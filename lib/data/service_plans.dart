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

  bool get isFree => priceMonthlyVnd == 0;

  int priceFor(BillingCycle cycle) =>
      cycle == BillingCycle.monthly ? priceMonthlyVnd : priceYearlyVnd;

  String get cameraLabel => maxCameras < 0 ? 'Không giới hạn camera' : '$maxCameras camera';

  /// 12x the monthly price — the "giá gốc" shown struck-through next to the
  /// discounted yearly price.
  int get fullYearPriceVnd => priceMonthlyVnd * 12;

  /// Percent saved by paying yearly vs. 12x monthly, derived from the two
  /// real prices the API returns — mirrors whatever % the admin set on the
  /// server, since priceYearlyVnd is server-computed from that same %.
  int get yearlySavingsPercent {
    final full = fullYearPriceVnd;
    if (full <= 0 || isFree) return 0;
    final saved = full - priceYearlyVnd;
    if (saved <= 0) return 0;
    return ((saved / full) * 100).round();
  }
}

/// No plan has a fixed retention window — recordings are kept indefinitely
/// until the account's storage quota is full. Once full, new recordings
/// stop saving until the user deletes old files or upgrades.
const String kRetentionPolicy =
    'Lưu trữ không giới hạn thời gian, đến khi đầy dung lượng thì cần xoá bớt mới ghi tiếp';
