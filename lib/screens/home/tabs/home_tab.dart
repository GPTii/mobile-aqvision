import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../camera_detail_screen.dart';
import '../record_list_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 900));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.headerBackground,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(bottom: false, child: _Header()),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.accent,
                backgroundColor: AppColors.card,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _StatsGrid()),
                    SliverToBoxAdapter(child: _LiveCamerasSection()),
                    SliverToBoxAdapter(child: _QuickActionsSection()),
                    SliverToBoxAdapter(child: _RecentAlertsSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.accentGradient,
            ),
            alignment: Alignment.center,
            child: const Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, Admin 👋',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'RapidMedia Dashboard',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _IconBadgeButton(
            icon: Icons.notifications_rounded,
            badgeCount: 3,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _IconBadgeButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _IconBadgeButton({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  icon,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.card, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
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

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatsGrid extends StatelessWidget {
  static const _stats = [
    _StatItem('Tổng camera', '24', Icons.videocam_rounded, AppColors.accent),
    _StatItem(
      'Đang hoạt động',
      '21',
      Icons.check_circle_rounded,
      AppColors.success,
    ),
    _StatItem('Mất kết nối', '2', Icons.wifi_off_rounded, AppColors.danger),
    _StatItem(
      'Cảnh báo hôm nay',
      '3',
      Icons.warning_rounded,
      AppColors.warning,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(stat: _stats[0])),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(stat: _stats[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(stat: _stats[2])),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(stat: _stats[3])),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(stat.icon, size: 16, color: stat.color),
          ),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreview {
  final String name;
  final String location;
  final bool online;

  const _CameraPreview(this.name, this.location, this.online);
}

class _LiveCamerasSection extends StatelessWidget {
  static const _cameras = [
    _CameraPreview('Cổng chính', 'Tầng 1 · Lối vào', true),
    _CameraPreview('Bãi đỗ xe', 'Khu vực ngoài trời', true),
    _CameraPreview('Kho hàng', 'Tầng hầm B1', false),
    _CameraPreview('Hành lang T2', 'Tầng 2 · Khu văn phòng', true),
    _CameraPreview('Quầy lễ tân', 'Tầng 1 · Sảnh chính', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Camera trực tiếp',
          actionLabel: 'Xem tất cả',
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _cameras.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _CameraCard(camera: _cameras[index]),
          ),
        ),
      ],
    );
  }
}

class _CameraCard extends StatelessWidget {
  final _CameraPreview camera;

  const _CameraCard({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CameraDetailScreen(
              name: camera.name,
              location: camera.location,
              online: camera.online,
            ),
          ),
        ),
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: AppColors.mediaPlaceholderGradient),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.videocam_rounded,
                        color: AppColors.mediaPlaceholderIcon,
                        size: 34,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (camera.online ? AppColors.danger : Colors.black)
                                  .withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (camera.online)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(
                              camera.online ? 'LIVE' : 'OFFLINE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      camera.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      camera.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
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
}

class _QuickAction {
  final String label;
  final IconData icon;
  final void Function(BuildContext context)? onTap;

  const _QuickAction(this.label, this.icon, {this.onTap});
}

class _QuickActionsSection extends StatelessWidget {
  static final _actions = [
    const _QuickAction('Thêm camera', Icons.add_circle_outline_rounded),
    const _QuickAction('Xem bản đồ', Icons.map_outlined),
    _QuickAction(
      'Lịch sử',
      Icons.history_rounded,
      onTap: (context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RecordListScreen()),
      ),
    ),
    const _QuickAction('Cài đặt', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Truy cập nhanh'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: _actions
                .map(
                  (a) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: a == _actions.last ? 0 : 10,
                      ),
                      child: _QuickActionButton(action: a),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap == null ? null : () => action.onTap!(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(action.icon, color: AppColors.accent, size: 20),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Severity { danger, warning, info }

class _AlertItem {
  final String title;
  final String source;
  final String time;
  final _Severity severity;

  const _AlertItem(this.title, this.source, this.time, this.severity);
}

class _RecentAlertsSection extends StatelessWidget {
  static const _alerts = [
    _AlertItem(
      'Phát hiện chuyển động bất thường',
      'Cổng chính',
      '5 phút trước',
      _Severity.danger,
    ),
    _AlertItem(
      'Camera mất kết nối',
      'Kho hàng',
      '22 phút trước',
      _Severity.warning,
    ),
    _AlertItem(
      'Cập nhật firmware thành công',
      'Hệ thống',
      '1 giờ trước',
      _Severity.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Cảnh báo gần đây',
          actionLabel: 'Xem tất cả',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: List.generate(_alerts.length, (i) {
                final alert = _alerts[i];
                return Column(
                  children: [
                    _AlertTile(alert: alert),
                    if (i != _alerts.length - 1)
                      Divider(
                        height: 1,
                        color: AppColors.divider,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final _AlertItem alert;

  const _AlertTile({required this.alert});

  Color get _color {
    switch (alert.severity) {
      case _Severity.danger:
        return AppColors.danger;
      case _Severity.warning:
        return AppColors.warning;
      case _Severity.info:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (alert.severity) {
      case _Severity.danger:
        return Icons.error_rounded;
      case _Severity.warning:
        return Icons.wifi_off_rounded;
      case _Severity.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 18, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.source} · ${alert.time}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;

  const _SectionHeader({required this.title, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null)
            InkWell(
              onTap: () {},
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
