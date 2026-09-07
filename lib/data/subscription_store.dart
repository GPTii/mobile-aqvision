import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'service_plans.dart';
import '../utils/app_strings.dart';

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
      error = 'Không tải được thông tin gói dịch vụ'.tr;
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

  /// Sends an upgrade request for admin approval — does not flip the plan
  /// immediately. Callers should show a "request sent" message, not a
  /// success-as-if-upgraded one.
  Future<String> requestUpgrade({
    required String planId,
    required BillingCycle cycle,
    String? message,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập'.tr);

    _upgrading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/subscription/upgrade');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'planId': planId,
          'billingCycle': cycle.name,
          if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('Lỗi gửi yêu cầu nâng cấp (${res.statusCode}): ${res.body}'.tr);
      }
      return 'trong mục "Gói dịch vụ" ngay sau khi được duyệt.'.tr;
    } finally {
      _upgrading = false;
      notifyListeners();
    }
  }
}
