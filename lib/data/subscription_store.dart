import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'service_plans.dart';

class SubscriptionStore extends ChangeNotifier {
  static final SubscriptionStore instance = SubscriptionStore._();
  SubscriptionStore._();

  List<ServicePlan> plans = [];
  String? currentPlanId;
  BillingCycle currentBillingCycle = BillingCycle.monthly;
  DateTime? startedAt;
  DateTime? renewsAt;

  bool loading = false;
  String? error;
  bool _upgrading = false;
  bool get upgrading => _upgrading;

  ServicePlan? get currentPlan {
    for (final p in plans) {
      if (p.id == currentPlanId) return p;
    }
    return null;
  }

  String get _baseUrl => ApiConfig.apiV1Base;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchAll() async {
    final token = await _getToken();
    if (token == null) return;

    loading = true;
    notifyListeners();

    try {
      await Future.wait([_fetchPlans(token), _fetchCurrent(token)]);
      error = null;
    } catch (_) {
      error = 'Không tải được thông tin gói dịch vụ';
    }

    loading = false;
    notifyListeners();
  }

  Future<void> _fetchPlans(String token) async {
    final uri = Uri.parse('$_baseUrl/subscription/plans');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];
      plans = data.map((p) => ServicePlan.fromJson(p)).toList();
    } else {
      throw Exception('fetchPlans failed (${res.statusCode})');
    }
  }

  Future<void> _fetchCurrent(String token) async {
    final uri = Uri.parse('$_baseUrl/subscription');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final data = json['data'];
      currentPlanId = data['planId']?.toString();
      currentBillingCycle = BillingCycle.fromName(data['billingCycle']?.toString());
      startedAt = DateTime.tryParse(data['startedAt']?.toString() ?? '');
      renewsAt = DateTime.tryParse(data['renewsAt']?.toString() ?? '');
    } else {
      throw Exception('fetchCurrent failed (${res.statusCode})');
    }
  }

  /// Sends a "contact manager" request for a plan — this is not a
  /// self-service purchase, admin reviews and reaches out directly (no
  /// online payment yet). Doesn't flip the plan immediately. Returns the
  /// server's confirmation message to show the customer verbatim.
  Future<String> requestUpgrade({
    required String planId,
    required BillingCycle cycle,
    String? message,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập');

    _upgrading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/subscription/upgrade');
      final trimmedMessage = message?.trim();
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'planId': planId,
          'billingCycle': cycle.name,
          if (trimmedMessage != null && trimmedMessage.isNotEmpty) 'message': trimmedMessage,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('Lỗi gửi yêu cầu liên hệ (${res.statusCode}): ${res.body}');
      }

      final json = jsonDecode(res.body);
      return json['msg']?.toString() ??
          'Yêu cầu liên hệ đã được ghi nhận, quản lý sẽ liên hệ với bạn sớm';
    } finally {
      _upgrading = false;
      notifyListeners();
    }
  }
}
