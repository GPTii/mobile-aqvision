import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/commadesk_api.dart';
import '../utils/network_error_handler.dart';
import '../screens/auth/login_screen.dart';
import 'video_preload_cache.dart';

class UserAccount {
  final String id;
  String name;
  String email;
  String phone;
  String role;
  String? organizationId;
  String? organizationName;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'Người dùng',
    this.organizationId,
    this.organizationName,
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

  /// Legacy alias — CommaDesk uses Bearer JWT only (no web cookie session).
  String? get authToken => _token;

  Future<void> init() async {
    _token = await CommaDeskApi.instance.readAccessToken();
    if (_token != null && _token!.isNotEmpty) {
      try {
        await fetchProfile();
      } catch (e) {
        debugPrint('[AuthStore] token invalid: $e');
        await logout();
      }
    }
  }

  Future<void> login(String emailOrUsername, String password) async {
    final uri = Uri.parse('${CommaDeskApi.instance.baseUrl}/auth/login');
    final stopwatch = Stopwatch()..start();
    debugPrint('[LOGIN] POST $uri');

    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': emailOrUsername.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on SocketException catch (_) {
      showNetworkErrorDialog();
      throw Exception('Không thể kết nối máy chủ');
    } on TimeoutException catch (_) {
      showNetworkErrorDialog();
      throw Exception('Kết nối quá hạn');
    } catch (e) {
      debugPrint(
        '[LOGIN] FAILED after ${stopwatch.elapsedMilliseconds}ms — ${e.runtimeType}: $e',
      );
      rethrow;
    }
    debugPrint(
      '[LOGIN] status ${res.statusCode} after ${stopwatch.elapsedMilliseconds}ms',
    );

    final json = jsonDecode(res.body);
    if (json is! Map) {
      throw Exception('Phản hồi đăng nhập không hợp lệ');
    }
    final map = Map<String, dynamic>.from(json);

    if (res.statusCode != 200) {
      throw Exception(map['error']?.toString() ?? 'Đăng nhập thất bại');
    }

    final status = map['status']?.toString();
    if (status == 'requires_2fa') {
      throw Exception(
        'Tài khoản bật 2FA — vui lòng đăng nhập qua dashboard CommaDesk trước.',
      );
    }
    if (status == 'requires_org') {
      throw Exception(
        'Email trùng nhiều tổ chức — cần Organization ID khi đăng nhập.',
      );
    }
    if (status == 'requires_email') {
      throw Exception(
        'Tên đăng nhập trùng — vui lòng dùng email đầy đủ.',
      );
    }

    final access = (map['access_token'] ?? map['token'])?.toString() ?? '';
    final refresh = map['refresh_token']?.toString() ?? '';
    if (access.isEmpty || refresh.isEmpty) {
      throw Exception('Đăng nhập thất bại — thiếu token');
    }

    final userRaw = map['user'];
    String? orgId;
    if (userRaw is Map) {
      orgId = (userRaw['organization_id'] ?? userRaw['organizationId'])
          ?.toString();
    }

    await CommaDeskApi.instance.saveSession(
      accessToken: access,
      refreshToken: refresh,
      organizationId: orgId,
    );
    _token = access;

    try {
      await fetchProfile();
    } catch (e) {
      debugPrint('[LOGIN] profile fetch failed: $e');
      await logout();
      rethrow;
    }
  }

  Future<void> fetchProfile() async {
    final token = await CommaDeskApi.instance.readAccessToken();
    if (token == null || token.isEmpty) return;

    final res = await CommaDeskApi.instance.get('/profile');
    if (res.statusCode != 200) {
      await logout();
      return;
    }

    final json = jsonDecode(res.body);
    if (json is! Map) throw Exception('Profile không hợp lệ');
    final map = Map<String, dynamic>.from(json);

    final userRaw = map['user'];
    if (userRaw is! Map) throw Exception('Thiếu user trong profile');
    final user = Map<String, dynamic>.from(userRaw);
    final orgRaw = map['organization'];
    final org = orgRaw is Map ? Map<String, dynamic>.from(orgRaw) : null;

    final roles = map['roles'];
    String roleLabel = 'Người dùng';
    if (roles is List && roles.isNotEmpty) {
      roleLabel = roles.first.toString();
    } else if (user['is_admin'] == true || user['isAdmin'] == true) {
      roleLabel = 'Quản trị viên';
    }

    final orgId = org?['id']?.toString() ??
        user['organization_id']?.toString() ??
        user['organizationId']?.toString();

    if (orgId != null && orgId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('organization_id', orgId);
    }

    _token = token;
    _currentUser = UserAccount(
      id: user['id']?.toString() ?? '',
      name: (user['name'] ?? user['display_name'] ?? 'Người dùng').toString(),
      email: user['email']?.toString() ?? '',
      phone: user['phone']?.toString() ?? '',
      role: roleLabel,
      organizationId: orgId,
      organizationName: org?['name']?.toString(),
    );

    await _registerDeviceToken();
    notifyListeners();
  }

  Future<void> _registerDeviceToken() async {
    if (kIsWeb) return;
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final access = await CommaDeskApi.instance.readAccessToken();
      if (fcmToken == null || access == null) return;

      await CommaDeskApi.instance.post(
        '/push/register',
        body: {
          'token': fcmToken,
          'platform': defaultTargetPlatform.name,
        },
      );
    } catch (e) {
      debugPrint('[AuthStore] push register error: $e');
    }
  }

  Future<void> updateProfile({String? name, String? email, String? phone}) async {
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      body['name'] = name.trim();
      body['display_name'] = name.trim();
    }
    if (phone != null) body['phone'] = phone.trim();

    final res = await CommaDeskApi.instance.put('/profile', body: body);
    if (res.statusCode == 200) {
      await fetchProfile();
    } else {
      throw Exception(CommaDeskApi.messageFromResponse(res));
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final res = await CommaDeskApi.instance.post(
      '/profile/change-password',
      body: {
        'current_password': oldPassword,
        'new_password': newPassword,
      },
    );
    if (res.statusCode != 200) {
      throw Exception(CommaDeskApi.messageFromResponse(res));
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refresh_token');
      if (refresh != null && refresh.isNotEmpty) {
        await CommaDeskApi.instance.post(
          '/auth/logout',
          body: {'refresh_token': refresh},
        );
      }
    } catch (_) {}

    _currentUser = null;
    _token = null;
    VideoPreloadCache.instance.clear();
    await CommaDeskApi.instance.clearSession();
    notifyListeners();

    final context = globalNavigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
