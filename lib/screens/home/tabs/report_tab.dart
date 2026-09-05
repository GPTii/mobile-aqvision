import 'package:flutter/material.dart';

import '../../../data/camera_store.dart';
import '../../../data/storage_store.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/app_strings.dart';

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  @override
  void initState() {
    super.initState();
    StorageStore.instance.fetchStorage();
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      CameraStore.instance.fetchCameras(),
      CameraStore.instance.fetchGroups(),
      StorageStore.instance.fetchStorage(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Header()),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OverviewCard(),
                      const SizedBox(height: 16),
                      ListenableBuilder(
                        listenable: StorageStore.instance,
                        builder: (ctx, _) => _StorageSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ListenableBuilder(
          listenable: CameraStore.instance.listAndStatus,
          builder: (ctx, _) {
            final cameras = CameraStore.instance.cameras;
            final groups = CameraStore.instance.groups;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Báo cáo'.tr,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${cameras.length} camera · ${groups.length} ${'nhóm'.tr}',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Reusable section card ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(title!,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ),
          child,
        ],
      ),
    );
  }
}

// ── Overview: status tiles ───────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  const _OverviewCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CameraStore.instance.listAndStatus,
      builder: (ctx, _) {
        final cameras = CameraStore.instance.cameras;
        final groups = CameraStore.instance.groups;
        final online = cameras.where((c) => c.online).length;
        final offline = cameras.length - online;

        return _SectionCard(
          title: 'Tổng quan hệ thống'.tr,
          child: Column(
            children: [
              _StatTile(
                  icon: Icons.check_circle_rounded,
                  label: 'Đang hoạt động'.tr,
                  value: '$online',
                  color: AppColors.success),
              const SizedBox(height: 12),
              _StatTile(
                  icon: Icons.power_off_rounded,
                  label: 'Offline',
                  value: '$offline',
                  color: AppColors.textMuted),
              const SizedBox(height: 12),
              _StatTile(
                  icon: Icons.folder_rounded,
                  label: 'Tổng nhóm'.tr,
                  value: '${groups.length}',
                  color: AppColors.info),
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

// ── Cloud storage (unchanged) ────────────────────────────────────────────────

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
            padding: EdgeInsets.symmetric(vertical: 12),
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
              child: Text(store.error!,
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
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
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(' / ${_formatMb(store.storageQuotaMb)}',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
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
                        style: TextStyle(
                            fontSize: 12,
                            color: tierInfo.color,
                            fontWeight: FontWeight.w600,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
          if (store.cameras.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Camera chiếm nhiều dung lượng nhất'.tr,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Text(_formatMb(camera.usedStorageMb),
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
