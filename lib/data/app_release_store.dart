import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
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

/// Text that is either a plain server string (translated through [AppStrings])
/// or a `{"vi": ..., "en": ...}` map from the bundled release notes.
class LocalText {
  final Map<String, String> _byLang;

  const LocalText._(this._byLang);

  LocalText.plain(String vi) : _byLang = {'vi': vi};

  factory LocalText.fromJson(dynamic raw) {
    if (raw is Map) {
      final map = <String, String>{
        for (final e in raw.entries)
          if (e.value != null) e.key.toString(): e.value.toString(),
      };
      if (map.isNotEmpty) return LocalText._(map);
    }
    return LocalText.plain(raw?.toString() ?? '');
  }

  /// The Vietnamese source text.
  String get vi => _byLang['vi'] ?? _byLang.values.first;

  bool get isEmpty => vi.isEmpty;

  /// Text in the current app language.
  String get text {
    final lang = AppThemeStore.instance.lang;
    final own = _byLang[lang];
    if (own != null) return own;
    // A single Vietnamese string: let the shared translation table handle it.
    if (_byLang.length == 1) return vi.tr;
    return _byLang['en'] ?? vi;
  }

  @override
  String toString() => text;
}

class ReleaseSection {
  final ReleaseNoteKind kind;
  final List<LocalText> items;

  const ReleaseSection(this.kind, this.items);
}

class AppVersion {
  /// Release name, e.g. `AQPConnect-1.1.0-release`.
  final String name;
  final String version;
  final int buildNumber;
  final DateTime releasedAt;
  final LocalText teaser;
  final bool isLatest;

  /// This is the version currently installed on the device.
  final bool isInstalled;
  final List<ReleaseSection> sections;

  const AppVersion({
    required this.name,
    required this.version,
    required this.buildNumber,
    required this.releasedAt,
    required this.teaser,
    required this.sections,
    this.isLatest = false,
    this.isInstalled = false,
  });

  static String defaultName(String version) => 'AQPConnect-$version-release';

  factory AppVersion.fromJson(Map<String, dynamic> json, {bool isLatest = false}) {
    final sections = <ReleaseSection>[];
    for (final s in (json['sections'] as List? ?? const [])) {
      final kind = _kindFromApi(s is Map ? s['kind']?.toString() : null);
      if (kind == null) continue; // unknown kind from a newer server — skip it
      final items = (s['items'] as List? ?? const []).map(LocalText.fromJson).where((t) => !t.isEmpty).toList();
      if (items.isNotEmpty) sections.add(ReleaseSection(kind, items));
    }
    final version = (json['version'] ?? '').toString();
    final name = json['name']?.toString() ?? '';
    return AppVersion(
      name: name.isEmpty ? defaultName(version) : name,
      version: version,
      buildNumber: json['buildNumber'] is num ? (json['buildNumber'] as num).toInt() : 0,
      releasedAt: DateTime.tryParse(json['releasedAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      teaser: LocalText.fromJson(json['teaser']),
      sections: sections,
      isLatest: isLatest,
    );
  }

  AppVersion copyWith({bool? isLatest, bool? isInstalled}) => AppVersion(
        name: name,
        version: version,
        buildNumber: buildNumber,
        releasedAt: releasedAt,
        teaser: teaser,
        sections: sections,
        isLatest: isLatest ?? this.isLatest,
        isInstalled: isInstalled ?? this.isInstalled,
      );

  String get buildLabel => 'Build $buildNumber';

  /// "4 tháng 9, 2026" (vi) / "September 4, 2026" (en) — follows the app language.
  String get dateLabel {
    final d = releasedAt;
    final lang = AppThemeStore.instance.lang;
    if (lang == 'ko') return '${d.year}년 ${d.month}월 ${d.day}일';
    if (lang == 'zh_Hant') return '${d.year}年${d.month}月${d.day}日';
    if (lang == 'en') {
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    }
    return '${d.day} tháng ${d.month}, ${d.year}';
  }
}

/// Newest first: by version number, then build number, then release date.
int compareReleases(AppVersion a, AppVersion b) {
  List<int> parts(String v) => v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final pa = parts(a.version), pb = parts(b.version);
  for (var i = 0; i < pa.length || i < pb.length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return y.compareTo(x);
  }
  if (a.buildNumber != b.buildNumber) return b.buildNumber.compareTo(a.buildNumber);
  return b.releasedAt.compareTo(a.releasedAt);
}

/// Version history = release notes bundled in the APK (`assets/release_notes.json`)
/// merged with `GET /api/v1/app-releases`. The bundled file ships with every build,
/// so a freshly installed APK always lists its own release, even offline / logged out.
class AppReleaseStore extends ChangeNotifier {
  static final AppReleaseStore instance = AppReleaseStore._();
  AppReleaseStore._();

  static const _cacheKey = 'app_releases_cache';
  static const bundledAsset = 'assets/release_notes.json';

  /// Newest first; `isLatest` is only set on the first element.
  List<AppVersion> releases = [];
  bool loading = false;
  String? error;

  /// Version of the installed app, e.g. `1.1.0` (the `version:` in pubspec.yaml).
  String? installedVersion;

  List<AppVersion> _bundled = const [];
  List<AppVersion> _server = const [];
  bool _localLoaded = false;

  AppVersion? get latest => releases.isEmpty ? null : releases.first;

  String get _baseUrl => ApiConfig.apiV1Base;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static List<AppVersion> _parse(List data) =>
      data.whereType<Map<String, dynamic>>().map((e) => AppVersion.fromJson(e)).toList();

  /// Server entries win over bundled ones with the same version number.
  void _merge() {
    final byVersion = <String, AppVersion>{
      for (final v in _bundled) v.version: v,
      for (final v in _server) v.version: v,
    };
    final list = byVersion.values.toList()..sort(compareReleases);
    releases = [
      for (var i = 0; i < list.length; i++)
        list[i].copyWith(isLatest: i == 0, isInstalled: list[i].version == installedVersion),
    ];
  }

  /// Bundled notes, installed version and the last server response — all local.
  Future<void> _loadLocal() async {
    if (_localLoaded) return;
    _localLoaded = true;
    try {
      final raw = await rootBundle.loadString(bundledAsset);
      _bundled = _parse(jsonDecode(raw) as List);
    } catch (e) {
      debugPrint('[RELEASES] bundled notes unreadable: $e');
    }
    try {
      installedVersion = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) _server = _parse(jsonDecode(raw) as List);
    } catch (_) {
      // Corrupt cache — ignore, the network fetch below refills it.
    }
    if (installedVersion != null && !_bundled.any((v) => v.version == installedVersion)) {
      debugPrint('[RELEASES] $bundledAsset has no entry for $installedVersion — add one before shipping.');
    }
    _merge();
  }

  Future<void>? _inFlight;

  /// Shows bundled + cached notes right away, then refreshes from the server.
  Future<void> fetchReleases() {
    return _inFlight ??= _doFetch().whenComplete(() => _inFlight = null);
  }

  Future<void> _doFetch() async {
    if (!_localLoaded) {
      await _loadLocal();
      notifyListeners();
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
        _server = _parse(data);
        _merge();
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
