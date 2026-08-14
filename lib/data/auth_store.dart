import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  UserAccount? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get token => _token;
  
  String get _baseUrl {
    if (kIsWeb) {
      if (Uri.base.host == "localhost" || Uri.base.host == "127.0.0.1") {
        return "http://localhost:3002/api/v1";
      }
      return "${Uri.base.scheme}://${Uri.base.authority}/api/v1";
    }
    return "https://dev1.aqvision.net/api/v1";
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
    if (_token != null) {
      await fetchProfile();
    }
  }

  Future<void> login(String username, String password) async {
    final uri = Uri.parse("$_baseUrl/auth/login");
    final res = await http.post(uri, 
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({"username": username, "password": password})
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      _token = json["data"]["token"];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", _token!);
      
      await fetchProfile();
    } else {
      final json = jsonDecode(res.body);
      throw Exception(json["error"] ?? "Đăng nhập thất bại");
    }
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
      await fetchProfile();
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
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    notifyListeners();
  }
}
