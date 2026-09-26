import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../data/app_theme_store.dart';
import '../data/auth_store.dart';
import 'account_info_screen.dart';
import 'cloud_storage_screen.dart';
import 'service_package_screen.dart';
import '../widgets/prompt_dialog.dart';
import 'gallery_screen.dart';
import 'auth/login_screen.dart';
import '../data/app_release_store.dart';
import 'home/version_history_screen.dart';
import '../utils/app_strings.dart';
import 'setup/qr_scanner_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoPlay = true;
  bool _cellularPlay = true;

  @override
  void initState() {
    super.initState();
    AppReleaseStore.instance.fetchReleases();
  }

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Ngôn ngữ'.tr,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _LangOption(
                      code: 'VI',
                      label: 'Tiếng Việt'.tr,
                      selected: AppThemeStore.instance.lang == 'vi',
                      onTap: () {
                        AppThemeStore.instance.setLanguage('vi');
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                    ),
                    Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
                    _LangOption(
                      code: 'EN',
                      label: 'English',
                      selected: AppThemeStore.instance.lang == 'en',
                      onTap: () {
                        AppThemeStore.instance.setLanguage('en');
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Text(
                  'Cài đặt'.tr,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _Card(children: [
                    _SettingsRow(
                      icon: Icons.person_outline,
                      iconColor: AppColors.accentSecondary,
                      iconBg: AppColors.headerBackground,
                      label: 'Thông tin người dùng'.tr,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const AccountInfoScreen())),
                    ),
                    _SettingsRow(
                      icon: Icons.workspace_premium_outlined,
                      iconColor: AppColors.accentSecondary,
                      iconBg: AppColors.headerBackground,
                      label: 'Gói dịch vụ'.tr,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const ServicePackageScreen())),
                    ),
                    _SettingsRow(
                      icon: Icons.cloud_outlined,
                      iconColor: AppColors.accentSecondary,
                      iconBg: AppColors.headerBackground,
                      label: 'Dung lượng Cloud'.tr,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const CloudStorageScreen())),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  _GroupLabel('Thiết bị'.tr),
                  const SizedBox(height: 8),
                  _Card(children: [
                    _SettingsRow(
                      icon: Icons.qr_code_scanner_outlined,
                      iconColor: AppColors.accent,
                      iconBg: AppColors.accent.withOpacity(0.1),
                      label: 'Thêm thiết bị mới'.tr,
                      subtitle: 'Quét mã QR để cài đặt Gateway Eyerus'.tr,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const QrScannerScreen())),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  _GroupLabel('Trải nghiệm'.tr),
                  const SizedBox(height: 8),
                  _Card(children: [
                    _SettingsRow(
                      icon: Icons.dark_mode_outlined,
                      iconColor: AppColors.info,
                      iconBg: AppColors.info.withOpacity(0.1),
                      label: 'Ngoại hình'.tr,
                      trailingText: themeStr,
                      onTap: () => AppThemeStore.instance.toggleTheme(),
                    ),
                    _SettingsRow(
                      icon: Icons.photo_library_outlined,
                      iconColor: AppColors.info,
                      iconBg: AppColors.info.withOpacity(0.1),
                      label: 'Thư viện ảnh'.tr,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const GalleryScreen())),
                    ),
                    _SettingsRow(
                      icon: Icons.language_outlined,
                      iconColor: AppColors.info,
                      iconBg: AppColors.info.withOpacity(0.1),
                      label: 'Ngôn ngữ'.tr,
                      trailingText: langStr,
                      onTap: _showLanguageDialog,
                    ),
                    _SettingsRow(
                      icon: Icons.play_circle_outline,
                      iconColor: AppColors.success,
                      iconBg: AppColors.success.withOpacity(0.1),
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
                      iconColor: AppColors.success,
                      iconBg: AppColors.success.withOpacity(0.1),
                      label: 'Phát bằng mạng di động'.tr,
                      subtitle: 'Khi bật lên, luôn cho phép phát lại trên mạng di động'.tr,
                      trailingWidget: CupertinoSwitch(
                        value: _cellularPlay,
                        activeColor: AppColors.success,
                        onChanged: (val) => setState(() => _cellularPlay = val),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  _GroupLabel('Hệ thống'.tr),
                  const SizedBox(height: 8),
                  _Card(children: [
                    _SettingsRow(
                      icon: Icons.update_outlined,
                      iconColor: AppColors.warning,
                      iconBg: AppColors.warning.withOpacity(0.12),
                      label: 'Tự Động Cập Nhật'.tr,
                      trailingText: 'Chưa kích hoạt'.tr,
                      onTap: () {},
                    ),
                    _SettingsRow(
                      icon: Icons.memory_outlined,
                      iconColor: AppColors.warning,
                      iconBg: AppColors.warning.withOpacity(0.12),
                      label: 'Phương pháp giải mã'.tr,
                      trailingText: 'Giải mã phần cứng'.tr,
                      onTap: () {},
                    ),
                    ListenableBuilder(
                      listenable: AppReleaseStore.instance,
                      builder: (context, _) => _SettingsRow(
                        icon: Icons.article_outlined,
                        iconColor: AppColors.success,
                        iconBg: AppColors.success.withOpacity(0.1),
                        label: 'Nhật ký'.tr,
                        trailingText: AppReleaseStore.instance.latest?.version,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const VersionHistoryScreen()),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  _Card(children: [
                    _SettingsRow(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.danger,
                      iconBg: AppColors.headerBackground,
                      label: 'Đăng xuất'.tr,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) Divider(height: 1, color: AppColors.divider, indent: 60, endIndent: 14),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final bool danger;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.subtitle,
    this.trailingText,
    this.trailingWidget,
    this.onTap,
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: danger ? AppColors.danger : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ),
                  ],
                ),
              ),
              if (trailingWidget != null)
                trailingWidget!
              else ...[
                if (trailingText != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(trailingText!,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w500)),
                  ),
                if (!danger && onTap != null)
                  Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({required this.code, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? AppColors.headerBackground : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.accentSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.accent : Colors.transparent,
                  border: Border.all(color: selected ? AppColors.accent : AppColors.border, width: 2),
                ),
                alignment: Alignment.center,
                child: selected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
