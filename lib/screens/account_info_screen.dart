import 'package:flutter/material.dart';
import '../data/auth_store.dart';
import '../data/business_info_store.dart';
import '../theme/app_colors.dart';
import '../widgets/change_password_sheet.dart';
import '../widgets/prompt_dialog.dart';
import '../utils/app_strings.dart';
import 'auth/login_screen.dart';
import 'edit_account_screen.dart';
import '../widgets/app_ui.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Đăng xuất?'.tr,
      message: 'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng ứng dụng.'.tr,
      confirmLabel: 'Đăng xuất'.tr,
    );
    if (!confirmed || !context.mounted) return;
    await AuthStore.instance.logout();

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([AuthStore.instance, BusinessInfoStore.instance]),
          builder: (context, _) {
            final user = AuthStore.instance.currentUser;
            final biz = BusinessInfoStore.instance;

            return Column(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                        ),
                        Expanded(
                          child: Text(
                            'Thông tin người dùng'.tr,
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
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
                      _GroupLabel('Thông tin tài khoản'.tr),
                      const SizedBox(height: 8),
                      _Card(children: [
                        _FieldRow(icon: Icons.email_outlined, label: 'Email'.tr, value: user?.email ?? '--'),
                        _FieldRow(
                          icon: Icons.phone_outlined,
                          label: 'Số điện thoại'.tr,
                          value: user?.phone.isNotEmpty == true ? user!.phone : '--',
                        ),
                      ]),
                      const SizedBox(height: 18),
                      _GroupLabel('Thông tin doanh nghiệp'.tr),
                      const SizedBox(height: 8),
                      _Card(children: [
                        _BizField('Tên doanh nghiệp'.tr, biz.companyName),
                        _BizField('Giấy chứng nhận ĐKKD'.tr, biz.registrationNo),
                        _BizField('Trụ sở chính'.tr, biz.address),
                        _BizField('Mã số thuế'.tr, biz.taxCode),
                        _BizField('Email liên hệ'.tr, biz.contactEmail),
                        _BizField('Hotline hỗ trợ'.tr, biz.hotline),
                      ]),
                      const SizedBox(height: 18),
                      _GroupLabel('Bảo mật'.tr),
                      const SizedBox(height: 8),
                      _Card(children: [
                        _ActionRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Chỉnh sửa thông tin'.tr,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EditAccountScreen()),
                          ),
                        ),
                        _ActionRow(
                          icon: Icons.lock_outline_rounded,
                          label: 'Đổi mật khẩu'.tr,
                          onTap: () => showChangePasswordSheet(context),
                        ),
                      ]),
                      const SizedBox(height: 18),
                      _Card(children: [
                        _ActionRow(
                          icon: Icons.logout_rounded,
                          label: 'Đăng xuất'.tr,
                          danger: true,
                          onTap: () => _logout(context),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ));
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
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
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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

class _BizField extends StatelessWidget {
  final String label;
  final String value;
  const _BizField(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text(
            hasValue ? value : '— chưa cập nhật —'.tr,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 13,
              color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
              fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
            ),
          ),
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
