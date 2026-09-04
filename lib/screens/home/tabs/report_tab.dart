import '../../../utils/app_strings.dart';
import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import '../../../data/camera_store.dart';
import '../../../data/stats_store.dart';
import '../../../data/storage_store.dart';
import '../../../theme/app_colors.dart';
import '../groups_screen.dart';
import '../record_list_screen.dart';

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  @override
  void initState() {
    super.initState();
    StatsStore.instance.fetchStats();
    StorageStore.instance.fetchStorage();
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      CameraStore.instance.fetchCameras(),
      CameraStore.instance.fetchGroups(),
      StatsStore.instance.fetchStats(),
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
              // Header
              SliverToBoxAdapter(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                              '${cameras.length} ' + 'camera'.tr + ' · ${groups.length} ' + 'nhóm'.tr,
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
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Status cards row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListenableBuilder(
                    listenable: CameraStore.instance.listAndStatus,
                    builder: (ctx, _) {
                      final cameras = CameraStore.instance.cameras;
                      final groups = CameraStore.instance.groups;
                      final online = cameras.where((c) => c.online).length;
                      final offline = cameras.length - online;
                      return Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Đang hoạt động'.tr,
                              value: '$online',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Offline',
                              value: '$offline',
                              icon: Icons.power_off_rounded,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Tổng nhóm'.tr,
                              value: '${groups.length}',
                              icon: Icons.folder_rounded,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

                // Dashboard Charts (fl_chart)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListenableBuilder(
                      listenable: StatsStore.instance,
                      builder: (ctx, _) {
                        final stats = StatsStore.instance.stats;
                        if (stats == null) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        // Pie Chart Data
                        final online = stats.onlineCameras.toDouble();
                        final offline = stats.offlineCameras.toDouble();
                        final total = online + offline;

                        // Bar Chart Data (Disk in GB)
                        final diskUsedGB = stats.diskUsed / (1024 * 1024 * 1024);
                        final diskFreeGB = stats.diskFree / (1024 * 1024 * 1024);

                        return Column(
                          children: [
                            // Camera Pie Chart
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tỷ lệ Camera'.tr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 150,
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 40,
                                        sections: [
                                          PieChartSectionData(
                                            color: AppColors.success,
                                            value: online,
                                            title: '${((online/total)*100).toStringAsFixed(0)}%',
                                            radius: 30,
                                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          if (offline > 0)
                                            PieChartSectionData(
                                              color: AppColors.danger,
                                              value: offline,
                                              title: '${((offline/total)*100).toStringAsFixed(0)}%',
                                              radius: 30,
                                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _Dot(color: AppColors.success), SizedBox(width: 4), Text('Online', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 16),
                                      _Dot(color: AppColors.danger), SizedBox(width: 4), Text('Offline', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Storage Bar Chart
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dung lượng lưu trữ (GB)'.tr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 150,
                                    child: BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        maxY: diskUsedGB + diskFreeGB + 50,
                                        barTouchData: BarTouchData(enabled: false),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                if (value == 0) return Text('Đã dùng'.tr, style: TextStyle(fontSize: 10));
                                                if (value == 1) return Text('Trống'.tr, style: TextStyle(fontSize: 10));
                                                return const Text('');
                                              },
                                            ),
                                          ),
                                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        gridData: const FlGridData(show: false),
                                        borderData: FlBorderData(show: false),
                                        barGroups: [
                                          BarChartGroupData(
                                            x: 0,
                                            barRods: [BarChartRodData(toY: diskUsedGB, color: AppColors.danger, width: 20, borderRadius: BorderRadius.circular(4))],
                                            showingTooltipIndicators: [0],
                                          ),
                                          BarChartGroupData(
                                            x: 1,
                                            barRods: [BarChartRodData(toY: diskFreeGB, color: AppColors.success, width: 20, borderRadius: BorderRadius.circular(4))],
                                            showingTooltipIndicators: [0],
                                          ),
                                        ],
                                      ),
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
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Quick actions + groups (structure + status)
                SliverToBoxAdapter(
                  child: ListenableBuilder(
                    listenable: CameraStore.instance.listAndStatus,
                    builder: (ctx, _) {
                      final cameras = CameraStore.instance.cameras;
                      final groups = CameraStore.instance.groups;
                      final ungrouped = cameras
                          .where((c) => c.groupIds.every((id) =>
                              CameraStore.instance.groupById(id) == null))
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Truy cập nhanh'.tr,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickAction(
                                    icon: Icons.video_library_rounded,
                                    label: 'Bản ghi'.tr,
                                    sublabel: 'Xem & quản lý'.tr,
                                    color: AppColors.danger,
                                    onTap: cameras.isEmpty
                                        ? null
                                        : () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      RecordingListScreen(
                                                          cameraId: cameras
                                                              .first.id)),
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _QuickAction(
                                    icon: Icons.folder_rounded,
                                    label: 'Nhóm'.tr,
                                    sublabel: 'Quản lý nhóm'.tr,
                                    color: AppColors.info,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const GroupsScreen()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (groups.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('Camera theo nhóm'.tr,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const GroupsScreen()),
                                    ),
                                    child: Text('Quản lý →'.tr,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...groups.map((group) {
                                final cams = CameraStore.instance
                                    .camerasInGroup(group.id);
                                final onlineCams =
                                    cams.where((c) => c.online).length;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(14),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: AppColors.info
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                              Icons.folder_rounded,
                                              color: AppColors.info,
                                              size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(group.name,
                                                  style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors
                                                          .textPrimary)),
                                              const SizedBox(height: 3),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: cams.isEmpty
                                                      ? 0
                                                      : onlineCams /
                                                          cams.length,
                                                  backgroundColor:
                                                      AppColors.border,
                                                  color: AppColors.success,
                                                  minHeight: 4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text('${cams.length}',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color: AppColors
                                                        .textPrimary)),
                                            Text('$onlineCams online',
                                                style: TextStyle(
                                                    fontSize: 10.5,
                                                    color:
                                                        AppColors.success)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                            if (ungrouped.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Chưa phân nhóm'.tr,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted)),
                              const SizedBox(height: 8),
                              ...ungrouped.map((c) => _CameraRow(camera: c)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Cloud storage usage
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListenableBuilder(
                      listenable: StorageStore.instance,
                      builder: (ctx, _) => const _StorageSection(),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub widgets ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 10),
                Text(label,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text(sublabel,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraRow extends StatelessWidget {
  final dynamic camera;
  const _CameraRow({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: camera.online ? AppColors.success : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(camera.name,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(camera.online ? 'Online' : 'Offline',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: camera.online ? AppColors.success : AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Cloud storage ────────────────────────────────────────────────────────────

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
