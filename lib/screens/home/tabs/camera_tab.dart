import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../data/app_state.dart';

import '../../../data/camera_store.dart';
import '../../../data/video_preload_cache.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/camera_navigation.dart';
import '../../../widgets/notification_bell_button.dart';

class CameraTab extends StatefulWidget {
  const CameraTab({super.key});

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> {
  bool _isGridView = true;
  String? _selectedGroupId; // null = All

  Future<void> _handleRefresh() async {
    await CameraStore.instance.fetchCameras();
    await CameraStore.instance.fetchGroups();
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
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  ListenableBuilder(
                    listenable: CameraStore.instance.listAndStatus,
                    builder: (context, _) {
                      final all = CameraStore.instance.cameras;
                      return _Header(
                        total: all.length,
                        online: CameraStore.instance.onlineCount,
                        isGridView: _isGridView,
                        onToggleView: () =>
                            setState(() => _isGridView = !_isGridView),
                      );
                    },
                  ),
                  ListenableBuilder(
                    listenable: CameraStore.instance,
                    builder: (context, _) {
                      final groups = CameraStore.instance.groups;
                      if (groups.isEmpty) return const SizedBox.shrink();
                      return SizedBox(
                        height: 36,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          scrollDirection: Axis.horizontal,
                          children: [
                            _GroupChip(
                              label: 'Tất cả',
                              selected: _selectedGroupId == null,
                              onTap: () =>
                                  setState(() => _selectedGroupId = null),
                            ),
                            ...groups.map((g) => _GroupChip(
                                  label: g.name,
                                  selected: _selectedGroupId == g.id,
                                  onTap: () => setState(() => _selectedGroupId =
                                      _selectedGroupId == g.id ? null : g.id),
                                )),
                          ],
                        ),
                      );
                    },
                  ),
                ],
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
                child: ListenableBuilder(
                  listenable: CameraStore.instance,
                  builder: (context, _) {
                    final allCameras = CameraStore.instance.cameras;
                    final cameras = _selectedGroupId == null
                        ? allCameras
                        : allCameras
                            .where((c) => c.groupIds.contains(_selectedGroupId))
                            .toList();
                    if (cameras.isEmpty) return const _EmptyState();
                    return _isGridView
                        ? _CameraGrid(cameras: cameras)
                        : _CameraList(cameras: cameras);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GroupChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
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
          const NotificationBellButton(),
          const SizedBox(width: 10),
          _SquareIconButton(
            icon: isGridView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
            onTap: onToggleView,
          ),
        ],
      ),
    );
  }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Phone portrait stays at the current 2 columns; wider layouts
        // (phone landscape, tablets) pick up extra columns instead of
        // stretching 2 fixed tiles across the whole width, matching the
        // multi-screen wall look on bigger screens.
        final crossAxisCount =
            (constraints.maxWidth / 190).floor().clamp(2, 5);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: cameras.length,
          itemBuilder: (context, index) => _CameraGridCard(
            key: ValueKey(cameras[index].id),
            camera: cameras[index],
          ),
        );
      },
    );
  }
}

class _CameraGridCard extends StatelessWidget {
  final Camera camera;

  const _CameraGridCard({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openCameraDetail(context, camera.id),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ListenableBuilder(
                listenable: CameraStore.instance.cameraListenable(camera.id),
                builder: (_, __) {
                  final online = CameraStore.instance.cameraById(camera.id)?.online ?? camera.online;
                  if (!online) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(gradient: AppColors.mediaPlaceholderGradient),
                        ),
                        const Center(
                          child: Icon(
                            Icons.videocam_off_rounded,
                            color: Colors.white70,
                            size: 34,
                          ),
                        ),
                      ],
                    );
                  }
                  return _VideoThumbnail(
                    key: ValueKey('cam-thumb-${camera.id}'),
                    cameraId: camera.id,
                    hlsUrl: camera.hlsUrl ?? '',
                    activeTabIndex: 1,
                  );
                },
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  camera.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: ListenableBuilder(
                  listenable: CameraStore.instance.cameraListenable(camera.id),
                  builder: (_, __) {
                    final online = CameraStore.instance
                            .cameraById(camera.id)
                            ?.online ??
                        camera.online;
                    return _StatusBadge(online: online);
                  },
                ),
              ),
              ListenableBuilder(
                listenable: CameraStore.instance.cameraListenable(camera.id),
                builder: (_, __) {
                  final recording = CameraStore.instance
                          .cameraById(camera.id)
                          ?.recording ??
                      camera.recording;
                  if (!recording) return const SizedBox.shrink();
                  return const Positioned(
                      top: 8, right: 8, child: _RecordingDot());
                },
              ),
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
      itemBuilder: (context, index) => _CameraListTile(
        key: ValueKey('list-${cameras[index].id}'),
        camera: cameras[index],
      ),
    );
  }
}

