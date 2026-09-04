import 'package:flutter/material.dart';

import '../../../data/settings_store.dart';
import '../../../data/storage_store.dart';
import '../../../data/subscription_store.dart';
import '../../../theme/app_colors.dart';
import '../account_security_screen.dart';
import '../appearance_screen.dart';
import '../auto_update_screen.dart';
import '../language_screen.dart';
import '../plan_detail_screen.dart';
import '../version_history_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    SubscriptionStore.instance.fetchAll();
    StorageStore.instance.fetchStorage();
    SettingsStore.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.headerBackground,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Text(
                  'Cài đặt',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Card(children: [
                    _ActionRow(
                      icon: Icons.shield_outlined,
                      iconColor: AppColors.accentSecondary,
                      iconBg: const Color(0xFFFDEAEC),
                      label: 'Tài khoản & bảo mật',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AccountSecurityScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  ListenableBuilder(
                    listenable: SubscriptionStore.instance,
                    builder: (context, _) => _Card(children: [
                      _ActionRow(
                        icon: Icons.workspace_premium_outlined,
                        iconColor: AppColors.accentSecondary,
                        iconBg: const Color(0xFFFDEAEC),
                        label: 'Gói dịch vụ',
                        value: SubscriptionStore.instance.currentPlan?.name,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlanDetailScreen()),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  const _SectionLabel('Trải nghiệm'),
                  const SizedBox(height: 10),
                  _Card(children: [
                    _ActionRow(
                      icon: Icons.dark_mode_outlined,
                      iconColor: AppColors.info,
                      iconBg: AppColors.info.withOpacity(0.1),
                      label: 'Ngoại hình',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                      ),
                    ),
                    _ActionRow(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.info,
                      iconBg: AppColors.info.withOpacity(0.1),
                      label: 'Ngôn ngữ',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LanguageScreen()),
                      ),
                    ),
                    const _MobileDataToggleRow(),
                  ]),
                  const SizedBox(height: 20),

                  const _SectionLabel('Hệ thống'),
                  const SizedBox(height: 10),
                  _Card(children: [
                    _ActionRow(
                      icon: Icons.system_update_alt_rounded,
                      iconColor: AppColors.warning,
                      iconBg: AppColors.warning.withOpacity(0.12),
                      label: 'Tự động cập nhật',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AutoUpdateScreen()),
                      ),
                    ),
                    _ActionRow(
                      icon: Icons.receipt_long_rounded,
                      iconColor: AppColors.success,
                      iconBg: AppColors.success.withOpacity(0.1),
                      label: 'Nhật ký',
                      subtitle: kAppVersionHistory.isEmpty
                          ? null
                          : 'Phiên bản ${kAppVersionHistory.first.version} · cập nhật & sửa lỗi',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VersionHistoryScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  _Card(children: [
                    _ActionRow(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.danger,
                      iconBg: const Color(0xFFFDEAEC),
                      label: 'Đăng xuất',
                      danger: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AccountSecurityScreen()),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile data playback toggle ──────────────────────────────────────────

class _MobileDataToggleRow extends StatelessWidget {
  const _MobileDataToggleRow();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final value = SettingsStore.instance.playOnMobileData;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Icon(Icons.signal_cellular_alt_rounded, size: 17, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phát bằng mạng di động',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('Khi bật lên, luôn cho phép phát lại trên mạng di động',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: (v) => SettingsStore.instance.setPlayOnMobileData(v),
                activeTrackColor: AppColors.success,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared row / card widgets ────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5));
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

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
            if (i != children.length - 1) Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? subtitle;
  final String? value;
  final VoidCallback onTap;
  final bool danger;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: danger ? AppColors.danger : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ),
                  ],
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                ),
              if (!danger) const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
