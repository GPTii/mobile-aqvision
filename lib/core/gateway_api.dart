import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown when the gateway requires authentication (HTTP 401) but we have no
/// valid session. Callers should run [ensureLogin] once, then retry.
/// See README_BLE.md §14.
class NeedLogin implements Exception {
  @override
  String toString() => 'NeedLogin';
}

/// REST client for a single Eyerus gateway on the LAN: `http://<ip>:5050`.
///
/// Faithful to README_BLE.md §4. All configuration/status operations go
/// through here. Errors surface as [Exception] carrying the gateway's
/// Vietnamese `error` string; a 401 becomes [NeedLogin].
class GatewayApi {
  /// Base URL, e.g. `http://192.168.1.216:5050`.
  final Uri base;
  final http.Client _http;

  /// Bearer token once the gateway has accounts enabled (§14). Null otherwise.
  String? token;

  GatewayApi(this.base, {this.token, http.Client? client}) : _http = client ?? http.Client();

  Map<String, String> get _auth => token == null ? const {} : {'Authorization': 'Bearer $token'};

  /// §14. Logs in and returns the role ("admin" / "user").
  Future<String> login(String username, String password) async {
    final j = await post('/api/auth/login', {
      'username': username,
      'password': password,
    });
    token = j['token'] as String?;
    return (j['role'] ?? 'user') as String;
  }

  Future<dynamic> get(String path) async {
    final r = await _http.get(base.resolve(path), headers: _auth).timeout(const Duration(seconds: 20));
    return _decode(r);
  }

  Future<dynamic> post(String path, Object body) async {
    final r = await _http
        .post(
          base.resolve(path),
          headers: {'Content-Type': 'application/json', ..._auth},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    return _decode(r);
  }

  dynamic _decode(http.Response r) {
    if (r.statusCode == 401) throw NeedLogin();
    dynamic j;
    try {
      j = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      if (r.statusCode >= 400) {
        throw Exception('HTTP ${r.statusCode}');
      }
      throw Exception('Phản hồi không hợp lệ từ gateway (HTTP ${r.statusCode})');
    }
    if (r.statusCode >= 400 || (j is Map && j['success'] == false)) {
      throw Exception(
        j is Map ? (j['error'] ?? 'HTTP ${r.statusCode}') : 'HTTP ${r.statusCode}',
      );
    }
    return j;
  }

  /// Polls `/api/health` (no auth) until `{"status": "ok"}` or [timeout].
  /// After a factory reset the platform reboots when joining WiFi, so allow ~60 s.
  Future<bool> waitReady({Duration timeout = const Duration(seconds: 60)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      try {
        final h = await get('/api/health');
        if (h is Map && h['status'] == 'ok') return true;
      } catch (_) {
        // not up yet
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    return false;
  }

  void close() => _http.close();
}
