import 'package:flutter/material.dart';

import '../../data/auth_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/change_password_sheet.dart';
import '../../widgets/edit_profile_sheet.dart';
import '../../widgets/prompt_dialog.dart';
import '../auth/login_screen.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Đăng xuất?',
      message: 'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng ứng dụng.',
      confirmLabel: 'Đăng xuất',
    );
    if (!confirmed || !context.mounted) return;
    await AuthStore.instance.logout();

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
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
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textPrimary, size: 20),
                        ),
                        const Expanded(
                          child: Text(
                            'Tài khoản & bảo mật',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _Card(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.accentGradient,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _initials(user?.name),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.name ?? 'Chưa đăng nhập',
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      user?.role ?? '',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 18),

                      const _GroupLabel('Thông tin tài khoản'),
                      const SizedBox(height: 8),
                      _Card(children: [
                        _FieldRow(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '--'),
                        _FieldRow(
                          icon: Icons.phone_outlined,
                          label: 'Số điện thoại',
                          value: user?.phone.isNotEmpty == true ? user!.phone : '--',
                        ),
                      ]),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          const _GroupLabel('Thông tin doanh nghiệp'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('MẪU',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _Card(children: [
                        _BizField('Tên doanh nghiệp'),
                        _BizField('Giấy chứng nhận ĐKKD'),
                        _BizField('Trụ sở chính'),
                        _BizField('Mã số thuế'),
                        _BizField('Email liên hệ'),
                        _BizField('Hotline hỗ trợ'),
                      ]),
                      const SizedBox(height: 18),

                      const _GroupLabel('Bảo mật'),
                      const SizedBox(height: 8),
                      _Card(children: [
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
                      ]),
                      const SizedBox(height: 18),

                      _Card(children: [
                        _ActionRow(
                          icon: Icons.logout_rounded,
                          label: 'Đăng xuất',
                          danger: true,
                          onTap: () => _logout(context),
                        ),
                      ]),
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
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
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
            if (i != children.length - 1)
              Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _FieldRow({required this.icon, required this.label, required this.value});

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

class _BizField extends StatelessWidget {
  final String label;
  const _BizField(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.3)),
          const SizedBox(height: 3),
          const Text('— chưa cập nhật —',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
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

  const _ActionRow({required this.icon, required this.label, required this.onTap, this.danger = false});

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
                child: Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              if (!danger) Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
