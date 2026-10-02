import '../../../utils/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../data/app_state.dart';

import '../../../data/camera_store.dart';
import '../../../data/gateway_session_store.dart';
import '../../../data/video_preload_cache.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_ui.dart';
import '../../../widgets/camera_navigation.dart';
import '../../../widgets/gateway_picker.dart';
import '../../../widgets/notification_bell_button.dart';
import '../../setup/camera_scan_screen.dart';
import '../../setup/qr_scanner_screen.dart';

/// Camera-tab home filter: null = "Tất cả" (default). Picking a home also
/// makes it the working gateway (used by "+ → Quét camera").
final ValueNotifier<String?> cameraTabFilter = ValueNotifier(null);

class CameraTab extends StatefulWidget {
  const CameraTab({super.key});

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> {
  bool _isGridView = true;
  String? _selectedGroupId; // null = All
  final ScrollController _groupScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    GatewaySessionStore.instance.loadSaved();
  }

  @override
  void dispose() {
    _groupScrollController.dispose();
    super.dispose();
  }

  void _scrollToGroup(String? groupId, List<CameraGroup> groups) {
    if (!_groupScrollController.hasClients) return;
    if (groupId == null) {
      _groupScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final targetOffset = (index + 1) * 95.0 - 60.0;
      final maxScroll = _groupScrollController.position.maxScrollExtent;
      _groupScrollController.animateTo(
        targetOffset.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Cameras of the home picked in the header (see
  /// [GatewaySessionStore.homeIncludesCamera]).
  List<Camera> _homeCameras() {
    return CameraStore.instance.cameras
        .where((c) => GatewaySessionStore.homeIncludesCamera(cameraTabFilter.value, c.cameraCode))
        .toList();
  }

  /// Group chips for the current home: with "Tất cả" every group (empty ones
  /// too, so cameras can be added); otherwise only groups that hold at least
  /// one of this home's cameras.
  List<CameraGroup> _visibleGroups(List<Camera> homeCameras) {
    final groups = CameraStore.instance.groups;
    if (cameraTabFilter.value == null) return groups;
    final used = {for (final c in homeCameras) ...c.groupIds};
    return groups.where((g) => used.contains(g.id)).toList();
  }

  /// [_selectedGroupId], unless the home switch hid that group.
  String? _effectiveGroupId(List<Camera> homeCameras) {
    final id = _selectedGroupId;
    if (id == null) return null;
    return _visibleGroups(homeCameras).any((g) => g.id == id) ? id : null;
  }

  Future<void> _handleRefresh() async {
    await CameraStore.instance.fetchCameras();
    await CameraStore.instance.fetchGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: Column(
          children: [
            DecoratedBox(
              // Header sits directly on the page gradient.
              decoration: const BoxDecoration(),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    ListenableBuilder(
                      listenable: Listenable.merge([
                        CameraStore.instance.listAndStatus,
                        GatewaySessionStore.instance,
                        cameraTabFilter,
                      ]),
                      builder: (context, _) {
                        final all = _homeCameras();
                        return _Header(
                          total: all.length,
                          online: all.where((c) => c.online).length,
                          isGridView: _isGridView,
                          onToggleView: () => setState(() => _isGridView = !_isGridView),
                        );
                      },
                    ),
                    ListenableBuilder(
                      listenable: Listenable.merge([
                        CameraStore.instance,
                        GatewaySessionStore.instance,
                        cameraTabFilter,
                      ]),
                      builder: (context, _) {
                        final homeCameras = _homeCameras();
                        final groups = _visibleGroups(homeCameras);
                        final selectedGroupId = _effectiveGroupId(homeCameras);
                        if (groups.isEmpty) return const SizedBox.shrink();
                        return SizedBox(
                          height: 38,
                          child: Row(
                            children: [
                              Expanded(
                                child: ListView(
                                  controller: _groupScrollController,
                                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _GroupChip(
                                      label: 'Tất cả'.tr,
                                      selected: selectedGroupId == null,
                                      onTap: () {
                                        setState(() => _selectedGroupId = null);
                                        _scrollToGroup(null, groups);
                                      },
                                    ),
                                    ...groups.map((g) => _GroupChip(
                                          label: g.displayName,
                                          selected: selectedGroupId == g.id,
                                          onTap: () {
                                            final next = selectedGroupId == g.id ? null : g.id;
                                            setState(() => _selectedGroupId = next);
                                            _scrollToGroup(next, groups);
                                          },
                                        )),
                                  ],
                                ),
                              ),
                              _GroupDropdownButton(
                                groups: groups,
                                homeCameras: homeCameras,
                                selectedGroupId: selectedGroupId,
                                onSelected: (id) {
                                  setState(() => _selectedGroupId = id);
                                  _scrollToGroup(id, groups);
                                },
                              ),
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
                    listenable: Listenable.merge([
                      CameraStore.instance,
                      GatewaySessionStore.instance,
                      cameraTabFilter,
                    ]),
                    builder: (context, _) {
                      final allCameras = _homeCameras();
                      final groupId = _effectiveGroupId(allCameras);
                      final cameras =
                          groupId == null ? allCameras : allCameras.where((c) => c.groupIds.contains(groupId)).toList();
                      if (cameras.isEmpty) return const _EmptyState();
                      return _isGridView ? _CameraGrid(cameras: cameras) : _CameraList(cameras: cameras);
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

class _GroupChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GroupChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: selected ? Border(bottom: BorderSide(color: AppColors.textPrimary, width: 2)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _GroupDropdownButton extends StatelessWidget {
  final List<CameraGroup> groups;
  final List<Camera> homeCameras;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelected;

  const _GroupDropdownButton({
    required this.groups,
    required this.homeCameras,
    required this.selectedGroupId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isCustomGroup = selectedGroupId != null;
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 6),
      child: Theme(
        data: Theme.of(context).copyWith(
          popupMenuTheme: PopupMenuThemeData(
            color: AppColors.card,
            elevation: 10,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.divider.withValues(alpha: 0.7), width: 1),
            ),
          ),
        ),
        child: PopupMenuButton<String?>(
          tooltip: 'Danh sách phòng'.tr,
          offset: const Offset(0, 36),
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
          onSelected: onSelected,
          itemBuilder: (context) {
            return [
              PopupMenuItem<String?>(
                enabled: false,
                height: 32,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DANH SÁCH PHÒNG'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.divider.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${groups.length}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(height: 6),
              PopupMenuItem<String?>(
                value: null,
                height: 42,
                child: Row(
                  children: [
                    Icon(
                      selectedGroupId == null ? Icons.check_circle_rounded : Icons.apps_rounded,
                      size: 18,
                      color: selectedGroupId == null ? AppColors.accent : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tất cả'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selectedGroupId == null ? FontWeight.w700 : FontWeight.w500,
                          color: selectedGroupId == null ? AppColors.accent : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: selectedGroupId == null
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${homeCameras.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selectedGroupId == null ? AppColors.accent : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...groups.map((g) {
                final isSelected = selectedGroupId == g.id;
                final count = homeCameras.where((c) => c.groupIds.contains(g.id)).length;
                return PopupMenuItem<String?>(
                  value: g.id,
                  height: 42,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.meeting_room_outlined,
                        size: 18,
                        color: isSelected ? AppColors.accent : AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          g.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.accent : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.accent : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ];
          },
          child: Container(
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: isCustomGroup ? AppColors.accent.withValues(alpha: 0.12) : AppColors.card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isCustomGroup ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: isCustomGroup ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
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

  void _showAddSheet(BuildContext context) {
    void open(Widget screen) {
      Navigator.pop(context);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.qr_code_scanner_outlined, color: AppColors.accent),
                title: Text('Thêm thiết bị mới'.tr,
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('Quét mã QR để cài đặt Gateway Eyerus'.tr,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () => open(const QrScannerScreen()),
              ),
              ListTile(
                leading: Icon(Icons.radar, color: AppColors.info),
                title:
                    Text('Quét camera'.tr, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('Tìm và thêm camera qua Gateway trong mạng'.tr,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () => open(const CameraScanScreen()),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: GatewayPicker(filter: cameraTabFilter, selectsGateway: true),
            ),
          ),
          const NotificationBellButton(),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showAddSheet(context),
            child: Icon(Icons.add, color: AppColors.textPrimary, size: 28),
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
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, size: 26, color: AppColors.textPrimary),
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
        final crossAxisCount = (constraints.maxWidth / 190).floor().clamp(2, 5);

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
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        onTap: () => openCameraDetail(context, camera.id),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
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
                        DecoratedBox(
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
                    final online = CameraStore.instance.cameraById(camera.id)?.online ?? camera.online;
                    return _StatusBadge(online: online);
                  },
                ),
              ),
              ListenableBuilder(
                listenable: CameraStore.instance.cameraListenable(camera.id),
                builder: (_, __) {
                  final recording = CameraStore.instance.cameraById(camera.id)?.recording ?? camera.recording;
                  if (!recording) return const SizedBox.shrink();
                  return const Positioned(top: 8, right: 8, child: _RecordingDot());
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
        .map((id) => CameraStore.instance.groupById(id)?.displayName)
        .where((name) => name != null)
        .join(', ');
    final displayGroupName = groupNames.isNotEmpty ? groupNames : 'Chưa phân nhóm'.tr;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        onTap: () => openCameraDetail(context, camera.id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
                                  DecoratedBox(
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
                        listenable: CameraStore.instance.cameraListenable(camera.id),
                        builder: (_, __) {
                          final recording = CameraStore.instance.cameraById(camera.id)?.recording ?? camera.recording;
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
                      style: TextStyle(
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
                          listenable: CameraStore.instance.cameraListenable(camera.id),
                          builder: (_, __) {
                            final online = CameraStore.instance.cameraById(camera.id)?.online ?? camera.online;
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
        color: (online ? AppColors.danger : Colors.black).withOpacity(
          0.85,
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
                    ),
                    child: Icon(
                      Icons.videocam_off_outlined,
                      size: 30,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có camera nào'.tr,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nhấn nút + phía trên để thêm camera đầu tiên.'.tr,
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
          DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.mediaPlaceholderGradient),
          ),
          Center(
            child: _hasError
                ? IconButton(
                    icon: Icon(Icons.refresh_rounded, color: AppColors.danger, size: 34),
                    onPressed: _attach,
                  )
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
