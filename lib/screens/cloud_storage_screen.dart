import 'package:flutter/material.dart';

import '../data/storage_store.dart';
import '../theme/app_colors.dart';
import '../utils/app_strings.dart';

/// Cloud storage detail — moved here from the old Report tab. Reachable from
/// Settings ("Dung lượng Cloud") instead of living in a dedicated tab.
class CloudStorageScreen extends StatefulWidget {
  const CloudStorageScreen({super.key});

  @override
  State<CloudStorageScreen> createState() => _CloudStorageScreenState();
}

class _CloudStorageScreenState extends State<CloudStorageScreen> {
  @override
  void initState() {
    super.initState();
    StorageStore.instance.fetchStorage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        'Dung lượng Cloud'.tr,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: StorageStore.instance.fetchStorage,
                color: AppColors.accent,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  children: [
                    ListenableBuilder(
                      listenable: StorageStore.instance,
                      builder: (ctx, _) => const _StorageSection(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cloud storage ─────────────────────────────────────────────────────────────

class _TierInfo {
  final String label;
  final Color color;
  final String? message;
  const _TierInfo(this.label, this.color, this.message);
}

const _warn2Color = Color(0xFFC2410C);

_TierInfo _tierInfo(String tier) {
  switch (tier) {
    case 'warn':
      return _TierInfo(
        'Sắp đầy'.tr,
        AppColors.warning,
        'Dung lượng sắp đầy. Xoá bớt recording cũ hoặc liên hệ quản trị viên để tăng dung lượng.'.tr,
      );
    case 'warn2':
      return _TierInfo(
        'Gần đầy'.tr,
        _warn2Color,
        'Dung lượng gần đầy. Xoá bớt recording cũ hoặc liên hệ quản trị viên để tăng dung lượng.'.tr,
      );
    case 'bad':
      return _TierInfo(
        'Nguy cấp'.tr,
        AppColors.danger,
        'Dung lượng sắp hết. Liên hệ quản trị viên ngay để tránh gián đoạn ghi hình.'.tr,
      );
    case 'full':
      return _TierInfo(
        'Đã đầy'.tr,
        AppColors.danger,
        'Đã đầy dung lượng — recording mới sẽ KHÔNG được lưu cho tới khi bạn xoá bớt hoặc được tăng dung lượng. Dữ liệu cũ vẫn an toàn, không bị xoá.'.tr,
      );
    default:
      return _TierInfo('Bình thường'.tr, AppColors.success, null);
  }
}

String _formatMb(double mb) {
  if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
  return '${mb.toStringAsFixed(0)} MB';
}

class _StorageCard extends StatelessWidget {
  final Widget child;
  const _StorageCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _StorageSection extends StatelessWidget {
  const _StorageSection();

  @override
  Widget build(BuildContext context) {
    final store = StorageStore.instance;

    if (store.loading && store.storageQuotaMb == 0) {
      return _StorageCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
            ),
          ),
        ),
      );
    }

    if (store.error != null) {
      return _StorageCard(
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(store.error!, style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            ),
          ],
        ),
      );
    }

    final tierInfo = _tierInfo(store.tier);
    final pct = (store.percent / 100).clamp(0.0, 1.0);

    return _StorageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Dung lượng Cloud'.tr,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
              _TierBadge(label: tierInfo.label, color: tierInfo.color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_formatMb(store.usedStorageMb),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(' / ${_formatMb(store.storageQuotaMb)}', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const Spacer(),
              Text('${store.percent.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tierInfo.color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              color: tierInfo.color,
              minHeight: 8,
            ),
          ),
          if (tierInfo.message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tierInfo.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tierInfo.color.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, size: 16, color: tierInfo.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tierInfo.message!,
                        style: TextStyle(fontSize: 12, color: tierInfo.color, fontWeight: FontWeight.w600, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
          if (store.cameras.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Camera chiếm nhiều dung lượng nhất'.tr,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            ...store.cameras.take(5).map((c) => _StorageCameraRow(camera: c)),
          ],
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TierBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _StorageCameraRow extends StatelessWidget {
  final CameraStorageUsage camera;
  const _StorageCameraRow({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(camera.name,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Text(_formatMb(camera.usedStorageMb),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
