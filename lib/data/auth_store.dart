import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/api_config.dart';

class UserAccount {
  final String id;
  String name;
  String email; // used as username or email
  String phone;
  String role;
  
  // Agency info
  String? agencyId;
  String? apiSecret;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'Quản trị viên',
    this.agencyId,
    this.apiSecret,
  });
}

class AuthStore extends ChangeNotifier {
  static final AuthStore instance = AuthStore._();

  AuthStore._();

  UserAccount? _currentUser;
  String? _token;
  String? _authToken;

  UserAccount? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get token => _token;

  /// Cookie JWT for Next.js `/api/rapidmedia` (Luồng B). Not `access_token`.
  String? get authToken => _authToken ?? _token;

  String get _baseUrl => ApiConfig.apiV1Base;

  String get _webOrigin => ApiConfig.webOrigin;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
    _authToken = prefs.getString("auth_token");
    if (_token != null) {
      try { await fetchProfile(); } catch (e) { print("Token invalid: $e"); await logout(); }
    }
  }

  Future<void> login(String username, String password) async {
    final uri = Uri.parse("$_baseUrl/auth/login");
    final stopwatch = Stopwatch()..start();
    debugPrint("[LOGIN] POST $uri");

    final http.Response res;
    try {
      res = await http.post(uri,
        headers: {
          "Content-Type": "application/json"
        },
        body: jsonEncode({"username": username, "password": password})
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("[LOGIN] FAILED after ${stopwatch.elapsedMilliseconds}ms — ${e.runtimeType}: $e");
      rethrow;
    }
    debugPrint("[LOGIN] status ${res.statusCode} after ${stopwatch.elapsedMilliseconds}ms");

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      _token = json["data"]["token"];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", _token!);

      await _loginWebSession(username, password);
      try {
        await fetchProfile();
      } catch (e) {
        debugPrint("[LOGIN] profile fetch failed: $e");
        await logout();
        rethrow;
      }
    } else {
      final json = jsonDecode(res.body);
      throw Exception(json["error"] ?? "Đăng nhập thất bại");
    }
  }

  /// Luồng B: `POST /api/auth/login` → cookie `auth_token` (không có `access_token` trong body).
  Future<void> _loginWebSession(String username, String password) async {
    try {
      final uri = Uri.parse("$_webOrigin/api/auth/login");
      debugPrint("[LOGIN] web session POST $uri");
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      ).timeout(const Duration(seconds: 10));

      final fromCookie = _parseAuthTokenCookie(res.headers["set-cookie"]);
      final cookie = (fromCookie != null && fromCookie.isNotEmpty)
          ? fromCookie
          : _token;
      debugPrint(
        "[LOGIN] web session ${res.statusCode} cookie=${fromCookie != null}",
      );
      if (cookie != null && cookie.isNotEmpty) {
        await _saveAuthToken(cookie);
      }
    } catch (e) {
      debugPrint("[LOGIN] web session failed: $e");
      if (_token != null) await _saveAuthToken(_token!);
    }
  }

  Future<void> _saveAuthToken(String value) async {
    _authToken = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", value);
  }

  String? _parseAuthTokenCookie(String? setCookie) {
    if (setCookie == null || setCookie.isEmpty) return null;
    return RegExp(r'auth_token=([^;]+)').firstMatch(setCookie)?.group(1);
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    
    final uri = Uri.parse("$_baseUrl/auth/me");
    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $_token",
      "Bypass-Tunnel-Reminder": "true"
    }).timeout(const Duration(seconds: 10));
    
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final user = json["user"];
      final agency = json["agency"];
      
      _currentUser = UserAccount(
        id: user["id"]?.toString() ?? "",
        name: user["name"] ?? user["fullName"] ?? user["username"] ?? "Người dùng",
        email: user["username"] ?? "",
        phone: user["phone"] ?? "--",
        role: user["role"] ?? "Quản trị viên",
        agencyId: agency != null ? agency["agencyId"] : null,
        apiSecret: agency != null ? agency["apiSecret"] : null,
      );
      
      // Register device token for push notifications
      _registerDeviceToken();
      
      notifyListeners();
    } else {
      // Token may be expired
      await logout();
    }
  }

  Future<void> _registerDeviceToken() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && _token != null) {
        await http.post(
          Uri.parse("$_baseUrl/devices/register"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_token",
          },
          body: jsonEncode({"token": token, "platform": defaultTargetPlatform.name}),
        );
      }
    } catch (e) {
      print("Register device token error: $e");
    }
  }

  Future<void> updateProfile({String? name, String? email, String? phone}) async {
    final uri = Uri.parse("$_baseUrl/auth/me");
    final res = await http.patch(uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token",
      },
      body: jsonEncode({
        if (name != null && name.trim().isNotEmpty) "name": name.trim(),
        if (phone != null) "phone": phone.trim(),
      }),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      try { await fetchProfile(); } catch (e) { print("Token invalid: $e"); await logout(); }
    } else {
      final json = jsonDecode(res.body);
      throw Exception(json["error"] ?? "Lỗi cập nhật thông tin");
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final uri = Uri.parse("$_baseUrl/auth/me");
    final res = await http.put(uri, 
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"oldPassword": oldPassword, "newPassword": newPassword}),
    );
    if (res.statusCode != 200) {
      final json = jsonDecode(res.body);
      throw Exception(json["error"] ?? "Lỗi đổi mật khẩu");
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse("$_webOrigin/api/auth/logout"),
        headers: {
          if (authToken != null) "Cookie": "auth_token=$authToken",
        },
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    _currentUser = null;
    _token = null;
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("auth_token");
    notifyListeners();
  }
}
