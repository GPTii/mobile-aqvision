/// Subscription-plan models for the "Gói dịch vụ" UI, backed by the real
/// GET /api/v1/subscription/plans and GET /api/v1/subscription endpoints
/// (see SubscriptionStore).
enum BillingCycle {
  monthly,
  yearly;

  static BillingCycle fromName(String? name) =>
      name == 'yearly' ? BillingCycle.yearly : BillingCycle.monthly;
}

class ServicePlan {
  final String id;
  final String name;
  final int maxCameras; // -1 = unlimited
  final double storageGb;
  final int priceMonthlyVnd; // 0 = free
  final int priceYearlyVnd;
  final String tagline;

  const ServicePlan({
    required this.id,
    required this.name,
    required this.maxCameras,
    required this.storageGb,
    required this.priceMonthlyVnd,
    required this.priceYearlyVnd,
    required this.tagline,
  });

  factory ServicePlan.fromJson(Map<String, dynamic> json) => ServicePlan(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        maxCameras: (json['maxCameras'] as num?)?.toInt() ?? 0,
        storageGb: (json['storageGb'] as num?)?.toDouble() ?? 0,
        priceMonthlyVnd: (json['priceMonthlyVnd'] as num?)?.toInt() ?? 0,
        priceYearlyVnd: (json['priceYearlyVnd'] as num?)?.toInt() ?? 0,
        tagline: json['tagline']?.toString() ?? '',
      );

  String get cameraLabel => maxCameras < 0 ? 'Không giới hạn camera' : '$maxCameras camera';
}

/// No plan has a fixed retention window — recordings are kept indefinitely
/// until the account's storage quota is full. Once full, new recordings
/// stop saving until the user deletes old files or upgrades.
const String kRetentionPolicy =
    'Lưu trữ không giới hạn thời gian, đến khi đầy dung lượng thì cần xoá bớt mới ghi tiếp';
