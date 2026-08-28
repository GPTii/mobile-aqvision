import 'package:flutter/foundation.dart';

import 'service_plans.dart';

/// CommaDesk chưa có module subscription/plans như AQ-VISION backend.
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

  Future<void> fetchAll() async {
    loading = true;
    notifyListeners();

    plans = [];
    currentPlanId = null;
    error = 'Gói dịch vụ được quản lý trên CommaDesk — liên hệ quản trị viên.';
    loading = false;
    notifyListeners();
  }

  Future<String> requestUpgrade({
    required String planId,
    required BillingCycle cycle,
    String? message,
  }) async {
    throw Exception(
      'Nâng cấp gói chưa hỗ trợ trong app — liên hệ quản trị CommaDesk.',
    );
  }
}
