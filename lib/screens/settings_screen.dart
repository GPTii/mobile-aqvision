import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../config/api_config.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui.dart';
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
                    for (final (i, e) in AppStrings.languages.entries.indexed) ...[
                      if (i > 0) Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
                      _LangOption(
                        code: const {'vi': 'VI', 'en': 'EN', 'ko': 'KO', 'zh_Hant': '繁'}[e.key]!,
                        label: e.value,
                        selected: AppThemeStore.instance.lang == e.key,
                        onTap: () {
                          AppThemeStore.instance.setLanguage(e.key);
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                      ),
                    ],
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
    final langStr = AppStrings.languages[AppThemeStore.instance.lang] ?? 'Tiếng Việt';
    final themeStr = AppThemeStore.instance.isDark ? 'Tối'.tr : 'Sáng'.tr;

    final user = AuthStore.instance.currentUser;
    Widget sw(bool v, ValueChanged<bool> onChanged) => CupertinoSwitch(
          value: v,
          activeTrackColor: AppColors.accent,
          onChanged: onChanged,
        );
    void open(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            children: [
              AppPageHeader(title: 'Cài đặt'.tr, padding: const EdgeInsets.fromLTRB(4, 14, 4, 18)),
              _ProfileCard(
                name: user?.name ?? 'Người dùng'.tr,
                detail: user?.email ?? '',
                onTap: () => open(const AccountInfoScreen()),
              ),
              const SizedBox(height: 14),
              AppCard(children: [
                AppListTile(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: AppIconColors.orange,
                  title: 'Gói dịch vụ'.tr,
                  onTap: () => open(const ServicePackageScreen()),
                ),
                AppListTile(
                  icon: Icons.cloud_rounded,
                  iconColor: AppIconColors.blue,
                  title: 'Dung lượng Cloud'.tr,
                  onTap: () => open(const CloudStorageScreen()),
                ),
                AppListTile(
                  icon: Icons.photo_library_rounded,
                  iconColor: AppIconColors.pink,
                  title: 'Thư viện ảnh'.tr,
                  onTap: () => open(const GalleryScreen()),
                ),
              ]),
              AppSectionTitle('Trải nghiệm'.tr),
              AppCard(children: [
                AppListTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: AppIconColors.purple,
                  title: 'Ngoại hình'.tr,
                  trailingText: themeStr,
                  onTap: () => AppThemeStore.instance.toggleTheme(),
                ),
                AppListTile(
                  icon: Icons.translate_rounded,
                  iconColor: AppIconColors.teal,
                  title: 'Ngôn ngữ'.tr,
                  trailingText: langStr,
                  onTap: _showLanguageDialog,
                ),
                AppListTile(
                  icon: Icons.play_circle_fill_rounded,
                  iconColor: AppIconColors.green,
                  title: 'Phát lại tự động'.tr,
                  subtitle: 'Tự động phát chế độ xem trực tiếp trên trang chủ.'.tr,
                  trailing: sw(_autoPlay, (v) => setState(() => _autoPlay = v)),
                ),
                AppListTile(
                  icon: Icons.signal_cellular_alt_rounded,
                  iconColor: AppIconColors.cyan,
                  title: 'Phát bằng mạng di động'.tr,
                  subtitle: 'Khi bật lên, luôn cho phép phát lại trên mạng di động'.tr,
                  trailing: sw(_cellularPlay, (v) => setState(() => _cellularPlay = v)),
                ),
              ]),
              AppSectionTitle('Hệ thống'.tr),
              AppCard(children: [
                AppListTile(
                  icon: Icons.system_update_rounded,
                  iconColor: AppIconColors.amber,
                  title: 'Tự Động Cập Nhật'.tr,
                  trailingText: 'Chưa kích hoạt'.tr,
                  onTap: () {},
                ),
                AppListTile(
                  icon: Icons.memory_rounded,
                  iconColor: AppIconColors.indigo,
                  title: 'Phương pháp giải mã'.tr,
                  trailingText: 'Giải mã phần cứng'.tr,
                  onTap: () {},
                ),
                ListenableBuilder(
                  listenable: AppReleaseStore.instance,
                  builder: (context, _) => AppListTile(
                    icon: Icons.article_rounded,
                    iconColor: AppColors.accent,
                    title: 'Nhật ký'.tr,
                    trailingText: AppReleaseStore.instance.installedVersion ?? AppReleaseStore.instance.latest?.version,
                    onTap: () => open(const VersionHistoryScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              AppCard(children: [
                AppListTile(
                  icon: ApiConfig.isLocal ? Icons.lan_outlined : Icons.cloud_outlined,
                  iconColor: ApiConfig.isLocal ? AppColors.accent : AppColors.success,
                  title: 'Máy chủ kết nối'.tr,
                  trailingText: ApiConfig.isLocal ? ApiConfig.localOrigin : 'dev1.aqvision.net',
                  onTap: () {},
                ),
                AppListTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.danger,
                  title: 'Đăng xuất'.tr,
                  danger: true,
                  onTap: () => _logout(context),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar + name + account detail, like the "me" header of smart-home apps.
class _ProfileCard extends StatelessWidget {
  final String name;
  final String detail;
  final VoidCallback onTap;

  const _ProfileCard({required this.name, required this.detail, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppColors.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(gradient: AppColors.accentGradient, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(initial,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 26, color: AppColors.textMuted.withValues(alpha: 0.7)),
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
