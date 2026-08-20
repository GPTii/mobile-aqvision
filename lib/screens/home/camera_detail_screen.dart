import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../main.dart' as import_main;

import '../../data/camera_store.dart';
import '../../data/notification_store.dart';
import '../../data/recording_store.dart';
import '../../data/video_preload_cache.dart';
import '../../theme/app_colors.dart';
import '../../widgets/camera_form_sheet.dart';
import '../../widgets/prompt_dialog.dart';
import 'record_list_screen.dart';
import '../../widgets/webrtc_player.dart';




class CameraDetailScreen extends StatefulWidget {
  final String cameraId;

  const CameraDetailScreen({super.key, required this.cameraId});

  @override
  State<CameraDetailScreen> createState() => _CameraDetailScreenState();
}

class _CameraDetailScreenState extends State<CameraDetailScreen> {
  bool _isAlarmArmed = false;
  bool _recordBusy = false;
  bool _useWebRTC = false;

  @override
  void initState() {
    super.initState();
    final camera = CameraStore.instance.cameraById(widget.cameraId);
    if (camera != null) {
      _useWebRTC = camera.playProtocol == 'webrtc';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRecordStatus());
    NotificationStore.instance.fetchAlerts();
  }

  Future<void> _syncRecordStatus() async {
    final camera = CameraStore.instance.cameraById(widget.cameraId);
    if (camera == null) return;
    await RecordingStore.instance.checkRecordStatus(
      cameraId: camera.id,
      app: camera.app ?? 'live',
      stream: camera.cameraCode,
    );
  }

