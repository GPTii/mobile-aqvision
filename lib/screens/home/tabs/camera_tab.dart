import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../camera_detail_screen.dart';

enum _CameraFilter { all, online, offline }

class _Camera {
  final String name;
  final String location;
  final bool online;
  final String resolution;
  final bool recording;

  const _Camera(
    this.name,
    this.location,
    this.online,
    this.resolution,
    this.recording,
  );
}

const _cameras = [
  _Camera('Cổng chính', 'Tầng 1 · Lối vào', true, '1080p', true),
  _Camera('Bãi đỗ xe', 'Khu vực ngoài trời', true, '4K', true),
  _Camera('Kho hàng', 'Tầng hầm B1', false, '1080p', false),
  _Camera('Hành lang T2', 'Tầng 2 · Khu văn phòng', true, '1080p', true),
  _Camera('Quầy lễ tân', 'Tầng 1 · Sảnh chính', true, '4K', true),
  _Camera('Phòng server', 'Tầng 3 · Khu kỹ thuật', true, '1080p', true),
  _Camera('Cửa sau', 'Tầng 1 · Lối thoát hiểm', false, '720p', false),
  _Camera('Sân thượng', 'Tầng mái', true, '1080p', false),
];

class CameraTab extends StatefulWidget {
  const CameraTab({super.key});

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> {
  final _searchController = TextEditingController();
  String _query = '';
  _CameraFilter _filter = _CameraFilter.all;
  bool _isGridView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Camera> get _filtered {
    return _cameras.where((cam) {
      final matchesQuery =
          _query.isEmpty ||
          cam.name.toLowerCase().contains(_query.toLowerCase()) ||
          cam.location.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = switch (_filter) {
        _CameraFilter.all => true,
        _CameraFilter.online => cam.online,
        _CameraFilter.offline => !cam.online,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 900));
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = _cameras.where((c) => c.online).length;
    final results = _filtered;

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
            child: SafeArea(
              bottom: false,
              child: _Header(
                total: _cameras.length,
                online: onlineCount,
                isGridView: _isGridView,
                onToggleView: () => setState(() => _isGridView = !_isGridView),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  _SearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  _FilterChipsRow(
                    filter: _filter,
                    total: _cameras.length,
                    online: onlineCount,
                    offline: _cameras.length - onlineCount,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppColors.accent,
                      backgroundColor: AppColors.card,
                      child: results.isEmpty
                          ? _EmptyState(query: _query)
                          : _isGridView
                          ? _CameraGrid(cameras: results)
                          : _CameraList(cameras: results),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int total;
  final int online;
  final bool isGridView;
  final VoidCallback onToggleView;

  const _Header({
    required this.total,
    required this.online,
    required this.isGridView,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Camera',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total thiết bị · $online đang hoạt động',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _SquareIconButton(
            icon: isGridView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
            onTap: onToggleView,
          ),
          const SizedBox(width: 10),
          _SquareIconButton(
            icon: Icons.add_rounded,
            onTap: () {},
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: filled ? AppColors.accentGradient : null,
            color: filled ? null : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: filled ? null : Border.all(color: AppColors.divider),
          ),
          child: Icon(
            icon,
            size: 21,
            color: filled ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          hintText: 'Tìm camera theo tên hoặc vị trí',
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 21,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  final _CameraFilter filter;
  final int total;
  final int online;
  final int offline;
  final ValueChanged<_CameraFilter> onChanged;

  const _FilterChipsRow({
    required this.filter,
    required this.total,
    required this.online,
    required this.offline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (_CameraFilter.all, 'Tất cả', total),
      (_CameraFilter.online, 'Đang hoạt động', online),
      (_CameraFilter.offline, 'Mất kết nối', offline),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label, count) in options) ...[
            _FilterChip(
              label: '$label · $count',
              selected: filter == value,
              onTap: () => onChanged(value),
            ),
            if (value != options.last.$1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.accentGradient : null,
            color: selected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraGrid extends StatelessWidget {
  final List<_Camera> cameras;

  const _CameraGrid({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: cameras.length,
      itemBuilder: (context, index) => _CameraGridCard(camera: cameras[index]),
    );
  }
}

class _CameraGridCard extends StatelessWidget {
  final _Camera camera;

  const _CameraGridCard({required this.camera});

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraDetailScreen(
          name: camera.name,
          location: camera.location,
          online: camera.online,
          resolution: camera.resolution,
          recording: camera.recording,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetail(context),
        child: Container(
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
                      child: _StatusBadge(online: camera.online),
                    ),
                    if (camera.recording)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: _RecordingDot(),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.high_quality_outlined,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            camera.resolution,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

class _CameraList extends StatelessWidget {
  final List<_Camera> cameras;

  const _CameraList({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: cameras.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _CameraListTile(camera: cameras[index]),
    );
  }
}

class _CameraListTile extends StatelessWidget {
  final _Camera camera;

  const _CameraListTile({required this.camera});

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraDetailScreen(
          name: camera.name,
          location: camera.location,
          online: camera.online,
          resolution: camera.resolution,
          recording: camera.recording,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(context),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 68,
                  height: 68,
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
                          size: 26,
                        ),
                      ),
                      if (camera.recording)
                        const Positioned(
                          top: 5,
                          right: 5,
                          child: _RecordingDot(size: 7),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      camera.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 12.5,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            camera.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusBadge(online: camera.online),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.high_quality_outlined,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            camera.resolution,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool online;

  const _StatusBadge({required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (online ? AppColors.danger : Colors.black).withValues(
          alpha: 0.85,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (online)
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
            online ? 'LIVE' : 'OFFLINE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingDot extends StatelessWidget {
  final double size;

  const _RecordingDot({this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.danger,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.card,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Icon(
                      Icons.videocam_off_outlined,
                      size: 30,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không tìm thấy camera',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    query.isEmpty
                        ? 'Không có camera nào phù hợp với bộ lọc này.'
                        : 'Không có camera nào khớp với "$query".',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
