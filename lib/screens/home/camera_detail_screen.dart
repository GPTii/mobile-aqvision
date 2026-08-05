import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'record_list_screen.dart';

class _MotionEvent {
  final String location;
  final String time;

  const _MotionEvent(this.location, this.time);
}

class CameraDetailScreen extends StatefulWidget {
  final String name;
  final String location;
  final bool online;
  final String resolution;
  final bool recording;

  const CameraDetailScreen({
    super.key,
    required this.name,
    required this.location,
    required this.online,
    this.resolution = '1080p',
    this.recording = true,
  });

  @override
  State<CameraDetailScreen> createState() => _CameraDetailScreenState();
}

class _CameraDetailScreenState extends State<CameraDetailScreen> {
  final _pageController = PageController();
  int _page = 0;
  late bool _isRecording = widget.recording;
  bool _isAlarmArmed = false;

  static const _motionEvents = [
    _MotionEvent('Gần cửa ra vào', '5 phút trước'),
    _MotionEvent('Khu vực trung tâm', '22 phút trước'),
    _MotionEvent('Gần cửa sổ', '1 giờ trước'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: _buildHeader(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPreview(),
                    _buildDots(),
                    const SizedBox(height: 20),
                    _buildControls(),
                    const SizedBox(height: 8),
                    _buildSpeakButton(),
                    _buildMotionSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecordListScreen(cameraName: widget.name),
              ),
            ),
            icon: const Icon(
              Icons.history_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          Icon(
            widget.online
                ? Icons.power_settings_new_rounded
                : Icons.power_off_rounded,
            color: widget.online ? AppColors.success : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildPreview() {
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
            child: PageView.builder(
              controller: _pageController,
              itemCount: 3,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) => Stack(
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
                        'Cam ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (widget.online)
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
      ),
    );
  }

  Widget _buildDots() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final selected = index == _page;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: selected ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildControls() {
    final controls = [
      (
        icon: _isRecording
            ? Icons.stop_circle_rounded
            : Icons.fiber_manual_record_rounded,
        label: 'Record',
        active: _isRecording,
        onTap: () => setState(() => _isRecording = !_isRecording),
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

  Widget _buildMotionSection() {
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
                    _MotionTile(event: event, cameraName: widget.name),
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