  Future<void> _confirmDelete(BuildContext context, Camera camera) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xoá camera?',
      message: 'Bạn có chắc muốn xoá "${camera.name}"? Hành động này không thể hoàn tác.',
    );
    if (!confirmed || !context.mounted) return;
    CameraStore.instance.deleteCamera(camera.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        CameraStore.instance,
        CameraStore.instance.cameraListenable(widget.cameraId),
      ]),
      builder: (context, _) {
        final camera = CameraStore.instance.cameraById(widget.cameraId);
        if (camera == null) {
          return const Scaffold(backgroundColor: AppColors.background);
        }
        final groupNames = camera.groupIds
            .map((id) => CameraStore.instance.groupById(id)?.name)
            .where((name) => name != null)
            .join(', ');
        final displayGroupName =
            groupNames.isNotEmpty ? groupNames : 'Chưa phân nhóm';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: _buildHeader(context, camera, displayGroupName),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPreview(camera),
                        const SizedBox(height: 20),
                        _buildControls(camera),
                        const SizedBox(height: 8),
                        _buildSpeakButton(),
                        _buildRecordingSection(context, camera),
                        _buildDeviceInfoSection(camera, displayGroupName),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Camera camera, String groupName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  groupName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            color: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              switch (value) {
                case 'history':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecordingListScreen(cameraId: camera.id),
                    ),
                  );
                case 'edit':
                  showCameraFormSheet(context, camera: camera);
                case 'delete':
                  _confirmDelete(context, camera);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'history',
                child: Text('Lịch sử ghi hình'),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Text('Sửa thông tin'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Xoá camera', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
          // _ConnectionToggleButton(camera: camera),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildProtocolChip(String label, bool selected) {
    return GestureDetector(
      onTap: () {
        final wantWebRTC = label == 'WebRTC';
        if (_useWebRTC != wantWebRTC) {
          setState(() => _useWebRTC = wantWebRTC);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withOpacity(0.9)
              : Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent(Camera camera) {
    if (!camera.online) {
      return const ColoredBox(
        color: Color(0x99000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 40),
              SizedBox(height: 8),
              Text(
                'Camera offline',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (_useWebRTC) {
      return WebRTCPlayerWidget(
        key: ValueKey('webrtc-${camera.id}-${camera.app}-${camera.cameraCode}'),
        app: camera.app ?? 'live',
        stream: camera.cameraCode,
      );
    }

    if (camera.hlsUrl?.isNotEmpty ?? false) {
      return _DetailVideoPlayer(
        key: ValueKey('detail-${camera.id}-${camera.hlsUrl}'),
        cameraId: camera.id,
        hlsUrl: camera.hlsUrl!,
      );
    }

    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.mediaPlaceholderGradient),
      child: Center(
        child: Icon(Icons.videocam_rounded, color: AppColors.mediaPlaceholderIcon, size: 56),
      ),
    );
  }

  Widget _buildPreview(Camera camera) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(child: _buildVideoContent(camera)),
                // Camera name badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      camera.name,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Protocol toggle chips
                if (camera.online)
                  Positioned(
                    top: 38,
                    left: 12,
                    child: Row(
                      children: [
                        _buildProtocolChip('HLS', !_useWebRTC),
                        const SizedBox(width: 6),
                        _buildProtocolChip('WebRTC', _useWebRTC),
                      ],
                    ),
                  ),
                // LIVE badge
                if (camera.online)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle,
                            ),
                          ),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Fullscreen button
                if (camera.online)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => Scaffold(
                            backgroundColor: Colors.black,
                            body: SafeArea(
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: _useWebRTC
                                      ? WebRTCPlayerWidget(
                                          app: camera.app ?? 'live',
                                          stream: camera.cameraCode,
                                        )
                                      : _DetailVideoPlayer(
                                          cameraId: camera.id,
                                          hlsUrl: camera.hlsUrl!,
                                        ),
                                ),
                              ),
                            ),
                            floatingActionButton: FloatingActionButton(
                              backgroundColor: Colors.white24,
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                            ),
                            floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
                          ),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fullscreen_rounded, color: Colors.white, size: 18,
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

  Widget _buildControls(Camera camera) {
    return ListenableBuilder(
      listenable: RecordingStore.instance.listenableFor(camera.id),
      builder: (context, _) {
        final isRec = RecordingStore.instance.isRecording(camera.id);
        final controls = [
          (
            icon: isRec
                ? Icons.stop_circle_rounded
                : Icons.fiber_manual_record_rounded,
            label: 'Record',
            active: isRec,
            onTap: _recordBusy
                ? () {}
                : () async {
                    if (!isRec && !camera.online) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Camera đang offline, không thể bắt đầu ghi hình'),
                        ),
                      );
                      return;
                    }
                    final store = RecordingStore.instance;
                    setState(() => _recordBusy = true);
                    try {
                      if (isRec) {
                        await store.stopRecord(
                          cameraId: camera.id,
                          app: camera.app ?? 'live',
                          stream: camera.cameraCode,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã dừng ghi hình')),
                          );
                        }
                      } else {
                        await store.startRecord(
                          cameraId: camera.id,
                          app: camera.app ?? 'live',
                          stream: camera.cameraCode,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Bắt đầu ghi hình...')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(RecordingStore.errorText(e))),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _recordBusy = false);
                    }
                  },
          ),
          (
            icon: Icons.camera_alt_rounded,
            label: 'Capture',
            active: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu ảnh chụp màn hình')),
              );
            },
          ),
          (
            icon: Icons.history_rounded,
            label: 'Lịch sử',
            active: false,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.background,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  minChildSize: 0.4,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (_, scrollController) => SingleChildScrollView(
                    controller: scrollController,
                    child: SafeArea(
                      child: _buildActivitySection(camera),
                    ),
                  ),
                ),
              );
            },
          ),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: controls
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: c == controls.last ? 0 : 10),
                      child: _ControlButton(
                        icon: c.icon,
                        label: c.label,
                        active: c.active,
                        onTap: c.onTap,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSpeakButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.infoGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Giữ để nói',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingSection(BuildContext context, Camera camera) {
    return ListenableBuilder(
      listenable: RecordingStore.instance.listenableFor(camera.id),
      builder: (ctx, _) {
        final isRec = RecordingStore.instance.isRecording(camera.id);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Ghi hình',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  if (isRec)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record_rounded,
                              size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text('REC',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => RecordingListScreen(cameraId: camera.id)),
                  ),
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
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.video_library_rounded,
                              color: AppColors.danger, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Xem bản ghi',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              SizedBox(height: 2),
                              Text('Tìm kiếm, xem và xóa video đã ghi',
                                  style: TextStyle(
                                      fontSize: 11.5, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildDeviceInfoSection(Camera camera, String groupName) {
    final rows = [
      ('Camera ID', camera.cameraCode, Icons.qr_code_2_rounded),
      ('Loại camera', camera.type, Icons.videocam_outlined),
      ('Địa chỉ IP', camera.ipAddress, Icons.wifi_rounded),
      ('Vị trí lắp đặt', camera.location, Icons.place_outlined),
      ('Nhóm', groupName, Icons.folder_open_rounded),
      (
        'Trạng thái',
        camera.online ? 'Online' : 'Offline',
        camera.online ? Icons.check_circle_rounded : Icons.cancel_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 26, 16, 12),
          child: Text(
            'Thông tin thiết bị',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(rows.length, (i) {
                final (label, value, icon) = rows[i];
                final isStatus = label == 'Trạng thái';
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(icon, size: 17, color: isStatus
                              ? (camera.online ? AppColors.success : AppColors.textMuted)
                              : AppColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: isStatus
                                    ? (camera.online ? AppColors.success : AppColors.danger)
                                    : AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != rows.length - 1)
                      Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(Camera camera) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Lịch sử hoạt động',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListenableBuilder(
            listenable: NotificationStore.instance,
            builder: (context, _) {
              final allNotifications = NotificationStore.instance.notifications;
              final cameraNotifications = allNotifications.where((n) {
                return n.source.toLowerCase() == 'camera' && n.message.contains(camera.cameraCode);
              }).take(50).toList();

              if (cameraNotifications.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'Chưa có hoạt động nào',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                );
              }

              return Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: List.generate(cameraNotifications.length, (i) {
                      final notif = cameraNotifications[i];
                      return Column(
                        children: [
                          _ActivityTile(notification: notif),
                          if (i != cameraNotifications.length - 1)
                            const Divider(
                              height: 1,
                              color: AppColors.divider,
                              indent: 14,
                              endIndent: 14,
                            ),
                        ],
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accent.withOpacity(0.12)
                : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AppNotification notification;

  const _ActivityTile({required this.notification});

  Color get _color {
    switch (notification.severity) {
      case NotificationSeverity.danger: return AppColors.danger;
      case NotificationSeverity.warning: return AppColors.warning;
      case NotificationSeverity.info: return AppColors.info;
      case NotificationSeverity.subscription: return AppColors.info;
    }
  }

  IconData get _icon {
    switch (notification.severity) {
      case NotificationSeverity.danger: return Icons.error_rounded;
      case NotificationSeverity.warning: return Icons.wifi_off_rounded;
      case NotificationSeverity.info: return Icons.info_rounded;
      case NotificationSeverity.subscription: return Icons.workspace_premium_rounded;
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
              color: _color.withOpacity(0.14),
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
                  notification.title,
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
                  notification.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailVideoPlayer extends StatefulWidget {
  final String cameraId;
  final String hlsUrl;
  const _DetailVideoPlayer({
    super.key,
    required this.cameraId,
    required this.hlsUrl,
  });
  @override
  State<_DetailVideoPlayer> createState() => _DetailVideoPlayerState();
}

class _DetailVideoPlayerState extends State<_DetailVideoPlayer> with RouteAware {
  VideoPlayerController? _controller;
  bool _hasError = false;
  bool _fromCache = false;
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant _DetailVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hlsUrl != widget.hlsUrl ||
        oldWidget.cameraId != widget.cameraId) {
      _disposeVideo();
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.hlsUrl.isEmpty) return;
    if (!mounted) return;
    _hasError = false;

    final cache = VideoPreloadCache.instance;

    // Instant path: reuse warmed controller from grid preload.
    var ctrl = cache.acquire(widget.cameraId);
    if (ctrl == null) {
      await cache.warm(widget.cameraId, widget.hlsUrl);
      if (!mounted) return;
      ctrl = cache.acquire(widget.cameraId);
    }

    if (ctrl != null) {
      _fromCache = true;
      _controller = ctrl;
      try {
        await ctrl.setVolume(1);
        await ctrl.setLooping(true);
        if (!ctrl.value.isPlaying) await ctrl.play();
      } catch (_) {}
      if (mounted) setState(() {});
      return;
    }

    // Fallback cold start (should be rare).
    _fromCache = false;
    try {
      final local = VideoPlayerController.networkUrl(Uri.parse(widget.hlsUrl));
      await local.initialize();
      if (!mounted) {
        local.dispose();
        return;
      }
      await local.setVolume(1);
      await local.setLooping(true);
      await local.play();
      setState(() => _controller = local);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _disposeVideo() {
    if (_controller == null) return;
    if (_fromCache) {
      VideoPreloadCache.instance.release(widget.cameraId, keepWarm: true);
    } else {
      _controller?.dispose();
    }
    _controller = null;
    _fromCache = false;
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    import_main.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    // Detach surface so fullscreen can reuse the same controller safely.
    try {
      _controller?.setVolume(0);
      _controller?.pause();
    } catch (_) {}
    if (mounted) setState(() => _obscured = true);
  }

  @override
  void didPopNext() {
    if (mounted) setState(() => _obscured = false);
    try {
      _controller?.setVolume(1);
      _controller?.play();
    } catch (_) {}
  }

  @override
  void dispose() {
    import_main.routeObserver.unsubscribe(this);
    if (_fromCache) {
      VideoPreloadCache.instance.release(widget.cameraId, keepWarm: true);
    } else {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_obscured &&
        _controller != null &&
        _controller!.value.isInitialized) {
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
              ? IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.danger, size: 34),
                  onPressed: _initializeVideo,
                )
              : _obscured
                  ? const SizedBox.shrink()
                  : const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white70),
                    ),
        ),
      ],
    );
  }
}

/// Interactive connect / disconnect toggle button shown in the camera detail
/// header. Mirrors the web dashboard's "Kết Nối Lại" / "Ngắt Kết Nối" buttons.
class _ConnectionToggleButton extends StatefulWidget {
  final Camera camera;
  const _ConnectionToggleButton({required this.camera});

  @override
  State<_ConnectionToggleButton> createState() => _ConnectionToggleButtonState();
}

class _ConnectionToggleButtonState extends State<_ConnectionToggleButton> {
  bool _loading = false;

  Future<void> _toggle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await CameraStore.instance.toggleConnection(widget.camera.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.camera.online;
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOnline
              ? AppColors.success.withOpacity(0.12)
              : AppColors.danger.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOnline
                ? AppColors.success.withOpacity(0.4)
                : AppColors.danger.withOpacity(0.4),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOnline
                        ? Icons.power_settings_new_rounded
                        : Icons.power_off_rounded,
                    color: isOnline ? AppColors.success : AppColors.danger,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? 'Ngắt' : 'Kết nối',
                    style: TextStyle(
                      color: isOnline ? AppColors.success : AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
