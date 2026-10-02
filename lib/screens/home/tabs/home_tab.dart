import '../../../utils/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../data/app_state.dart';

import '../../../data/camera_store.dart';
import '../../../data/hidden_cameras_store.dart';
import '../../../data/video_preload_cache.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_ui.dart';
import '../../../widgets/camera_selection_sheet.dart';
import '../../../widgets/camera_navigation.dart';
import '../../../data/gateway_session_store.dart';
import '../../../widgets/gateway_picker.dart';
import '../../../widgets/news_button.dart';
import '../../../widgets/notification_bell_button.dart';
import '../../../widgets/prompt_dialog.dart';
import '../../../widgets/weather_time_header.dart';

/// Home-tab camera filter picked in the header: null = "Tất cả" (default).
/// Independent of the gateway selected on the Camera tab.
final ValueNotifier<String?> homeCameraFilter = ValueNotifier(null);

bool _inGatewayFilter(Camera c) => GatewaySessionStore.homeIncludesCamera(homeCameraFilter.value, c.cameraCode);

/// Shown on Home: in the picked gateway and not hidden by the user.
bool _inHomeFilter(Camera c) => _inGatewayFilter(c) && !HiddenCamerasStore.instance.isHidden(c.id);

/// Cameras the user hid that would otherwise show under the current filter.
List<Camera> _hiddenCameras() => CameraStore.instance.cameras
    .where((c) => _inGatewayFilter(c) && HiddenCamerasStore.instance.isHidden(c.id))
    .toList();

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
      body: AppBackground(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GatewayPicker(fontSize: 24, filter: homeCameraFilter),
                          SizedBox(height: 4),
                          WeatherTimeHeader(),
                        ],
                      ),
                    ),
                    const NewsButton(),
                    const NotificationBellButton(),
                  ],
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
                    listenable: Listenable.merge([
                      CameraStore.instance,
                      GatewaySessionStore.instance,
                      homeCameraFilter,
                      HiddenCamerasStore.instance,
                    ]),
                    builder: (context, _) {
                      // Filtered to one home: hide groups with none of its cameras.
                      // "Tất cả" keeps empty groups so cameras can be added to them.
                      final groups = homeCameraFilter.value == null
                          ? CameraStore.instance.groups
                          : CameraStore.instance.groups
                              .where((g) => CameraStore.instance.camerasInGroup(g.id).any(_inHomeFilter))
                              .toList();
                      final ungrouped = CameraStore.instance.cameras
                          .where(_inHomeFilter)
                          .where((c) => c.groupIds.every((id) => CameraStore.instance.groupById(id) == null))
                          .toList();
                      final hidden = _hiddenCameras();

                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          SliverList.builder(
                            itemCount: groups.length,
                            itemBuilder: (context, index) => _RoomSection(group: groups[index]),
                          ),
                          if (ungrouped.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _UngroupedSection(cameras: ungrouped),
                            ),
                          if (hidden.isNotEmpty)
                            SliverToBoxAdapter(child: _HiddenCamerasCard(count: hidden.length)),
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
      ),
    );
  }
}

class _RoomSection extends StatelessWidget {
  final CameraGroup group;

  const _RoomSection({required this.group});

