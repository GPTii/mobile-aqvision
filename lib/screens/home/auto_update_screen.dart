import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/settings_store.dart';
import '../../theme/app_colors.dart';

class AutoUpdateScreen extends StatelessWidget {
  const AutoUpdateScreen({super.key});

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
                      child: Text('Tự động cập nhật',
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
                  final enabled = SettingsStore.instance.autoUpdateEnabled;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.system_update_alt_rounded, size: 17, color: AppColors.warning),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tự động cập nhật lên bản mới nhất',
                                        style: TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    SizedBox(height: 2),
                                    Text('Nhắc cài bản mới ngay khi có, không cần kiểm tra thủ công.',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: enabled,
                                onChanged: (v) => SettingsStore.instance.setAutoUpdateEnabled(v),
                                activeTrackColor: AppColors.success,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final info = snapshot.data;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    info == null
                                        ? 'Đang kiểm tra phiên bản...'
                                        : 'Bạn đang dùng bản mới nhất — phiên bản ${info.version} (${info.buildNumber}).',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
