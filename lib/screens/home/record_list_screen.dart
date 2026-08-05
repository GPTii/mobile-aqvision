import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class _Recording {
  final String title;
  final String time;
  final String size;

  const _Recording(this.title, this.time, this.size);
}

class RecordListScreen extends StatelessWidget {
  final String? cameraName;

  const RecordListScreen({super.key, this.cameraName});

  static const _today = [
    _Recording('Cổng chính', '12:30', '36.9 MB'),
    _Recording('Kho hàng', '10:30', '28.4 MB'),
    _Recording('Hành lang T2', '08:30', '31.2 MB'),
  ];

  static const _yesterday = [
    _Recording('Quầy lễ tân', '21:30', '36.9 MB'),
    _Recording('Kho hàng', '20:30', '24.1 MB'),
    _Recording('Sân thượng', '17:25', '19.7 MB'),
  ];

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _DateHeader(label: 'Hôm nay'),
                  ..._today.map((r) => _RecordingTile(recording: r)),
                  const SizedBox(height: 8),
                  _DateHeader(label: 'Hôm qua'),
                  ..._yesterday.map((r) => _RecordingTile(recording: r)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Danh sách bản ghi',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                if (cameraName != null)
                  Text(
                    cameraName!,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Icon(Icons.filter_list_rounded, color: AppColors.textSecondary, size: 22),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String label;

  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
      child: Text(
        label,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  final _Recording recording;

  const _RecordingTile({required this.recording});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(gradient: AppColors.mediaPlaceholderGradient),
                          ),
                        ),
                        const Center(
                          child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 22),
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
                        recording.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        recording.size,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  recording.time,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
