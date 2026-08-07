import 'package:flutter/material.dart';

import '../../../data/camera_store.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/camera_form_sheet.dart';
import '../../../widgets/notification_bell_button.dart';
import '../../../widgets/prompt_dialog.dart';
import '../camera_detail_screen.dart';

class CameraTab extends StatefulWidget {
  const CameraTab({super.key});

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> {
  bool _isGridView = true;

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 900));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CameraStore.instance,
      builder: (context, _) {
        final cameras = CameraStore.instance.cameras;
        final onlineCount = cameras.where((c) => c.online).length;

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
                    total: cameras.length,
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
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.accent,
                    backgroundColor: AppColors.card,
                    child: cameras.isEmpty
                        ? const _EmptyState()
                        : _isGridView
                        ? _CameraGrid(cameras: cameras)
                        : _CameraList(cameras: cameras),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          const NotificationBellButton(),
          const SizedBox(width: 10),
          _SquareIconButton(
            icon: isGridView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
            onTap: onToggleView,
          ),
          const SizedBox(width: 10),
          _AddMenuButton(),
        ],
      ),
    );
  }
}

class _AddMenuButton extends StatelessWidget {
  const _AddMenuButton();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case 'camera':
            showCameraFormSheet(context);
          case 'group':
            _promptAddGroup(context);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'camera', child: Text('Thêm camera')),
        PopupMenuItem(value: 'group', child: Text('Thêm nhóm camera')),
      ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.add_rounded, size: 21, color: Colors.white),
      ),
    );
  }
}

Future<void> _promptAddGroup(BuildContext context) async {
  final name = await showTextPromptDialog(
    context,
    title: 'Thêm nhóm camera',
    hint: 'VD: Phòng ngủ',
    confirmLabel: 'Thêm',
  );
  if (name != null) CameraStore.instance.addGroup(name);
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareIconButton({required this.icon, required this.onTap});

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
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(icon, size: 21, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _CameraGrid extends StatelessWidget {
  final List<Camera> cameras;

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
        childAspectRatio: 1.3,
      ),
      itemCount: cameras.length,
      itemBuilder: (context, index) => _CameraGridCard(camera: cameras[index]),
    );
  }
}

class _CameraGridCard extends StatelessWidget {
  final Camera camera;

  const _CameraGridCard({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CameraDetailScreen(cameraId: camera.id),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.mediaPlaceholderGradient),
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
                const Positioned(top: 8, right: 8, child: _RecordingDot()),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraList extends StatelessWidget {
  final List<Camera> cameras;

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
  final Camera camera;

  const _CameraListTile({required this.camera});

  @override
  Widget build(BuildContext context) {
    final groupName = CameraStore.instance.groupById(camera.groupId)?.name ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CameraDetailScreen(cameraId: camera.id),
          ),
        ),
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
                            groupName,
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
  const _EmptyState();

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
                    'Chưa có camera nào',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nhấn nút + phía trên để thêm camera đầu tiên.',
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
