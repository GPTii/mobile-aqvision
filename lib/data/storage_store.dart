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

  String get _baseUrl => ApiConfig.apiBase;

  Future<void> fetchStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return;

    loading = true;
    if (cameras.isEmpty && usedStorageMb == 0) notifyListeners();

    try {
      final uri = Uri.parse("$_baseUrl/v1/storage");
      final res = await http.get(uri, headers: {
        "Authorization": "Bearer $token",
      }).timeout(const Duration(seconds: 10));

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
                  usedStorageMb: (c["usedStorageMb"] as num?)?.toDouble() ?? 0,
                ))
            .toList()
          ..sort((a, b) => b.usedStorageMb.compareTo(a.usedStorageMb));
        error = null;
      } else {
        error = "Không tải được dung lượng lưu trữ".tr;
      }
    } catch (_) {
      error = "Không tải được dung lượng lưu trữ".tr;
    }

    loading = false;
    notifyListeners();
  }
}
