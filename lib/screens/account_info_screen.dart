import 'package:flutter/material.dart';
import '../data/auth_store.dart';
import '../theme/app_colors.dart';
import '../widgets/change_password_sheet.dart';
import '../widgets/edit_profile_sheet.dart';
import '../utils/app_strings.dart';

class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({super.key});

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Thông tin người dùng'.tr, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.card,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: AuthStore.instance,
        builder: (context, _) {
          final user = AuthStore.instance.currentUser;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.headerBackground,
                  borderRadius: const BorderRadius.only(
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
                        decoration: BoxDecoration(
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
                      SizedBox(height: 14),
                      Text(
                        user?.name ?? 'Chưa đăng nhập'.tr,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
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
                    Text('Thông tin tài khoản'.tr, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.email_outlined, 'Email', user?.email ?? '--'),
                          Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
                          _buildInfoRow(Icons.phone_outlined, 'Số điện thoại'.tr, user?.phone.isNotEmpty == true ? user!.phone : '--'),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Text('Tài khoản và bảo mật'.tr, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _buildActionRow(Icons.person_outline, 'Chỉnh sửa thông tin'.tr, () => showEditProfileSheet(context)),
                          Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
                          _buildActionRow(Icons.lock_outline, 'Đổi mật khẩu'.tr, () => showChangePasswordSheet(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          SizedBox(width: 12),
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

  Widget _buildActionRow(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 19, color: AppColors.textSecondary),
              SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
