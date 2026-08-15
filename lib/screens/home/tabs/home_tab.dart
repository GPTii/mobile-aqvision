import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../data/app_state.dart';

import '../../../data/camera_store.dart';
import '../../../data/video_preload_cache.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/camera_selection_sheet.dart';
import '../../../widgets/camera_form_sheet.dart';
import '../../../widgets/camera_navigation.dart';
import '../../../widgets/notification_bell_button.dart';
import '../../../widgets/prompt_dialog.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Future<void> _handleRefresh() async {
    await Future.wait([
      CameraStore.instance.fetchCameras(),
      CameraStore.instance.fetchGroups(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Chrome stays outside the store listener — SSE/status flips don't rebuild headers.
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Trang chủ',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const NotificationBellButton(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.accent,
                backgroundColor: AppColors.card,
                child: ListenableBuilder(
                  listenable: CameraStore.instance,
                  builder: (context, _) {
                    final groups = CameraStore.instance.groups;
                    final ungrouped = CameraStore.instance.cameras
                        .where((c) => c.groupIds.every(
                            (id) => CameraStore.instance.groupById(id) == null))
                        .toList();

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        SliverList.builder(
                          itemCount: groups.length,
                          itemBuilder: (context, index) =>
                              _RoomSection(group: groups[index]),
                        ),
                        if (ungrouped.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _UngroupedSection(cameras: ungrouped),
                          ),
                        const SliverToBoxAdapter(child: _AddRoomCard()),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    );
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

class _RoomSection extends StatelessWidget {
  final CameraGroup group;

  const _RoomSection({required this.group});

  @override
  Widget build(BuildContext context) {
    final cameras = CameraStore.instance.camerasInGroup(group.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoomHeader(group: group, cameraCount: cameras.length),
          if (cameras.isEmpty)
            _EmptyRoomHint(groupId: group.id)
          else
            _CameraGrid(cameras: cameras, groupId: group.id),
        ],
      ),
    );
  }
}

class _UngroupedSection extends StatelessWidget {
  final List<Camera> cameras;

  const _UngroupedSection({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UngroupedHeader(cameraCount: cameras.length),
          _CameraGrid(cameras: cameras, groupId: ''),
        ],
      ),
    );
  }
}

class _UngroupedHeader extends StatelessWidget {
  final int cameraCount;

  const _UngroupedHeader({required this.cameraCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chưa phân nhóm',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$cameraCount camera · chưa xếp vào nhóm nào',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CameraGrid extends StatelessWidget {
  final List<Camera> cameras;
  final String groupId;

  const _CameraGrid({required this.cameras, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final extras = cameras.skip(1).take(2).toList();
    final overflowCount = cameras.length - 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _CameraTile(
            key: ValueKey(cameras.first.id),
            camera: cameras.first,
            groupId: groupId,
            aspectRatio: 16 / 10,
          ),
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: List.generate(extras.length, (index) {
                final isLast = index == extras.length - 1;
                final showOverflow = isLast && overflowCount > 0;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == extras.length - 1 ? 0 : 10,
                    ),
                    child: _CameraTile(
                      key: ValueKey(extras[index].id),
                      camera: extras[index],
                      groupId: groupId,
                      aspectRatio: 1.3,
                      overflowCount: showOverflow ? overflowCount : 0,
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyRoomHint extends StatelessWidget {
  final String groupId;

  const _EmptyRoomHint({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showCameraSelectionSheet(context, groupId: groupId),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Chưa có camera · Nhấn để thêm',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  final CameraGroup group;
  final int cameraCount;

  const _RoomHeader({required this.group, required this.cameraCount});

  Future<void> _rename(BuildContext context) async {
    final name = await showTextPromptDialog(
      context,
      title: 'Đổi tên nhóm',
      initialValue: group.name,
      hint: 'Tên nhóm camera',
    );
    if (name != null) CameraStore.instance.renameGroup(group.id, name);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xoá nhóm "${group.name}"?',
      message: 'Toàn bộ camera trong nhóm này ($cameraCount camera) sẽ bị xoá theo.',
    );
    if (confirmed) {
      try {
        await CameraStore.instance.deleteGroup(group.id);
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$cameraCount Camera',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            icon: Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.textSecondary),
            onSelected: (value) {
              switch (value) {
                case 'add':
                  showCameraFormSheet(context, initialGroupId: group.id);
                case 'add_existing':
                  showCameraSelectionSheet(context, groupId: group.id);
                case 'rename':
                  _rename(context);
                case 'delete':
                  _delete(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'add', child: Text('Thêm camera mới')),
              PopupMenuItem(value: 'add_existing', child: Text('Thêm camera có sẵn')),
              PopupMenuItem(value: 'rename', child: Text('Đổi tên nhóm')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Xoá nhóm', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddRoomCard extends StatelessWidget {
  const _AddRoomCard();

  Future<void> _addGroup(BuildContext context) async {
    final name = await showTextPromptDialog(
      context,
      title: 'Thêm nhóm camera',
      hint: 'VD: Phòng ngủ',
      confirmLabel: 'Thêm',
    );
    if (name != null) {
      try {
        await CameraStore.instance.addGroup(name);
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _addGroup(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 18, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Thêm nhóm camera',
                  style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraTile extends StatelessWidget {
  final Camera camera;
  final String groupId;
  final double aspectRatio;
  final int overflowCount;

  const _CameraTile({
    super.key,
    required this.camera,
    required this.groupId,
    required this.aspectRatio,
    this.overflowCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openCameraDetail(context, camera.id),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: _VideoThumbnail(
                    key: ValueKey('thumb-${camera.id}'),
                    cameraId: camera.id,
                    hlsUrl: camera.hlsUrl ?? '',
                    activeTabIndex: 0,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _Chip(text: camera.name),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListenableBuilder(
                        listenable:
                            CameraStore.instance.cameraListenable(camera.id),
                        builder: (_, __) {
                          final live = CameraStore.instance
                                  .cameraById(camera.id)
                                  ?.online ??
                              camera.online;
                          return live
                              ? const _LiveBadge()
                              : const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(width: 4),
                      if (groupId.isNotEmpty && groupId != '0')
                        _CameraOptionsMenu(camera: camera, groupId: groupId),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0),
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          camera.lastSeen,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (overflowCount > 0)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                      ),
                      child: Center(
                        child: Text(
                          '+$overflowCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 90),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.92),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
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

class _VideoThumbnail extends StatefulWidget {
  final String cameraId;
  final String hlsUrl;
  /// Bottom-nav tab that owns this player (0 = Home, 1 = Camera).
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

  bool get _shouldPlay => AppState.videoAllowedForTab(widget.activeTabIndex);

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
    // Cache owns disposal — only drop the local reference.
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
    if (_controller != null && _controller!.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }
    return Stack(
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
}

class _CameraOptionsMenu extends StatelessWidget {
  final Camera camera;
  final String groupId;
  const _CameraOptionsMenu({required this.camera, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_horiz_rounded, size: 16, color: Colors.white),
      ),
      onSelected: (value) async {
        if (value == 'remove') {
          try {
            final newGroupIds = camera.groupIds.where((id) => id != groupId).toList();
            await CameraStore.instance.updateCamera(camera.id, groupIds: newGroupIds);
          } catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'remove',
          child: Text('Xoá khỏi nhóm', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    );
  }
}