  @override
  Widget build(BuildContext context) {
    final inRoom = CameraStore.instance.camerasInGroup(group.id).where(_inGatewayFilter).toList();
    final cameras = inRoom.where(_inHomeFilter).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoomHeader(group: group, cameraCount: cameras.length),
          if (cameras.isNotEmpty)
            _CameraGrid(cameras: cameras, groupId: group.id)
          else if (inRoom.isNotEmpty)
            _AllHiddenHint(count: inRoom.length)
          else
            _EmptyRoomHint(groupId: group.id),
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
          Text(
            'Chưa phân nhóm'.tr,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
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
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$cameraCount ' + 'camera · chưa xếp vào nhóm nào'.tr,
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

  /// Above this available width (phone landscape and up, not just tablets)
  /// we switch each room from "1 hero + small tiles" to a uniform
  /// video-wall grid showing every camera in the group at equal size.
  /// Phone portrait width tops out around 320-400dp available, phone
  /// landscape starts around 600dp — this sits between the two.
  static const _wallBreakpoint = 560.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= _wallBreakpoint) {
            return _CameraWallGrid(
              cameras: cameras,
              groupId: groupId,
              maxWidth: constraints.maxWidth,
            );
          }

          // Phone portrait keeps the current "1 hero + 2 small" look
          // unchanged. Phone landscape fits more small tiles in the row
          // instead of stretching just 2 of them — same responsive idea
          // as the Camera tab's grid, applied to this tab's hero-tile
          // layout instead of a uniform grid.
          final extraCount = (constraints.maxWidth / 150).floor().clamp(2, 4);
          final extras = cameras.skip(1).take(extraCount).toList();
          final overflowCount = cameras.length - (1 + extraCount);

          return Column(
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
                  children: [
                    for (var index = 0; index < extras.length; index++) ...[
                      // Gap between tiles, not padding inside one — keeps all tiles the same size.
                      if (index > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _CameraTile(
                          key: ValueKey(extras[index].id),
                          camera: extras[index],
                          groupId: groupId,
                          aspectRatio: 1.3,
                          overflowCount: index == extras.length - 1 && overflowCount > 0 ? overflowCount : 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Tablet layout: every camera in the room/group at equal size, like a
/// monitoring video wall, instead of one hero tile + small thumbnails.
class _CameraWallGrid extends StatelessWidget {
  final List<Camera> cameras;
  final String groupId;
  final double maxWidth;

  const _CameraWallGrid({
    required this.cameras,
    required this.groupId,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Smaller target tile width than a tablet-only grid would use, so
    // ordinary phone landscape (not just big tablets) already lands on
    // 3-4 columns instead of needing tablet-scale width to densify.
    final crossAxisCount = (maxWidth / 170).floor().clamp(3, 6);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 16 / 10,
      ),
      itemCount: cameras.length,
      itemBuilder: (context, index) => _CameraTile(
        key: ValueKey(cameras[index].id),
        camera: cameras[index],
        groupId: groupId,
        aspectRatio: 16 / 10,
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
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          onTap: () => showCameraSelectionSheet(context, groupId: groupId),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
            ),
            child: Column(
              children: [
                Icon(Icons.add_circle_rounded, size: 30, color: AppColors.accent.withValues(alpha: 0.85)),
                const SizedBox(height: 8),
                Text(
                  'Chưa có camera · Nhấn để thêm'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
              ],
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
      title: 'Đổi tên nhóm'.tr,
      initialValue: group.name,
      hint: 'Tên nhóm camera'.tr,
    );
    if (name != null && name.trim().isNotEmpty && name.trim() != group.name) {
      try {
        await CameraStore.instance.renameGroup(group.id, name.trim());
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ));
        }
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xoá nhóm'.tr + ' "${group.displayName}"?',
      message: 'Toàn bộ camera trong nhóm này'.tr + ' ($cameraCount ' + 'camera'.tr + ') ' + 'sẽ bị xoá theo.'.tr,
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
                  group.displayName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
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
                      decoration: BoxDecoration(
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
            icon: Icon(Icons.more_horiz_rounded, size: 24, color: AppColors.textPrimary),
            onSelected: (value) {
              switch (value) {
                case 'add_existing':
                  showCameraSelectionSheet(context, groupId: group.id);
                case 'rename':
                  _rename(context);
                case 'delete':
                  _delete(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'add_existing', child: Text('Thêm camera có sẵn'.tr)),
              PopupMenuItem(value: 'rename', child: Text('Đổi tên nhóm'.tr)),
              PopupMenuItem(
                value: 'delete',
                child: Text('Xoá nhóm'.tr, style: TextStyle(color: AppColors.danger)),
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
      title: 'Thêm nhóm camera'.tr,
      hint: 'VD: Phòng ngủ'.tr,
      confirmLabel: 'Thêm'.tr,
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
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          onTap: () => _addGroup(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 22, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Thêm nhóm camera'.tr,
                  style: TextStyle(color: AppColors.accent, fontSize: 15, fontWeight: FontWeight.w700),
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
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        onTap: () => openCameraDetail(context, camera.id),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
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
                        listenable: CameraStore.instance.cameraListenable(camera.id),
                        builder: (_, __) {
                          final live = CameraStore.instance.cameraById(camera.id)?.online ?? camera.online;
                          return live ? const _LiveBadge() : const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(width: 4),
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
    if (oldWidget.hlsUrl != widget.hlsUrl || oldWidget.cameraId != widget.cameraId) {
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
        DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.mediaPlaceholderGradient),
        ),
        Center(
          child: _hasError
              ? Icon(Icons.error_outline, color: AppColors.danger, size: 34)
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
        if (value == 'hide') {
          await HiddenCamerasStore.instance.hide(camera.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text('Đã ẩn "{name}" khỏi trang chủ'.trArgs({'name': camera.name})),
              action: SnackBarAction(
                label: 'Hoàn tác'.tr,
                onPressed: () => HiddenCamerasStore.instance.show(camera.id),
              ),
            ));
        } else if (value == 'remove') {
          try {
            final newGroupIds = camera.groupIds.where((id) => id != groupId).toList();
            await CameraStore.instance.updateCamera(camera.id, groupIds: newGroupIds);
          } catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'hide', child: Text('Ẩn khỏi trang chủ'.tr)),
        if (groupId.isNotEmpty && groupId != '0')
          PopupMenuItem(
            value: 'remove',
            child: Text('Xoá khỏi nhóm'.tr, style: TextStyle(color: AppColors.danger)),
          ),
      ],
    );
  }
}

/// Room whose cameras are all hidden — says so instead of "no camera yet".
class _AllHiddenHint extends StatelessWidget {
  final int count;

  const _AllHiddenHint({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          onTap: () => _showHiddenCamerasSheet(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
            ),
            child: Column(
              children: [
                Icon(Icons.visibility_off_rounded, size: 26, color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text(
                  'Đã ẩn {count} camera · Nhấn để hiện lại'.trArgs({'count': count}),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Entry to the hidden cameras list, above "Thêm nhóm camera".
class _HiddenCamerasCard extends StatelessWidget {
  final int count;

  const _HiddenCamerasCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          onTap: () => _showHiddenCamerasSheet(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility_off_rounded, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Camera đã ẩn ({count})'.trArgs({'count': count}),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lists hidden cameras with a "Hiện lại" button each; closes once empty.
void _showHiddenCamerasSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => ListenableBuilder(
      listenable: HiddenCamerasStore.instance,
      builder: (ctx, _) {
        final cameras = _hiddenCameras();
        if (cameras.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ctx.mounted) Navigator.of(ctx).maybePop();
          });
        }
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text('Camera đã ẩn'.tr,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ),
                    TextButton(
                      onPressed: HiddenCamerasStore.instance.showAll,
                      child: Text('Hiện tất cả'.tr, style: TextStyle(color: AppColors.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in cameras)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.videocam_off_rounded, color: AppColors.textMuted),
                          title: Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          trailing: TextButton.icon(
                            onPressed: () => HiddenCamerasStore.instance.show(c.id),
                            icon: Icon(Icons.visibility_rounded, size: 18, color: AppColors.accent),
                            label: Text('Hiện lại'.tr, style: TextStyle(color: AppColors.accent)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
