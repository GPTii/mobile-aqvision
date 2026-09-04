import 'package:flutter/material.dart';

import '../../data/service_plans.dart';
import '../../data/storage_store.dart';
import '../../data/subscription_store.dart';
import '../../theme/app_colors.dart';
import 'plan_selection_screen.dart';

class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key});

  static const _tierLabels = {
    'good': 'Bình thường',
    'warn': 'Sắp đầy',
    'warn2': 'Gần đầy',
    'bad': 'Nguy cấp',
    'full': 'Đã đầy',
  };

  static const _tierColors = {
    'good': AppColors.success,
    'warn': AppColors.warning,
    'warn2': Color(0xFFC2410C),
    'bad': AppColors.danger,
    'full': AppColors.danger,
  };

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.headerBackground,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                    const Expanded(
                      child: Text('Gói dịch vụ',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([StorageStore.instance, SubscriptionStore.instance]),
                builder: (context, _) {
                  final store = StorageStore.instance;
                  final sub = SubscriptionStore.instance;
                  final plan = sub.currentPlan;

                  if (sub.loading && plan == null) {
                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                      ),
                    );
                  }
                  if (plan == null) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(sub.error ?? 'Chưa có dữ liệu gói dịch vụ',
                          style: const TextStyle(color: AppColors.textMuted)),
                    );
                  }

                  final hasData = store.storageQuotaMb > 0;
                  final tierLabel = _tierLabels[store.tier] ?? 'Bình thường';
                  final tierColor = _tierColors[store.tier] ?? AppColors.success;
                  final usedGb = store.usedStorageMb / 1024;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _FeatureRow(
                              icon: Icons.workspace_premium_outlined,
                              label: 'Gói hiện tại',
                              value: plan.name,
                            ),
                            const Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
                            _FeatureRow(
                              icon: Icons.info_outline_rounded,
                              label: 'Trạng thái dung lượng',
                              value: hasData ? tierLabel : '--',
                              valueColor: hasData ? tierColor : null,
                            ),
                            const Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
                            _FeatureRow(
                              icon: Icons.cloud_outlined,
                              label: 'Dung lượng lưu trữ',
                              value: hasData
                                  ? '${usedGb.toStringAsFixed(1)} / ${plan.storageGb.toStringAsFixed(1)} GB'
                                  : '-- / ${plan.storageGb.toStringAsFixed(1)} GB',
                            ),
                            const Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
                            _FeatureRow(
                              icon: Icons.event_repeat_rounded,
                              label: 'Chu kỳ thanh toán',
                              value: sub.currentBillingCycle == BillingCycle.monthly ? 'Theo tháng' : 'Theo năm',
                            ),
                            const Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
                            _FeatureRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Ngày bắt đầu gói',
                              value: _formatDate(sub.startedAt),
                            ),
                            const Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
                            const _FeatureRow(
                              icon: Icons.history_rounded,
                              label: 'Thời hạn lưu bản ghi',
                              value: 'Không giới hạn*',
                            ),
                            if (plan.tagline.isNotEmpty) ...[
                              const Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
                              _FeatureRow(icon: Icons.description_outlined, label: 'Mô tả', value: plan.tagline),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '* Lưu đến khi đầy dung lượng, cần xoá bớt bản ghi cũ hoặc nâng cấp gói để ghi tiếp.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                        ),
                      ),

                      if (hasData && store.tier != 'good') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tierColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tierColor.withOpacity(0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_rounded, size: 16, color: tierColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Dung lượng đang ở mức "$tierLabel" — cân nhắc nâng cấp gói để tránh gián đoạn ghi hình.',
                                  style: TextStyle(fontSize: 12, color: tierColor, fontWeight: FontWeight.w600, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PlanSelectionScreen(currentPlanId: plan.id)),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.danger),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.bolt_rounded, size: 19, color: AppColors.danger),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text('Nâng cấp gói dịch vụ',
                                      style: TextStyle(
                                          color: AppColors.danger, fontSize: 14.5, fontWeight: FontWeight.w700)),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.danger),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _FeatureRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
