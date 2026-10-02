import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_defaults.dart';

/// Resolves API base URLs from [ApiDefaults] or custom Local Server settings.
class ApiConfig {
  ApiConfig._();

  static const String _keyServerMode = 'server_mode';
  static const String _keyLocalIp = 'local_server_ip';
  static const String _keyLocalPort = 'local_server_port';
  static const String _keyLocalScheme = 'local_server_scheme';

  /// 'cloud' (default: dev1.aqvision.net) or 'local' (LAN IP + port).
  static String _serverMode = 'cloud';
  static String _localIp = '192.168.1.100';
  static int _localPort = 3000;
  static String _localScheme = 'http';

  /// True when the user configured the app to use a local server.
  static bool get isLocal => _serverMode == 'local';
  static String get serverMode => _serverMode;
  static String get localIp => _localIp;
  static int get localPort => _localPort;
  static String get localScheme => _localScheme;

  /// Full origin string for local server, e.g. `http://192.168.1.100:3000`.
  static String get localOrigin => '$_localScheme://$_localIp:$_localPort';

  /// Media ingest host for gateway stream pushing:
  /// on local mode, streams push to local server IP; on cloud, to production ingest host.
  static String get mediaIngestHost => isLocal ? _localIp : ApiDefaults.mediaIngestHost;

  /// Load persisted server configuration from SharedPreferences.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _serverMode = prefs.getString(_keyServerMode) ?? 'cloud';
      _localIp = prefs.getString(_keyLocalIp) ?? '192.168.1.100';
      _localPort = prefs.getInt(_keyLocalPort) ?? 3000;
      _localScheme = prefs.getString(_keyLocalScheme) ?? 'http';
    } catch (e) {
      debugPrint('[ApiConfig] init error: $e');
    }
  }

  /// Update and persist server settings.
  static Future<void> setServerConfig({
    required String mode,
    String? ip,
    int? port,
    String? scheme,
  }) async {
    _serverMode = mode == 'local' ? 'local' : 'cloud';
    if (ip != null && ip.trim().isNotEmpty) {
      _localIp = ip.trim().replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/.*$'), '');
    }
    if (port != null && port > 0 && port <= 65535) {
      _localPort = port;
    }
    if (scheme != null && (scheme == 'http' || scheme == 'https')) {
      _localScheme = scheme;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyServerMode, _serverMode);
      await prefs.setString(_keyLocalIp, _localIp);
      await prefs.setInt(_keyLocalPort, _localPort);
      await prefs.setString(_keyLocalScheme, _localScheme);
    } catch (e) {
      debugPrint('[ApiConfig] setServerConfig persist error: $e');
    }
  }

  /// Quick connection ping to verify if an origin is reachable.
  static Future<bool> testConnection(String targetOrigin) async {
    final cleanOrigin = targetOrigin.replaceAll(RegExp(r'/+$'), '');
    try {
      final uri = Uri.parse('$cleanOrigin${ApiDefaults.apiV1Path}/auth/me');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      return res.statusCode > 0;
    } catch (_) {
      try {
        final uri = Uri.parse(cleanOrigin);
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        return res.statusCode > 0;
      } catch (_) {
        return false;
      }
    }
  }

  /// Production origin, e.g. `https://dev1.aqvision.net`.
  static String get productionOrigin => '${ApiDefaults.productionScheme}://${ApiDefaults.productionHost}';

  /// Backup origin: `https://media.aqptech.cloud`.
  static String get backupOrigin => '${ApiDefaults.productionScheme}://${ApiDefaults.backupHost}';

  /// Origin picked by [selectReachableOrigin]; primary until then.
  static String? _activeOrigin;

  /// True while the app talks to the backup domain.
  static bool get usingBackup => !isLocal && _activeOrigin == backupOrigin;

  /// Any HTTP answer below 500 counts as reachable (`/auth/me` without a
  /// token is a cheap 401); DNS / TLS / timeout / 5xx do not.
  static Future<bool> _reachable(String origin) async {
    try {
      final res =
          await http.get(Uri.parse('$origin${ApiDefaults.apiV1Path}/auth/me')).timeout(const Duration(seconds: 5));
      return res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  static Future<String>? _probing;

  /// Use dev1 when it answers, otherwise the backup domain. Called at startup
  /// and again after a network error (see [AuthStore.login]). Returns true
  /// when the active origin changed.
  static Future<bool> selectReachableOrigin() async {
    if (isLocal || kIsWeb) return false;
    final before = origin;
    final picked = await (_probing ??= () async {
      try {
        if (await _reachable(productionOrigin)) return productionOrigin;
        return productionOrigin;
      } finally {
        _probing = null;
      }
    }());
    _activeOrigin = picked;
    if (picked != before) debugPrint('[API] switched origin $before -> $picked');
    return picked != before;
  }

  /// Scheme + host (+ port if needed), without `/api` path.
  static String get origin {
    if (isLocal) {
      return localOrigin;
    }
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : ApiDefaults.localHost;
      final isWebLocal = host == 'localhost' || host == '127.0.0.1';
      if (isWebLocal && Uri.base.port != ApiDefaults.localApiPort) {
        return 'http://$host:${ApiDefaults.localApiPort}';
      }
      return '${Uri.base.scheme}://${Uri.base.authority}';
    }
    return _activeOrigin ?? productionOrigin;
  }

  /// `/api` — groups, proxies, rapidmedia, alerts, storage, …
  static String get apiBase => '$origin${ApiDefaults.apiPath}';

  /// `/api/v1` — auth, stats, devices, …
  static String get apiV1Base => '$origin${ApiDefaults.apiV1Path}';

  /// Web app origin for cookie auth (`/api/auth/login`, logout).
  static String get webOrigin => origin;

  /// HLS / recording media base: `/api/media`.
  /// Force HTTP for media to prevent ExoPlayer from rejecting self-signed SSL on dev.
  static String get mediaBase {
    if (origin.startsWith('https://dev1')) {
      return '${origin.replaceFirst('https://', 'http://')}${ApiDefaults.apiPath}/${ApiDefaults.mediaPathSegment}';
    }
    return '$apiBase/${ApiDefaults.mediaPathSegment}';
  }
}

