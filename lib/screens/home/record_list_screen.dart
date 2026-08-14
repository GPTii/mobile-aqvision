import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/camera_store.dart';
import '../../data/recording_store.dart';
import '../../theme/app_colors.dart';

class RecordingListScreen extends StatefulWidget {
  final String cameraId;

  const RecordingListScreen({super.key, required this.cameraId});

  @override
  State<RecordingListScreen> createState() => _RecordingListScreenState();
}

class _RecordingListScreenState extends State<RecordingListScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  VideoPlayerController? _vpController;
  RecordingFile? _playing;
  bool _loadingToggle = false;
  bool _enableMp4 = false;

  Camera? get _camera => CameraStore.instance.cameraById(widget.cameraId);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 6));
    _endDate = now;
    _load();
  }

  @override
  void dispose() {
    _vpController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cam = _camera;
    if (cam == null) return;
    final store = RecordingStore.instance;
    await store.checkRecordStatus(
      cameraId: cam.id,
      app: cam.app ?? 'live',
      stream: cam.cameraCode,
    );
    await store.fetchRecordings(
      cameraId: cam.id,
      app: cam.app ?? 'live',
      stream: cam.cameraCode,
      serverUrl: cam.targetUrl ?? '',
      startDate: _fmt(_startDate),
      endDate: _fmt(_endDate),
    );
    if (mounted) {
      setState(() {
        _enableMp4 = cam.recording;
      });
    }
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _load();
    }
  }

  Future<void> _toggleRecord() async {
    final cam = _camera;
    if (cam == null) return;
    final store = RecordingStore.instance;
    final isRec = store.isRecording(cam.id);
    setState(() => _loadingToggle = true);
    try {
      if (isRec) {
        await store.stopRecord(cameraId: cam.id, app: cam.app ?? 'live', stream: cam.cameraCode);
        _showSnack('Đã dừng ghi hình');
      } else {
        await store.startRecord(cameraId: cam.id, app: cam.app ?? 'live', stream: cam.cameraCode);
        _showSnack('Bắt đầu ghi hình');
      }
    } catch (e) {
      _showSnack('Lỗi: $e', error: true);
    } finally {
      if (mounted) setState(() => _loadingToggle = false);
    }
  }

  Future<void> _toggleAutoRecord(bool value) async {
    final cam = _camera;
    if (cam == null) return;
    try {
      await RecordingStore.instance.toggleAutoRecord(cameraId: cam.id, enable: value);
      if (mounted) setState(() => _enableMp4 = value);
      _showSnack(value ? 'Bật tự động ghi hình' : 'Tắt tự động ghi hình');
    } catch (e) {
      _showSnack('Lỗi: $e', error: true);
    }
  }

  Future<void> _deleteRecording(RecordingFile file) async {
    final cam = _camera;
    if (cam == null) return;
    final ok = await _confirmDialog('Xóa bản ghi?',
        'Xóa file ${file.fileName} ngày ${file.date}? Không thể hoàn tác.');
    if (!ok) return;
    try {
      await RecordingStore.instance.deleteRecording(cameraId: cam.id, file: file);
      _showSnack('Đã xóa bản ghi');
    } catch (e) {
      _showSnack('Lỗi: $e', error: true);
    }
  }

  Future<bool> _confirmDialog(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            content: Text(msg, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _playFile(RecordingFile file) async {
    if (_playing?.id == file.id) {
      _vpController?.dispose();
      setState(() {
        _vpController = null;
        _playing = null;
      });
      return;
    }
    _vpController?.dispose();
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(file.mp4Url));
    setState(() {
      _vpController = ctrl;
      _playing = file;
    });
    try {
      await ctrl.initialize();
      ctrl.play();
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack('Không thể phát video: $e', error: true);
      _vpController?.dispose();
      if (mounted) {
        setState(() {
          _vpController = null;
          _playing = null;
        });
      }
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _changeSpeed() async {
    if (_vpController == null) return;
    final speed = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tốc độ phát', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ListTile(title: const Text('1.0x (Bình thường)'), onTap: () => Navigator.pop(ctx, 1.0)),
          ListTile(title: const Text('1.5x'), onTap: () => Navigator.pop(ctx, 1.5)),
          ListTile(title: const Text('2.0x'), onTap: () => Navigator.pop(ctx, 2.0)),
          const SizedBox(height: 16),
        ],
      ),
    );
    if (speed != null && mounted) {
      await _vpController!.setPlaybackSpeed(speed);
      setState(() {});
    }
  }

  Future<void> _cutVideo() async {
    final file = _playing;
    final cam = _camera;
    if (file == null || cam == null || _vpController == null) return;

    final pos = _vpController!.value.position.inSeconds;
    final ok = await _confirmDialog('Cắt đoạn video', 'Hệ thống sẽ tạo 1 đoạn video dài 30 giây bắt đầu từ giây thứ $pos của bản ghi hiện tại. Tiếp tục?');
    if (!ok) return;

    _showSnack('Đang xử lý cắt video...');
    try {
      final clipUrl = await RecordingStore.instance.requestClip(file, pos, 30);
      _showSnack('Cắt thành công! Đã lưu tại: $clipUrl');
    } catch (e) {
      _showSnack('Lỗi: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cam = _camera;
    if (cam == null) {
      return const Scaffold(backgroundColor: AppColors.background);
    }
    return ListenableBuilder(
      listenable: RecordingStore.instance,
      builder: (ctx, _) {
        final store = RecordingStore.instance;
        final isRec = store.isRecording(cam.id);
        final isLoading = store.isLoading(cam.id);
        final recordings = store.recordingsFor(cam.id);

        // Group by date
        final Map<String, List<RecordingFile>> grouped = {};
        for (final r in recordings) {
          grouped.putIfAbsent(r.date, () => []).add(r);
        }
        final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.textPrimary, size: 20),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Bản ghi',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700)),
                                  Text(cam.name,
                                      style: TextStyle(
                                          color: AppColors.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                            // REC badge
                            if (isRec)
                              _PulsingRecBadge(),
                            const SizedBox(width: 8),
                            // Date filter button
                            GestureDetector(
                              onTap: _pickDateRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 13, color: AppColors.textSecondary),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${_fmtShort(_startDate)} – ${_fmtShort(_endDate)}',
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Auto record toggle
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
                          child: Row(
                            children: [
                              const Icon(Icons.fiber_manual_record_rounded,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text('Tự động ghi hình',
                                    style: TextStyle(
                                        fontSize: 13, color: AppColors.textSecondary)),
                              ),
                              Transform.scale(
                                scale: 0.85,
                                child: Switch(
                                  value: _enableMp4,
                                  onChanged: _toggleAutoRecord,
                                  activeColor: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Video Player (when playing)
                if (_vpController != null && _vpController!.value.isInitialized)
                  Container(
                    color: Colors.black,
                    child: AspectRatio(
                      aspectRatio: _vpController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_vpController!),
                          VideoProgressIndicator(_vpController!,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: AppColors.accent,
                                backgroundColor: Colors.white24,
                              )),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                _vpController?.dispose();
                                setState(() {
                                  _vpController = null;
                                  _playing = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Advanced Controls
                if (_vpController != null && _vpController!.value.isInitialized)
                  Container(
                    color: AppColors.headerBackground,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _changeSpeed,
                          icon: const Icon(Icons.speed_rounded, size: 18),
                          label: Text('${_vpController!.value.playbackSpeed}x'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _cutVideo,
                          icon: const Icon(Icons.content_cut_rounded, size: 16),
                          label: const Text('Cắt 30s'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ],
                    ),
                  ),

                // List
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : recordings.isEmpty
                          ? _EmptyRecordings(onRefresh: _load)
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: AppColors.accent,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                itemCount: dates.length,
                                itemBuilder: (ctx, i) {
                                  final date = dates[i];
                                  final items = grouped[date]!;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _DateHeader(date: date),
                                      ...items.map((r) => _RecordingTile(
                                            recording: r,
                                            isPlaying: _playing?.id == r.id,
                                            onPlay: () => _playFile(r),
                                            onDelete: () => _deleteRecording(r),
                                          )),
                                    ],
                                  );
                                },
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

  String _fmtShort(DateTime d) => '${d.day}/${d.month}';
}

// ── sub-widgets ───────────────────────────────────────────────────────────────

class _PulsingRecBadge extends StatefulWidget {
  @override
  State<_PulsingRecBadge> createState() => _PulsingRecBadgeState();
}

class _PulsingRecBadgeState extends State<_PulsingRecBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record_rounded, size: 8, color: Colors.white),
            SizedBox(width: 4),
            Text('REC',
                style: TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')[0];
    String label;
    if (date == today) {
      label = 'Hôm nay · $date';
    } else if (date == yesterday) {
      label = 'Hôm qua · $date';
    } else {
      label = date;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  final RecordingFile recording;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _RecordingTile({
    required this.recording,
    required this.isPlaying,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(recording.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
        ),
        confirmDismiss: (_) async {
          onDelete();
          return false; // let store update list
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPlay,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPlaying
                    ? AppColors.accent.withOpacity(0.07)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isPlaying ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 58,
                      height: 44,
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient: AppColors.mediaPlaceholderGradient),
                            ),
                          ),
                          Center(
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
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
                          recording.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bắt đầu ${recording.displayTime}',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.textMuted),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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

class _EmptyRecordings extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyRecordings({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('Không có bản ghi',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Bật tự động ghi hình hoặc nhấn "Ghi hình"',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            label: const Text('Tải lại', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}
