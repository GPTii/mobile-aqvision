import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/app_strings.dart';
import 'app_theme_store.dart';

enum ReleaseNoteKind { newFeature, improvement, fix, note }

/// Wire values of `sections[].kind` from `GET /api/v1/app-releases`.
ReleaseNoteKind? _kindFromApi(String? raw) {
  switch (raw) {
    case 'new_feature':
      return ReleaseNoteKind.newFeature;
    case 'improvement':
      return ReleaseNoteKind.improvement;
    case 'fix':
      return ReleaseNoteKind.fix;
    case 'note':
      return ReleaseNoteKind.note;
  }
  return null;
}

class ReleaseSection {
  final ReleaseNoteKind kind;
  final List<String> items;

  const ReleaseSection(this.kind, this.items);
}

class AppVersion {
  final String version;
  final int buildNumber;
  final DateTime releasedAt;
  final String teaser;
  final bool isLatest;
  final List<ReleaseSection> sections;

  const AppVersion({
    required this.version,
    required this.buildNumber,
    required this.releasedAt,
    required this.teaser,
    required this.sections,
    this.isLatest = false,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json, {bool isLatest = false}) {
    final sections = <ReleaseSection>[];
    for (final s in (json['sections'] as List? ?? const [])) {
      final kind = _kindFromApi(s is Map ? s['kind']?.toString() : null);
      if (kind == null) continue; // unknown kind from a newer server — skip it
      final items = (s['items'] as List? ?? const []).map((e) => e.toString()).toList();
      if (items.isNotEmpty) sections.add(ReleaseSection(kind, items));
    }
    return AppVersion(
      version: (json['version'] ?? '').toString(),
      buildNumber: json['buildNumber'] is num ? (json['buildNumber'] as num).toInt() : 0,
      releasedAt: DateTime.tryParse(json['releasedAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      teaser: (json['teaser'] ?? '').toString(),
      sections: sections,
      isLatest: isLatest,
    );
  }

  String get buildLabel => 'Build $buildNumber';

  /// "4 tháng 9, 2026" (vi) / "September 4, 2026" (en) — follows the app language.
  String get dateLabel {
    final d = releasedAt;
    if (AppThemeStore.instance.lang == 'en') {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    }
    return '${d.day} tháng ${d.month}, ${d.year}';
  }
}

/// Version history backed by `GET /api/v1/app-releases`.
class AppReleaseStore extends ChangeNotifier {
  static final AppReleaseStore instance = AppReleaseStore._();
  AppReleaseStore._();

  static const _cacheKey = 'app_releases_cache';

  /// Newest first; `isLatest` is only set on the first element.
  List<AppVersion> releases = [];
  bool loading = false;
  String? error;

  AppVersion? get latest => releases.isEmpty ? null : releases.first;

  String get _baseUrl => ApiConfig.apiV1Base;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static List<AppVersion> _parse(List data) {
    final list = data.whereType<Map<String, dynamic>>().map((e) => AppVersion.fromJson(e)).toList()
      ..sort((a, b) => b.releasedAt.compareTo(a.releasedAt));
    // The server does not store `isLatest`; it is the first item after sorting.
    return [
      for (var i = 0; i < list.length; i++)
        AppVersion(
          version: list[i].version,
          buildNumber: list[i].buildNumber,
          releasedAt: list[i].releasedAt,
          teaser: list[i].teaser,
          sections: list[i].sections,
          isLatest: i == 0,
        ),
    ];
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) releases = _parse(jsonDecode(raw) as List);
    } catch (_) {
      // Corrupt cache — ignore, the network fetch below refills it.
    }
  }

  Future<void>? _inFlight;

  /// Shows the cached list right away (if any), then refreshes from the server.
  Future<void> fetchReleases() {
    return _inFlight ??= _doFetch().whenComplete(() => _inFlight = null);
  }

  Future<void> _doFetch() async {
    if (releases.isEmpty) {
      await _loadCache();
      if (releases.isNotEmpty) notifyListeners();
    }

    final token = await _getToken();
    if (token == null) {
      error = 'Chưa đăng nhập'.tr;
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/app-releases').replace(queryParameters: {
        'page': '1',
        'limit': '50',
      });
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = (jsonDecode(res.body) as Map)['data'] ?? [];
        releases = _parse(data);
        error = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(data));
      } else {
        error = 'Không tải được nhật ký phiên bản'.tr;
      }
    } catch (e) {
      debugPrint('[RELEASES] fetch failed: $e');
      error = 'Không tải được nhật ký phiên bản'.tr;
    }

    loading = false;
    notifyListeners();
  }
}
