import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import '../../../data/camera_store.dart';
import '../../../data/stats_store.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CameraStore.instance,
      builder: (ctx, _) {
        final cameras = CameraStore.instance.cameras;
        final groups = CameraStore.instance.groups;
        final online = cameras.where((c) => c.online).length;
        final offline = cameras.length - online;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.headerBackground,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Báo cáo',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(
                            '${cameras.length} camera · ${groups.length} nhóm',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Status cards row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Đang hoạt động',
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
                            label: 'Tổng nhóm',
                            value: '${groups.length}',
                            icon: Icons.folder_rounded,
                            color: AppColors.info,
                          ),
                        ),
                      ],
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
                                  const Text('Tỷ lệ Camera', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                                      _Dot(color: AppColors.success), const SizedBox(width: 4), const Text('Online', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 16),
                                      _Dot(color: AppColors.danger), const SizedBox(width: 4), const Text('Offline', style: TextStyle(fontSize: 12)),
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
                                  const Text('Dung lượng lưu trữ (GB)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                                                if (value == 0) return const Text('Đã dùng', style: TextStyle(fontSize: 10));
                                                if (value == 1) return const Text('Trống', style: TextStyle(fontSize: 10));
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

                // Quick actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Truy cập nhanh',
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
                                label: 'Bản ghi',
                                sublabel: 'Xem & quản lý',
                                color: AppColors.danger,
                                onTap: cameras.isEmpty
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) => RecordingListScreen(
                                                  cameraId: cameras.first.id)),
                                        ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.folder_rounded,
                                label: 'Nhóm',
                                sublabel: 'Quản lý nhóm',
                                color: AppColors.info,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const GroupsScreen()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Groups with camera count
                if (groups.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Camera theo nhóm',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const GroupsScreen()),
                            ),
                            child: const Text('Quản lý →',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final group = groups[i];
                        final cams = CameraStore.instance.camerasInGroup(group.id);
                        final onlineCams = cams.where((c) => c.online).length;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.folder_rounded,
                                      color: AppColors.info, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(group.name,
                                          style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary)),
                                      const SizedBox(height: 3),
                                      // mini progress bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: cams.isEmpty
                                              ? 0
                                              : onlineCams / cams.length,
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
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${cams.length}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary)),
                                    Text('$onlineCams online',
                                        style: TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.success)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: groups.length,
                    ),
                  ),
                ],

                // Ungrouped cameras
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: () {
                      final ungrouped = cameras
                          .where((c) => c.groupIds.isEmpty)
                          .toList();
                      if (ungrouped.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chưa phân nhóm',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          ...ungrouped.map((c) => _CameraRow(camera: c)),
                        ],
                      );
                    }(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
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
              style: const TextStyle(
                  fontSize: 10.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _CameraStatusBar extends StatelessWidget {
  final List cameras;

  const _CameraStatusBar({required this.cameras});

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) return const SizedBox.shrink();
    final online = cameras.where((c) => c.online).length;
    final pct = online / cameras.length;

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
          Row(
            children: [
              const Text('Trạng thái camera',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text('${(pct * 100).toStringAsFixed(0)}% online',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              color: AppColors.success,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Dot(color: AppColors.success),
              const SizedBox(width: 4),
              Text('$online online',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 14),
              _Dot(color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${cameras.length - online} offline',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
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
                    style: const TextStyle(
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
                style: const TextStyle(
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
