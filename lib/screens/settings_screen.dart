import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../data/app_theme_store.dart';
import '../data/auth_store.dart';
import 'account_info_screen.dart';
import 'service_package_screen.dart';
import '../widgets/prompt_dialog.dart';
import 'gallery_screen.dart';
import 'auth/login_screen.dart';
import 'home/version_history_screen.dart';
import '../utils/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoPlay = true;
  bool _cellularPlay = true;

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

  void _showLanguageDialog() {
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Tiếng Việt'.tr, style: TextStyle(color: AppColors.textPrimary)),
              trailing: AppThemeStore.instance.lang == 'vi' ? Icon(Icons.check, color: AppColors.accent) : null,
              onTap: () {
                AppThemeStore.instance.setLanguage('vi');
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
            ListTile(
              title: Text('English', style: TextStyle(color: AppColors.textPrimary)),
              trailing: AppThemeStore.instance.lang == 'en' ? Icon(Icons.check, color: AppColors.accent) : null,
              onTap: () {
                AppThemeStore.instance.setLanguage('en');
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    
    final langStr = AppThemeStore.instance.lang == 'vi' ? 'Tiếng Việt'.tr : 'English';
    final themeStr = AppThemeStore.instance.isDark ? 'Tối'.tr : 'Sáng'.tr;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Cài Đặt'.tr, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.card,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.person_outline,
            label: 'Thông tin người dùng'.tr,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountInfoScreen())),
          ),
          _SettingsRow(
            icon: Icons.workspace_premium_outlined,
            label: 'Gói dịch vụ'.tr,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServicePackageScreen())),
          ),
          
          SizedBox(height: 20),
          _SettingsRow(
            icon: Icons.dark_mode_outlined,
            label: 'Ngoại hình'.tr,
            trailingText: themeStr,
            onTap: () => AppThemeStore.instance.toggleTheme(),
          ),
          _SettingsRow(
            icon: Icons.photo_library_outlined,
            label: 'Thư viện ảnh'.tr,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GalleryScreen())),
          ),
          _SettingsRow(
            icon: Icons.language_outlined,
            label: 'Ngôn ngữ'.tr,
            trailingText: langStr,
            onTap: _showLanguageDialog,
          ),
          _SettingsRow(
            icon: Icons.play_circle_outline,
            label: 'Phát lại tự động'.tr,
            subtitle: 'Tự động phát chế độ xem trực tiếp trên trang chủ.'.tr,
            trailingWidget: CupertinoSwitch(
              value: _autoPlay,
              activeColor: AppColors.success,
              onChanged: (val) => setState(() => _autoPlay = val),
            ),
          ),
          _SettingsRow(
            icon: Icons.signal_cellular_alt_outlined,
            label: 'Phát bằng mạng di động'.tr,
            subtitle: 'Khi bật lên, luôn cho phép phát lại trên mạng di động'.tr,
            trailingWidget: CupertinoSwitch(
              value: _cellularPlay,
              activeColor: AppColors.success,
              onChanged: (val) => setState(() => _cellularPlay = val),
            ),
          ),

          SizedBox(height: 20),
          _SettingsRow(
            icon: Icons.update_outlined,
            label: 'Tự Động Cập Nhật'.tr,
            trailingText: 'Chưa kích hoạt'.tr,
            onTap: () {},
          ),
          _SettingsRow(
            icon: Icons.memory_outlined,
            label: 'Phương pháp giải mã'.tr,
            trailingText: 'Giải mã phần cứng'.tr,
            onTap: () {},
          ),
          _SettingsRow(
            icon: Icons.lock_reset_outlined,
            label: 'Đặt lại mật khẩu thiết bị'.tr,
            onTap: () {},
          ),
          _SettingsRow(
            icon: Icons.article_outlined,
            label: 'Nhật ký'.tr,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VersionHistoryScreen()),
            ),
          ),

          SizedBox(height: 20),
          Container(
            color: AppColors.card,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Icon(Icons.logout, color: AppColors.danger),
              title: Text(
                'Đăng xuất'.tr,
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
              ),
              onTap: () => _logout(context),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailingText,
    this.trailingWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Icon(icon, color: AppColors.textSecondary, size: 26),
            title: Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: AppColors.textMuted, fontSize: 12)) : null,
            trailing: trailingWidget ?? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingText != null)
                  Text(trailingText!, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                if (onTap != null)
                  Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
            onTap: onTap,
          ),
          Divider(height: 1, indent: 60, color: AppColors.divider),
        ],
      ),
    );
  }
}