class _CameraListTile extends StatelessWidget {
  final Camera camera;

  const _CameraListTile({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    final groupNames = camera.groupIds
        .map((id) => CameraStore.instance.groupById(id)?.name)
        .where((name) => name != null)
        .join(', ');
    final displayGroupName = groupNames.isNotEmpty ? groupNames : 'Chưa phân nhóm';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openCameraDetail(context, camera.id),
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
                      Positioned.fill(
                        child: ListenableBuilder(
                          listenable: CameraStore.instance.cameraListenable(camera.id),
                          builder: (_, __) {
                            final online = CameraStore.instance.cameraById(camera.id)?.online ?? camera.online;
                            if (!online) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  const DecoratedBox(
                                    decoration: BoxDecoration(gradient: AppColors.mediaPlaceholderGradient),
                                  ),
                                  const Center(
                                    child: Icon(
                                      Icons.videocam_off_rounded,
                                      color: Colors.white70,
                                      size: 34,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return _VideoThumbnail(
                              key: ValueKey('list-thumb-${camera.id}'),
                              cameraId: camera.id,
                              hlsUrl: camera.hlsUrl ?? '',
                              activeTabIndex: 1,
                            );
                          },
                        ),
                      ),
                      ListenableBuilder(
                        listenable:
                            CameraStore.instance.cameraListenable(camera.id),
                        builder: (_, __) {
                          final recording = CameraStore.instance
                                  .cameraById(camera.id)
                                  ?.recording ??
                              camera.recording;
                          if (!recording) return const SizedBox.shrink();
                          return const Positioned(
                            top: 5,
                            right: 5,
                            child: _RecordingDot(size: 7),
                          );
                        },
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
                            displayGroupName,
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
                        ListenableBuilder(
                          listenable: CameraStore.instance
                              .cameraListenable(camera.id),
                          builder: (_, __) {
                            final online = CameraStore.instance
                                    .cameraById(camera.id)
                                    ?.online ??
                                camera.online;
                            return _StatusBadge(online: online);
                          },
                        ),
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
        color: (online ? AppColors.danger : Colors.black).withOpacity(0.85,
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

class _VideoThumbnail extends StatefulWidget {
  final String cameraId;
  final String hlsUrl;
  final int activeTabIndex;

  const _VideoThumbnail({
    super.key,
    required this.cameraId,
    required this.hlsUrl,
    required this.activeTabIndex,
  });

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  bool _isVisible = false;

  bool get _shouldPlay => AppState.videoAllowedForTab(widget.activeTabIndex) && _isVisible;

  void _onVisibilityChanged(VisibilityInfo info) {
    final visible = info.visibleFraction > 0.1;
    if (_isVisible != visible) {
      _isVisible = visible;
      _onPlaybackGateChange();
    }
  }

  @override
  void initState() {
    super.initState();
    AppState.isVideoGridActive.addListener(_onPlaybackGateChange);
    AppState.homeTabIndex.addListener(_onPlaybackGateChange);
    if (_shouldPlay) _attach();
  }

  @override
  void didUpdateWidget(covariant _VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hlsUrl != widget.hlsUrl ||
        oldWidget.cameraId != widget.cameraId) {
      _detach();
      if (oldWidget.hlsUrl != widget.hlsUrl) {
        VideoPreloadCache.instance.invalidate(oldWidget.cameraId);
      }
      if (_shouldPlay) _attach();
    }
  }

  void _onPlaybackGateChange() {
    if (_shouldPlay) {
      _attach();
    } else {
      _detach();
    }
  }

  Future<void> _attach() async {
    if (!_shouldPlay || widget.hlsUrl.isEmpty) return;
    _hasError = false;

    final cache = VideoPreloadCache.instance;
    var ctrl = cache.peek(widget.cameraId);
    ctrl ??= await cache.warm(widget.cameraId, widget.hlsUrl);
    if (!mounted || !_shouldPlay) return;

    if (ctrl != null && ctrl.value.isInitialized) {
      setState(() {
        _controller = ctrl;
        _hasError = false;
      });
    } else if (mounted) {
      setState(() => _hasError = true);
    }
  }

  void _detach() {
    _controller = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppState.isVideoGridActive.removeListener(_onPlaybackGateChange);
    AppState.homeTabIndex.removeListener(_onPlaybackGateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_controller != null && _controller!.value.isInitialized) {
      content = SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.mediaPlaceholderGradient),
          ),
          Center(
            child: _hasError
                ? const Icon(Icons.error_outline, color: AppColors.danger, size: 34)
                : const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  ),
          ),
        ],
      );
    }

    return VisibilityDetector(
      key: Key('visibility-cam-${widget.cameraId}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: content,
    );
  }
}
