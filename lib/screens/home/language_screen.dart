import 'package:flutter/material.dart';

import '../../data/settings_store.dart';
import '../../theme/app_colors.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const _options = [
    (lang: AppLanguage.vi, code: 'VI', label: 'Tiếng Việt'),
    (lang: AppLanguage.en, code: 'EN', label: 'English'),
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
                      child: Text('Ngôn ngữ',
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
                  final current = SettingsStore.instance.language;
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
                              _LangTile(
                                option: _options[i],
                                selected: current == _options[i].lang,
                                onTap: () => SettingsStore.instance.setLanguage(_options[i].lang),
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
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Bản tiếng Anh cho toàn bộ ứng dụng đang được chuẩn bị — lựa chọn của bạn sẽ được lưu và áp dụng ngay khi có.',
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

class _LangTile extends StatelessWidget {
  final ({AppLanguage lang, String code, String label}) option;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({required this.option, required this.selected, required this.onTap});

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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFDEAEC) : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(option.code,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected ? AppColors.accentSecondary : AppColors.textSecondary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(option.label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
