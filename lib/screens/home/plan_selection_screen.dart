import 'package:flutter/material.dart';

import '../../data/service_plans.dart';
import '../../data/subscription_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_strings.dart';

class PlanSelectionScreen extends StatefulWidget {
  final String currentPlanId;

  const PlanSelectionScreen({super.key, required this.currentPlanId});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  late BillingCycle _cycle = SubscriptionStore.instance.currentBillingCycle;

  Future<void> _requestUpgrade(ServicePlan plan) async {
    final messageController = TextEditingController();
    try {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('${'Liên hệ quản lý về gói'.tr} ${plan.name}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: messageController,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhắn thêm cho quản lý (không bắt buộc)...'.tr,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Huỷ'.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: Text('Gửi yêu cầu'.tr),
            ),
          ],
        ),
      );

      if (proceed != true || !mounted) return;

      final resultMessage = await SubscriptionStore.instance.requestUpgrade(
        planId: plan.id,
        cycle: _cycle,
        message: messageController.text,
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Yêu cầu đã gửi'.tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: Text(
            'Yêu cầu của bạn đang chờ quản trị viên duyệt. Gói sẽ tự cập nhật '.tr + resultMessage,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Đã hiểu'.tr),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    } finally {
      messageController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      'Nâng cấp gói dịch vụ'.tr,
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CycleToggle(
                cycle: _cycle,
                onChanged: (c) => setState(() => _cycle = c),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: SubscriptionStore.instance,
                builder: (context, _) {
                  final sub = SubscriptionStore.instance;
                  final plans = sub.plans;

                  if (plans.isEmpty) {
                    if (sub.loading) {
                      return Center(
                        child: CircularProgressIndicator(color: AppColors.accent),
                      );
                    }
                    return Center(
                      child: Text(
                        sub.error ?? 'Không có dữ liệu gói dịch vụ'.tr,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Phone: 1 column, cards stacked (unchanged). Tablet/wide
                      // screens: lay plans out side by side like a real plan
                      // comparison, instead of one long scroll of full-width cards.
                      final crossAxisCount =
                          (constraints.maxWidth / 320).floor().clamp(1, 3);

                      if (crossAxisCount == 1) {
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: plans.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _buildCard(plans[index]),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 330,
                        ),
                        itemCount: plans.length,
                        itemBuilder: (context, index) => _buildCard(plans[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ServicePlan plan) {
    final isCurrent = plan.id == widget.currentPlanId;
    return _PlanCard(
      plan: plan,
      cycle: _cycle,
      isCurrent: isCurrent,
      isUpgrading: SubscriptionStore.instance.upgrading,
      onUpgrade: () => _requestUpgrade(plan),
    );
  }
}

class _CycleToggle extends StatelessWidget {
  final BillingCycle cycle;
  final ValueChanged<BillingCycle> onChanged;

  const _CycleToggle({required this.cycle, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // No single "%" here — each plan has its own yearly discount, shown
    // on its own card instead of one (possibly misleading) number for all.
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CycleOption(
              label: 'Theo tháng'.tr,
              selected: cycle == BillingCycle.monthly,
              onTap: () => onChanged(BillingCycle.monthly),
            ),
          ),
          Expanded(
            child: _CycleOption(
              label: 'Theo năm'.tr,
              selected: cycle == BillingCycle.yearly,
              onTap: () => onChanged(BillingCycle.yearly),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CycleOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ServicePlan plan;
  final BillingCycle cycle;
  final bool isCurrent;
  final bool isUpgrading;
  final VoidCallback onUpgrade;

  const _PlanCard({
    required this.plan,
    required this.cycle,
    required this.isCurrent,
    required this.isUpgrading,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? AppColors.accent : AppColors.divider,
          width: isCurrent ? 1.6 : 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.name,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('Gói hiện tại'.tr,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(plan.tagline,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.support_agent_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Text('Liên hệ quản lý'.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 14),
          _FeatureRow(icon: Icons.videocam_outlined, text: plan.cameraLabel),
          const SizedBox(height: 6),
          _FeatureRow(icon: Icons.cloud_outlined, text: '${plan.storageGb.toStringAsFixed(0)} ${'GB lưu trữ'.tr}'),
          const SizedBox(height: 6),
          _FeatureRow(icon: Icons.history_rounded, text: kRetentionPolicy.tr),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: AppColors.textMuted,
                      side: BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Đang sử dụng'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                  )
                : ElevatedButton(
                    onPressed: isUpgrading ? null : onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isUpgrading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Liên hệ quản lý'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
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
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3)),
        ),
      ],
    );
  }
}
