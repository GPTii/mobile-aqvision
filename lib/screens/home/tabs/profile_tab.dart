import 'package:flutter/material.dart';

import '../../../data/auth_store.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/change_password_sheet.dart';
import '../../../widgets/edit_profile_sheet.dart';
import '../../../widgets/prompt_dialog.dart';
import '../../auth/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Đăng xuất?',
      message: 'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng ứng dụng.',
      confirmLabel: 'Đăng xuất',
    );
    if (!confirmed || !context.mounted) return;
    AuthStore.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthStore.instance,
      builder: (context, _) {
        final user = AuthStore.instance.currentUser;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.accentGradient,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(user?.name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user?.name ?? 'Chưa đăng nhập',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.role ?? '',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Thông tin tài khoản'),
                      const SizedBox(height: 10),
                      _InfoCard(
                        children: [
                          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '--'),
                          _InfoRow(icon: Icons.phone_outlined, label: 'Số điện thoại', value: user?.phone.isNotEmpty == true ? user!.phone : '--'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('Cài đặt'),
                      const SizedBox(height: 10),
                      _ActionCard(
                        children: [
                          _ActionRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Chỉnh sửa thông tin cá nhân',
                            onTap: () => showEditProfileSheet(context),
                          ),
                          _ActionRow(
                            icon: Icons.lock_outline_rounded,
                            label: 'Đổi mật khẩu',
                            onTap: () => showChangePasswordSheet(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _ActionCard(
                        children: [
                          _ActionRow(
                            icon: Icons.logout_rounded,
                            label: 'Đăng xuất',
                            danger: true,
                            onTap: () => _logout(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
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
          const SizedBox(width: 12),
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
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
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
              const SizedBox(width: 12),
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
