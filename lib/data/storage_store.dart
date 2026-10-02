import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/app_strings.dart';

class CameraStorageUsage {
  final String id;
  final String name;
  final double usedStorageMb;

  CameraStorageUsage({
    required this.id,
    required this.name,
    required this.usedStorageMb,
  });
}

/// Read-only cloud recording storage usage for the signed-in account, from
/// GET /api/v1/storage. Server computes percent/tier — this store just
/// mirrors the response, it never deletes recordings (no such endpoint yet).
class StorageStore extends ChangeNotifier {
  static final StorageStore instance = StorageStore._();

  StorageStore._();

  double usedStorageMb = 0;
  double storageQuotaMb = 0;
  double percent = 0;
  String tier = 'good';
  List<CameraStorageUsage> cameras = [];
  bool loading = false;
  String? error;

  static const _cacheKey = 'storage_report_cache';

  String get _baseUrl => ApiConfig.apiBase;

  /// Hydrate from the last successful response so the tab shows something
  /// instantly on cold start instead of a blank/zero state while the network
  /// call is in flight. Only meaningful before the first fetch of the session.
  Future<void> _hydrateFromCache(SharedPreferences prefs) async {
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      usedStorageMb = (data["usedStorageMb"] as num?)?.toDouble() ?? 0;
      storageQuotaMb = (data["storageQuotaMb"] as num?)?.toDouble() ?? 0;
      percent = (data["percent"] as num?)?.toDouble() ?? 0;
      tier = data["tier"] ?? "good";
      final List camList = data["cameras"] ?? [];
      cameras = camList
          .map((c) => CameraStorageUsage(
                id: (c["id"] ?? "").toString(),
                name: c["name"] ?? "Camera",
                usedStorageMb: (c["usedStorageMb"] as num?)?.toDouble() ?? 0,
              ))
          .toList();
    } catch (_) {
      // Corrupt cache — ignore, next successful fetch overwrites it.
    }
  }

  Future<void> _saveCache(SharedPreferences prefs) async {
    await prefs.setString(
        _cacheKey,
        jsonEncode({
          "usedStorageMb": usedStorageMb,
          "storageQuotaMb": storageQuotaMb,
          "percent": percent,
          "tier": tier,
          "cameras": cameras
              .map((c) => {
                    "id": c.id,
                    "name": c.name,
                    "usedStorageMb": c.usedStorageMb,
                  })
              .toList(),
        }));
  }

  Future<void>? _inFlight;

  /// ReportTab and ProfileTab both call this from their own `initState()` —
  /// `IndexedStack` mounts every tab eagerly, so both fire the moment
  /// `HomeShell` builds. Without de-duping, two concurrent requests race to
  /// write the same singleton fields and whichever resolves last wins, even
  /// if it's stale/incomplete — the class of bug behind "shows 0MB on first
  /// login, correct after logging back in". One in-flight request, shared.
  Future<void> fetchStorage() {
    return _inFlight ??= _doFetchStorage().whenComplete(() => _inFlight = null);
  }

  Future<void> _doFetchStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    debugPrint("[STORAGE] fetchStorage() start, token=${token == null ? 'NULL' : '${token.substring(0, 12)}...'}");
    if (token == null) {
      error = 'Chưa đăng nhập'.tr;
      notifyListeners();
      return;
    }

    if (cameras.isEmpty && usedStorageMb == 0) {
      await _hydrateFromCache(prefs);
      debugPrint("[STORAGE] hydrated from cache: usedStorageMb=$usedStorageMb, cameras=${cameras.length}");
      notifyListeners();
    }
    loading = true;

    try {
      final uri = Uri.parse("$_baseUrl/v1/storage");
      debugPrint("[STORAGE] GET $uri");
      final res = await http.get(uri, headers: {
        "Authorization": "Bearer $token",
      }).timeout(const Duration(seconds: 10));

      debugPrint("[STORAGE] response ${res.statusCode}: ${res.body}");

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final data = json["data"];
        usedStorageMb = (data["usedStorageMb"] as num?)?.toDouble() ?? 0;
        storageQuotaMb = (data["storageQuotaMb"] as num?)?.toDouble() ?? 0;
        percent = (data["percent"] as num?)?.toDouble() ?? 0;
        tier = data["tier"] ?? "good";
        final List camList = data["cameras"] ?? [];
        cameras = camList
            .map((c) => CameraStorageUsage(
                  id: (c["id"] ?? 0).toString(),
                  name: c["name"] ?? "Camera",
                  // Per-camera field is `usedMb`, not `usedStorageMb` (that
                  // name only exists on the top-level totals).
                  usedStorageMb: (c["usedMb"] as num?)?.toDouble() ?? 0,
                ))
            .toList()
          ..sort((a, b) => b.usedStorageMb.compareTo(a.usedStorageMb));
        error = null;
        await _saveCache(prefs);
        debugPrint(
            "[STORAGE] parsed OK: usedStorageMb=$usedStorageMb, storageQuotaMb=$storageQuotaMb, cameras=${cameras.length}");
      } else {
        error = 'Không tải được dung lượng lưu trữ'.tr;
      }
    } catch (e, st) {
      debugPrint("[STORAGE] EXCEPTION: $e\n$st");
      error = 'Không tải được dung lượng lưu trữ'.tr;
    }

    loading = false;
    notifyListeners();
  }
}
