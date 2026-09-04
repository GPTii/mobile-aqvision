import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/auth_store.dart';
import '../data/camera_store.dart';
import '../data/service_plans.dart';
import '../data/storage_store.dart';
import '../data/subscription_store.dart';
import '../theme/app_colors.dart';
// import '../widgets/change_password_sheet.dart';
// import '../widgets/edit_profile_sheet.dart';
import '../widgets/prompt_dialog.dart';

import 'home/plan_selection_screen.dart';
import '../utils/app_strings.dart';

// import '../../gallery_screen.dart';

class ServicePackageScreen extends StatefulWidget {
  const ServicePackageScreen({super.key});

  @override
  State<ServicePackageScreen> createState() => _ServicePackageScreenState();
}

class _ServicePackageScreenState extends State<ServicePackageScreen> {
  @override
  void initState() {
    super.initState();
    SubscriptionStore.instance.fetchAll();
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Gói dịch vụ'.tr, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.card,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel('Chi tiết gói'.tr),
          SizedBox(height: 10),
          const _ServicePackageCard(),
          SizedBox(height: 24),
          _SectionLabel('Thông tin ứng dụng'.tr),
          SizedBox(height: 10),
          const _AppVersionCard(),
        ],
      ),
    );
  }

  
}

class _ServicePackageCard extends StatelessWidget {
  const _ServicePackageCard();

  static final _tierLabels = {
    'good': 'Bình thường'.tr,
    'warn': 'Sắp đầy'.tr,
    'warn2': 'Gần đầy'.tr,
    'bad': 'Nguy cấp'.tr,
    'full': 'Đã đầy'.tr,
  };

  static final _tierColors = {
    'good': AppColors.success,
    'warn': AppColors.warning,
    'warn2': Color(0xFFC2410C),
    'bad': AppColors.danger,
    'full': AppColors.danger,
  };

  String _formatMb(double mb) {
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '${mb.toStringAsFixed(0)} MB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatVnd(int amount, BillingCycle cycle) {
    if (amount == 0) return 'Miễn phí'.tr;
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    final suffix = cycle == BillingCycle.monthly ? '/tháng'.tr : '/năm'.tr;
    return '${buf}đ$suffix'.tr;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        StorageStore.instance,
        CameraStore.instance,
        SubscriptionStore.instance,
      ]),
      builder: (context, _) {
        final store = StorageStore.instance;
        final sub = SubscriptionStore.instance;
        final hasData = store.storageQuotaMb > 0;
        final tierLabel = _tierLabels[store.tier] ?? 'Bình thường'.tr;
        final tierColor = _tierColors[store.tier] ?? AppColors.success;
        final plan = sub.currentPlan;
        final cameraCount = CameraStore.instance.cameras.length;

        if (sub.loading && plan == null) {
          return _InfoCard(children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                ),
              ),
            ),
          ]);
        }

        if (plan == null) {
          return _InfoCard(children: [
            _InfoRow(
              icon: Icons.error_outline_rounded,
              label: 'Gói dịch vụ'.tr,
              value: sub.error ?? 'Chưa có dữ liệu'.tr,
            ),
          ]);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              children: [
                _InfoRow(icon: Icons.workspace_premium_outlined, label: 'Gói hiện tại'.tr, value: plan.name),
                _InfoRow(
                  icon: Icons.videocam_outlined,
                  label: 'Camera',
                  value: plan.maxCameras < 0
                      ? '$cameraCount (không giới hạn)'.tr
                      : '$cameraCount / ${plan.maxCameras}',
                ),
                _InfoRow(
                  icon: Icons.cloud_outlined,
                  label: 'Dung lượng lưu trữ'.tr,
                  value: hasData
                      ? '${_formatMb(store.usedStorageMb)} / ${_formatMb(store.storageQuotaMb)}'
                      : '${plan.storageGb.toStringAsFixed(0)} GB',
                ),
                _InfoRow(
                  icon: Icons.event_repeat_rounded,
                  label: 'Chu kỳ thanh toán'.tr,
                  value: sub.currentBillingCycle == BillingCycle.monthly ? 'Theo tháng'.tr : 'Theo năm'.tr,
                ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày bắt đầu gói'.tr,
                  value: _formatDate(sub.startedAt),
                ),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Giá gói'.tr,
                  value: _formatVnd(plan.priceFor(sub.currentBillingCycle), sub.currentBillingCycle),
                ),
                _InfoRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Trạng thái dung lượng'.tr,
                  value: hasData ? tierLabel : '--',
                ),
              ],
            ),
            if (hasData && store.tier != 'good') ...[
              SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tierColor.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_rounded, size: 16, color: tierColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dung lượng đang ở mức "$tierLabel" — cân nhắc nâng cấp gói để tránh gián đoạn ghi hình.'.tr,
                        style: TextStyle(fontSize: 12, color: tierColor, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 10),
            _ActionCard(
              children: [
                _ActionRow(
                  icon: Icons.upgrade_rounded,
                  label: 'Nâng cấp gói dịch vụ'.tr,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlanSelectionScreen(currentPlanId: plan.id),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AppVersionCard extends StatelessWidget {
  const _AppVersionCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return _InfoCard(
          children: [
            _InfoRow(
              icon: Icons.info_outline_rounded,
              label: 'Phiên bản'.tr,
              value: info == null ? '--' : '${info.version} (${info.buildNumber})',
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final List<Widget> children;

  const _ActionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 19, color: danger ? AppColors.danger : AppColors.textSecondary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              if (!danger)
                Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
