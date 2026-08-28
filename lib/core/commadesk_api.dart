import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Thin HTTP client for CommaDesk `/api/v1` (JWT RS256 + org header).
class CommaDeskApi {
  CommaDeskApi._();

  static final CommaDeskApi instance = CommaDeskApi._();

  static const _accessKey = 'access_token';
  static const _legacyTokenKey = 'token';
  static const _refreshKey = 'refresh_token';
  static const _orgKey = 'organization_id';

  bool _refreshing = false;

  String get baseUrl => ApiConfig.apiV1Base;

  Future<Map<String, String>> authHeaders({bool json = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString(_accessKey) ?? prefs.getString(_legacyTokenKey);
    final orgId = prefs.getString(_orgKey);
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (orgId != null && orgId.isNotEmpty) 'X-Organization-Id': orgId,
    };
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    String? organizationId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_legacyTokenKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
    if (organizationId != null && organizationId.isNotEmpty) {
      await prefs.setString(_orgKey, organizationId);
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_orgKey);
    await prefs.remove('auth_token');
  }

  Future<String?> readAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey) ?? prefs.getString(_legacyTokenKey);
  }

  /// Unwrap CommaDesk envelopes: raw list, `{data: ...}`, `{success, data}`.
  static dynamic unwrapBody(dynamic decoded) {
    if (decoded is! Map) return decoded;
    final map = Map<String, dynamic>.from(decoded);
    if (map.containsKey('data')) return map['data'];
    return map;
  }

  static List<Map<String, dynamic>> asMapList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  static String messageFromResponse(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        final err = decoded['error'];
        if (err is Map && err['message'] != null) {
          return err['message'].toString();
        }
        if (err is String && err.isNotEmpty) return err;
        if (decoded['message'] != null) {
          return decoded['message'].toString();
        }
      }
    } catch (_) {}
    return 'Lỗi máy chủ (${res.statusCode})';
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 15),
    bool retryOn401 = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await http
        .get(uri, headers: await authHeaders())
        .timeout(timeout);
    if (res.statusCode == 401 && retryOn401 && !path.startsWith('/auth/')) {
      final ok = await _tryRefresh();
      if (ok) {
        return get(path, query: query, timeout: timeout, retryOn401: false);
      }
    }
    return res;
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 15),
    bool retryOn401 = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http
        .post(
          uri,
          headers: await authHeaders(),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
    if (res.statusCode == 401 && retryOn401 && !path.startsWith('/auth/')) {
      final ok = await _tryRefresh();
      if (ok) {
        return post(path, body: body, timeout: timeout, retryOn401: false);
      }
    }
    return res;
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 15),
    bool retryOn401 = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http
        .put(
          uri,
          headers: await authHeaders(),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
    if (res.statusCode == 401 && retryOn401 && !path.startsWith('/auth/')) {
      final ok = await _tryRefresh();
      if (ok) {
        return put(path, body: body, timeout: timeout, retryOn401: false);
      }
    }
    return res;
  }

  Future<http.Response> patch(
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 15),
    bool retryOn401 = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http
        .patch(
          uri,
          headers: await authHeaders(),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
    if (res.statusCode == 401 && retryOn401 && !path.startsWith('/auth/')) {
      final ok = await _tryRefresh();
      if (ok) {
        return patch(path, body: body, timeout: timeout, retryOn401: false);
      }
    }
    return res;
  }

  Future<http.Response> delete(
    String path, {
    Duration timeout = const Duration(seconds: 15),
    bool retryOn401 = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http
        .delete(uri, headers: await authHeaders())
        .timeout(timeout);
    if (res.statusCode == 401 && retryOn401 && !path.startsWith('/auth/')) {
      final ok = await _tryRefresh();
      if (ok) {
        return delete(path, timeout: timeout, retryOn401: false);
      }
    }
    return res;
  }

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString(_refreshKey);
      if (refresh == null || refresh.isEmpty) return false;
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return false;
      final json = jsonDecode(res.body);
      if (json is! Map) return false;
      final access = (json['access_token'] ?? json['token'])?.toString();
      final newRefresh = json['refresh_token']?.toString();
      if (access == null || access.isEmpty || newRefresh == null) {
        return false;
      }
      await saveSession(
        accessToken: access,
        refreshToken: newRefresh,
        organizationId: prefs.getString(_orgKey),
      );
      return true;
    } catch (e) {
      debugPrint('[CommaDeskApi] refresh failed: $e');
      return false;
    } finally {
      _refreshing = false;
    }
  }

  /// GET helper returning decoded JSON or throwing with a readable message.
  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    http.Response res;
    try {
      res = await get(path, query: query, timeout: timeout);
    } on SocketException {
      throw Exception('Không thể kết nối máy chủ');
    } on TimeoutException {
      throw Exception('Kết nối quá hạn');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw Exception(messageFromResponse(res));
  }

  Future<dynamic> postJson(
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    http.Response res;
    try {
      res = await post(path, body: body, timeout: timeout);
    } on SocketException {
      throw Exception('Không thể kết nối máy chủ');
    } on TimeoutException {
      throw Exception('Kết nối quá hạn');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw Exception(messageFromResponse(res));
  }
}
