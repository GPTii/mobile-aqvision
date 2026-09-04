import 'package:flutter/material.dart';

import '../../data/settings_store.dart';
import '../../theme/app_colors.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  static const _options = [
    (mode: AppThemeMode.light, icon: Icons.light_mode_outlined, label: 'Sáng', desc: 'Nền trắng, phù hợp ban ngày'),
    (mode: AppThemeMode.dark, icon: Icons.dark_mode_outlined, label: 'Tối', desc: 'Nền đen, dịu mắt ban đêm'),
    (
      mode: AppThemeMode.system,
      icon: Icons.settings_suggest_outlined,
      label: 'Theo hệ thống',
      desc: 'Tự đổi theo cài đặt điện thoại'
    ),
  ];

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
                      child: Text('Ngoại hình',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: SettingsStore.instance,
                builder: (context, _) {
                  final current = SettingsStore.instance.themeMode;
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
                            for (var i = 0; i < _options.length; i++) ...[
                              _ThemeOptionTile(
                                option: _options[i],
                                selected: current == _options[i].mode,
                                onTap: () => SettingsStore.instance.setThemeMode(_options[i].mode),
                              ),
                              if (i != _options.length - 1)
                                Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Lựa chọn của bạn được lưu lại ngay. Chế độ tối cho toàn bộ giao diện sẽ có trong bản cập nhật sau.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                              ),
                            ),
                          ],
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

class _ThemeOptionTile extends StatelessWidget {
  final ({AppThemeMode mode, IconData icon, String label, String desc}) option;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({required this.option, required this.selected, required this.onTap});

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
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFDEAEC) : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(option.icon, size: 17, color: selected ? AppColors.accentSecondary : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(option.desc, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  ],
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
                child: selected
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
