import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../main.dart' as import_main;

import '../../data/camera_store.dart';
import '../../data/recording_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/camera_form_sheet.dart';
import '../../widgets/prompt_dialog.dart';
import 'record_list_screen.dart';

class _MotionEvent {
  final String location;
  final String time;

  const _MotionEvent(this.location, this.time);
}

const _motionEvents = [
  _MotionEvent('Gần cửa ra vào', '5 phút trước'),
  _MotionEvent('Khu vực trung tâm', '22 phút trước'),
  _MotionEvent('Gần cửa sổ', '1 giờ trước'),
];

class CameraDetailScreen extends StatefulWidget {
  final String cameraId;

  const CameraDetailScreen({super.key, required this.cameraId});

  @override
  State<CameraDetailScreen> createState() => _CameraDetailScreenState();
}

class _CameraDetailScreenState extends State<CameraDetailScreen> {
  bool _isAlarmArmed = false;
  bool _recordBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRecordStatus());
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
      listenable: CameraStore.instance,
      builder: (context, _) {
        final camera = CameraStore.instance.cameraById(widget.cameraId);
        if (camera == null) {
          return const Scaffold(backgroundColor: AppColors.background);
        }
        final groupNames = camera.groupIds
            .map((id) => CameraStore.instance.groupById(id)?.name)
            .where((name) => name != null)
            .join(', ');
        final displayGroupName = groupNames.isNotEmpty ? groupNames : 'Chưa phân nhóm';

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
                        _buildMotionSection(camera),
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
          _ConnectionToggleButton(camera: camera),
          const SizedBox(width: 4),
        ],
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
                Positioned.fill(
                  child: camera.online && (camera.hlsUrl?.isNotEmpty ?? false)
                      ? _DetailVideoPlayer(hlsUrl: camera.hlsUrl!)
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.mediaPlaceholderGradient,
                              ),
                            ),
                            const Center(
                              child: Icon(
                                Icons.videocam_rounded,
                                color: AppColors.mediaPlaceholderIcon,
                                size: 56,
                              ),
                            ),
                          ],
                        ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      camera.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (camera.online)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (camera.online && (camera.hlsUrl?.isNotEmpty ?? false))
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
                                  aspectRatio: 16/9,
                                  child: _DetailVideoPlayer(hlsUrl: camera.hlsUrl!),
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
                          Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 18,
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
      listenable: RecordingStore.instance,
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
            icon: _isAlarmArmed
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            label: 'Alarm',
            active: _isAlarmArmed,
            onTap: () => setState(() => _isAlarmArmed = !_isAlarmArmed),
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
      listenable: RecordingStore.instance,
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

  Widget _buildMotionSection(Camera camera) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 26, 16, 12),
          child: Text(
            'Phát hiện chuyển động',
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
              children: List.generate(_motionEvents.length, (i) {
                final event = _motionEvents[i];
                return Column(
                  children: [
                    _MotionTile(event: event, cameraName: camera.name),
                    if (i != _motionEvents.length - 1)
                      Divider(
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

class _MotionTile extends StatelessWidget {
  final _MotionEvent event;
  final String cameraName;

  const _MotionTile({required this.event, required this.cameraName});

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
              color: AppColors.warning.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.directions_walk_rounded,
              size: 18,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phát hiện chuyển động',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$cameraName · ${event.location} · ${event.time}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              size: 18,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailVideoPlayer extends StatefulWidget {
  final String hlsUrl;
  const _DetailVideoPlayer({required this.hlsUrl});
  @override
  State<_DetailVideoPlayer> createState() => _DetailVideoPlayerState();
}

class _DetailVideoPlayerState extends State<_DetailVideoPlayer> with RouteAware {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    if (widget.hlsUrl.isNotEmpty) {
      // Delay initialization slightly to let background routes release their decoders
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      _hasError = false;
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.hlsUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller!.setVolume(1);
            _controller!.play();
          }
        }).catchError((_) {
          if (mounted) setState(() => _hasError = true);
        });
    }
  }

  void _disposeVideo() {
    _controller?.dispose();
    _controller = null;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    import_main.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    _disposeVideo();
  }

  @override
  void didPopNext() {
    _initializeVideo();
  }

  @override
  void dispose() {
    import_main.routeObserver.unsubscribe(this);
    _controller?.dispose();
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
