import 'package:flutter/material.dart';

import '../../data/camera_store.dart';
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
        final group = CameraStore.instance.groupById(camera.groupId);

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
                  child: _buildHeader(context, camera, group?.name ?? ''),
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
                        _buildDeviceInfoSection(camera, group?.name ?? ''),
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
                      builder: (_) => RecordListScreen(cameraName: camera.name),
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
          Icon(
            camera.online
                ? Icons.power_settings_new_rounded
                : Icons.power_off_rounded,
            color: camera.online ? AppColors.success : AppColors.textMuted,
            size: 22,
          ),
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
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.mediaPlaceholderGradient,
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.videocam_rounded,
                    color: AppColors.mediaPlaceholderIcon,
                    size: 56,
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
                      color: Colors.black.withValues(alpha: 0.5),
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
                        color: AppColors.danger.withValues(alpha: 0.9),
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
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 18,
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
    final controls = [
      (
        icon: camera.recording
            ? Icons.stop_circle_rounded
            : Icons.fiber_manual_record_rounded,
        label: 'Record',
        active: camera.recording,
        onTap: () => CameraStore.instance.updateCamera(
          camera.id,
          recording: !camera.recording,
        ),
      ),
      (
        icon: Icons.camera_alt_rounded,
        label: 'Capture',
        active: false,
        onTap: () {},
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
                  color: AppColors.info.withValues(alpha: 0.3),
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
                ? AppColors.accent.withValues(alpha: 0.12)
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
              color: AppColors.warning.withValues(alpha: 0.14),
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
              color: AppColors.accent.withValues(alpha: 0.14),
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
