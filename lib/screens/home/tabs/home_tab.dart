import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../camera_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 900));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.accent,
          backgroundColor: AppColors.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              for (final room in _rooms)
                SliverToBoxAdapter(child: _RoomSection(room: room)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCamera {
  final String label;
  final bool online;
  final String time;

  const _RoomCamera(this.label, this.online, this.time);
}

class _Room {
  final String name;
  final List<_RoomCamera> cameras;

  const _Room(this.name, this.cameras);
}

const _rooms = [
  _Room('Phòng khách', [
    _RoomCamera('Cam 1', true, '15:45'),
    _RoomCamera('Cam 2', true, '15:45'),
    _RoomCamera('Cam 3', false, '15:20'),
  ]),
  _Room('Nhà bếp', [
    _RoomCamera('Cam 1', true, '15:40'),
    _RoomCamera('Cam 2', true, '15:38'),
    _RoomCamera('Cam 3', true, '15:36'),
  ]),
  _Room('Bãi đỗ xe', [
    _RoomCamera('Cam 1', true, '15:30'),
    _RoomCamera('Cam 2', false, '14:58'),
  ]),
];

class _RoomSection extends StatelessWidget {
  final _Room room;

  const _RoomSection({required this.room});

  @override
  Widget build(BuildContext context) {
    final extras = room.cameras.skip(1).take(2).toList();
    final overflowCount = room.cameras.length - 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoomHeader(name: room.name, cameraCount: room.cameras.length),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _CameraTile(
                  room: room.name,
                  camera: room.cameras.first,
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
                            room: room.name,
                            camera: extras[index],
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
          ),
        ],
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  final String name;
  final int cameraCount;

  const _RoomHeader({required this.name, required this.cameraCount});

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
                  name,
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
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraTile extends StatelessWidget {
  final String room;
  final _RoomCamera camera;
  final double aspectRatio;
  final int overflowCount;

  const _CameraTile({
    required this.room,
    required this.camera,
    required this.aspectRatio,
    this.overflowCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CameraDetailScreen(
              name: camera.label,
              location: room,
              online: camera.online,
            ),
          ),
        ),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                    size: 30,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _Chip(text: camera.label),
                ),
                if (camera.online)
                  const Positioned(top: 8, right: 8, child: _LiveBadge()),
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
                          Colors.black.withValues(alpha: 0),
                          Colors.black.withValues(alpha: 0.55),
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
                          camera.time,
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
                        color: Colors.black.withValues(alpha: 0.55),
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
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
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
        color: AppColors.danger.withValues(alpha: 0.92),
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
