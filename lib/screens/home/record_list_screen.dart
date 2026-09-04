import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../data/camera_store.dart';
import '../../data/recording_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/captured_photo.dart';
import '../../utils/app_strings.dart';

class RecordingListScreen extends StatefulWidget {
  final String cameraId;

  const RecordingListScreen({super.key, required this.cameraId});

  @override
  State<RecordingListScreen> createState() => _RecordingListScreenState();
}

class _RecordingListScreenState extends State<RecordingListScreen> {
  final GlobalKey _videoKey = GlobalKey();
  bool _isFullscreen = false;
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
          colorScheme: ColorScheme.light(primary: AppColors.accent),
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
    if (!isRec && !cam.online) {
      _showSnack('Camera đang offline, không thể bắt đầu ghi hình'.tr, error: true);
      return;
    }
    setState(() => _loadingToggle = true);
    try {
      if (isRec) {
        await store.stopRecord(cameraId: cam.id, app: cam.app ?? 'live', stream: cam.cameraCode);
        _showSnack('Đã dừng ghi hình'.tr);
      } else {
        await store.startRecord(cameraId: cam.id, app: cam.app ?? 'live', stream: cam.cameraCode);
        _showSnack('Bắt đầu ghi hình'.tr);
      }
    } catch (e) {
      _showSnack(RecordingStore.errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _loadingToggle = false);
    }
  }

  Future<void> _toggleAutoRecord(bool value) async {
    final cam = _camera;
    if (cam == null) return;
    try {
      await RecordingStore.instance.toggleAutoRecord(cameraId: cam.id, enable: value);
      CameraStore.instance.setRecordingFlag(cam.id, value);
      if (mounted) setState(() => _enableMp4 = value);
      _showSnack(value ? 'Bật tự động ghi hình'.tr : 'Tắt tự động ghi hình'.tr);
    } catch (e) {
      _showSnack(RecordingStore.errorText(e), error: true);
    }
  }

  Future<void> _deleteRecording(RecordingFile file) async {
    final cam = _camera;
    if (cam == null) return;
    final ok = await _confirmDialog('Xóa bản ghi?'.tr,
        'Xóa file ${file.fileName} ngày ${file.date}? Không thể hoàn tác.'.tr);
    if (!ok) return;
    try {
      await RecordingStore.instance.deleteRecording(cameraId: cam.id, file: file);
      _showSnack('Đã xóa bản ghi'.tr);
    } catch (e) {
      _showSnack(RecordingStore.errorText(e), error: true);
    }
  }

  Future<bool> _confirmDialog(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            content: Text(msg, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy'.tr)),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Xóa'.tr, style: TextStyle(color: AppColors.danger)),
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
    // Auth đi kèm trong `?access_token=` của mp4Uri — không cần httpHeaders.
    final ctrl = VideoPlayerController.networkUrl(file.mp4Uri);
    setState(() {
      _vpController = ctrl;
      _playing = file;
    });
    try {
      await ctrl.initialize();
      ctrl.play();
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack('Không thể phát video: $e'.tr, error: true);
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

  
  Future<void> _takeSnapshot() async {
    try {
      final pngBytes = await CapturedPhoto.capture(_videoKey);
      if (!mounted) return;
      final saved = await CapturedPhoto.showPreviewAndSave(context, pngBytes);
      if (saved) _showSnack('Đã lưu ảnh vào Photos'.tr);
    } catch (e) {
      _showSnack('Lỗi chụp ảnh: $e'.tr, error: true);
    }
  }
  
  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Future<void> _changeSpeed() async {
    if (_vpController == null) return;
    final speed = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tốc độ phát'.tr, style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ListTile(title: Text('1.0x (Bình thường)'.tr), onTap: () => Navigator.pop(ctx, 1.0)),
          ListTile(title: Text('1.5x'), onTap: () => Navigator.pop(ctx, 1.5)),
          ListTile(title: Text('2.0x'), onTap: () => Navigator.pop(ctx, 2.0)),
          SizedBox(height: 16),
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
    final ok = await _confirmDialog('Cắt đoạn video'.tr, 'Hệ thống sẽ tạo 1 đoạn video dài 30 giây bắt đầu từ giây thứ $pos của bản ghi hiện tại. Tiếp tục?'.tr);
    if (!ok) return;

    _showSnack('Đang xử lý cắt video...'.tr);
    try {
      final clipUrl = await RecordingStore.instance.requestClip(file, pos, 30);
      _showSnack('Cắt thành công! Đã lưu tại: $clipUrl'.tr);
    } catch (e) {
      _showSnack(RecordingStore.errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cam = _camera;
    if (cam == null) {
      return Scaffold(backgroundColor: AppColors.background);
    }
    return ListenableBuilder(
      listenable: RecordingStore.instance.listenableFor(cam.id),
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
                if (!_isFullscreen)
                  // Header
                                  DecoratedBox(
                                    decoration: BoxDecoration(
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
                                                icon: Icon(Icons.arrow_back_ios_new_rounded,
                                                    color: AppColors.textPrimary, size: 20),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Bản ghi'.tr,
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
                                              SizedBox(width: 8),
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
                                                      Icon(Icons.calendar_today_rounded,
                                                          size: 13, color: AppColors.textSecondary),
                                                      SizedBox(width: 5),
                                                      Text(
                                                        '${_fmtShort(_startDate)} – ${_fmtShort(_endDate)}',
                                                        style: TextStyle(
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
                                                Icon(Icons.fiber_manual_record_rounded,
                                                    size: 14, color: AppColors.textMuted),
                                                SizedBox(width: 6),
                                                Expanded(
                                                  child: Text('Tự động ghi hình'.tr,
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
                          RepaintBoundary(
                            key: _videoKey,
                            child: VideoPlayer(_vpController!),
                          ),
                          // Overlay Controls
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black54, Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Play/Pause
                                  IconButton(
                                    icon: Icon(_vpController!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
                                    onPressed: () {
                                      setState(() {
                                        _vpController!.value.isPlaying ? _vpController!.pause() : _vpController!.play();
                                      });
                                    },
                                  ),
                                  // Mute
                                  IconButton(
                                    icon: Icon(_vpController!.value.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 28),
                                    onPressed: () {
                                      setState(() {
                                        _vpController!.setVolume(_vpController!.value.volume == 0 ? 1.0 : 0.0);
                                      });
                                    },
                                  ),
                                  // Snapshot
                                  IconButton(
                                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 28),
                                    onPressed: _takeSnapshot,
                                  ),

                                  // Cut
                                  IconButton(
                                    icon: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 28),
                                    onPressed: _cutVideo,
                                  ),
                                  // Fullscreen
                                  IconButton(
                                    icon: Icon(_isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white, size: 28),
                                    onPressed: _toggleFullscreen,
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                
                // Scrubber PA2
                if (_vpController != null && _vpController!.value.isInitialized)
                  _TimelineScrubber(controller: _vpController!),

                if (!_isFullscreen)
                  // List
                                  Expanded(
                                    child: isLoading
                                        ? Center(child: CircularProgressIndicator(color: AppColors.accent))
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
        child: Row(
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
      label = 'Hôm nay · $date'.tr;
    } else if (date == yesterday) {
      label = 'Hôm qua · $date'.tr;
    } else {
      label = date;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Text(label,
          style: TextStyle(
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
          child: Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
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
                          Positioned.fill(
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
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 2),
                        Text(
                          recording.displayTime,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11.5),
                        ),
                        if (recording.durationText.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(
                            recording.durationText,
                            style: TextStyle(
                                color: AppColors.accent, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Download button
                  IconButton(
                    icon: Icon(Icons.download_rounded,
                        size: 20, color: AppColors.accent),
                    onPressed: () async {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đang tải video...'.tr)),
                        );
                        final uri = Uri.parse(recording.mp4Url);
                        final res = await http.Client().send(http.Request('GET', uri));
                        if (res.statusCode == 200) {
                          final dir = Directory('/storage/emulated/0/Download');
                          if (!dir.existsSync()) dir.createSync(recursive: true);
                          final file = File('${dir.path}/${recording.fileName}');
                          await res.stream.pipe(file.openWrite());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đã lưu video vào thư mục Download'.tr)),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi tải video'.tr)),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e'.tr)),
                          );
                        }
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: 8),
                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
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
          SizedBox(height: 12),
          Text('Không có bản ghi'.tr,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Bật tự động ghi hình hoặc nhấn "Ghi hình".tr'.tr,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center),
          SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRefresh,
            icon: Icon(Icons.refresh_rounded, color: AppColors.accent),
            label: Text('Tải lại'.tr, style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}


class _TimelineScrubber extends StatefulWidget {
  final VideoPlayerController controller;
  const _TimelineScrubber({required this.controller});

  @override
  State<_TimelineScrubber> createState() => _TimelineScrubberState();
}

class _TimelineScrubberState extends State<_TimelineScrubber> {
  late VoidCallback _listener;
  bool _isDragging = false;
  double _dragPosition = 0;
  final double _pixelsPerSecond = 5.0; // 5 pixels = 1 second

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (!_isDragging && mounted) {
        setState(() {});
      }
    };
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final dur = widget.controller.value.duration;
    final pos = widget.controller.value.position;
    final currentSeconds = _isDragging ? _dragPosition : pos.inMilliseconds / 1000.0;
    final totalSeconds = dur.inMilliseconds / 1000.0;

    return Container(
      height: 80,
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          // Current time label
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(Duration(milliseconds: (currentSeconds * 1000).toInt())),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  onHorizontalDragStart: (details) {
                    setState(() {
                      _isDragging = true;
                      _dragPosition = pos.inMilliseconds / 1000.0;
                    });
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPosition -= details.primaryDelta! / _pixelsPerSecond;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > totalSeconds) _dragPosition = totalSeconds;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    widget.controller.seekTo(Duration(milliseconds: (_dragPosition * 1000).toInt()));
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  child: CustomPaint(
                    size: Size(width, double.infinity),
                    painter: _TimelinePainter(
                      currentSeconds: currentSeconds,
                      totalSeconds: totalSeconds,
                      pixelsPerSecond: _pixelsPerSecond,
                      accentColor: AppColors.accent,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final double currentSeconds;
  final double totalSeconds;
  final double pixelsPerSecond;
  final Color accentColor;

  _TimelinePainter({
    required this.currentSeconds,
    required this.totalSeconds,
    required this.pixelsPerSecond,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.0;
    
    final paintThick = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0;

    final paintCenter = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    final textStyle = const TextStyle(color: Colors.white70, fontSize: 10);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final double centerOffset = size.width / 2;
    
    // We draw from left to right.
    // The center offset represents 'currentSeconds'.
    // X coordinate for a given second 's' is: centerOffset + (s - currentSeconds) * pixelsPerSecond
    
    // Determine the visible range in seconds
    final double halfVisibleSeconds = (size.width / 2) / pixelsPerSecond;
    final int startSec = (currentSeconds - halfVisibleSeconds).floor();
    final int endSec = (currentSeconds + halfVisibleSeconds).ceil();

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw background blocks (just for styling, optional)
    final bgPaint = Paint()..color = const Color(0xFF2C2C2C);
    canvas.drawRect(Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2), bgPaint);

    for (int s = startSec; s <= endSec; s++) {
      if (s < 0 || s > totalSeconds) continue;
      
      final double x = centerOffset + (s - currentSeconds) * pixelsPerSecond;
      
      if (s % 10 == 0) { // Every 10 seconds, draw a tick
        if (s % 60 == 0) { // Every minute, draw a taller tick and text
          canvas.drawLine(Offset(x, 15), Offset(x, size.height), paintThick);
          
          final int m = s ~/ 60;
          final int hr = m ~/ 60;
          final int min = m % 60;
          final String label = hr > 0 
              ? "${hr.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}:00" 
              : "${min.toString().padLeft(2, '0')}:00";
          
          textPainter.text = TextSpan(text: label, style: textStyle);
          textPainter.layout();
          textPainter.paint(canvas, Offset(x - textPainter.width / 2, 0));
        } else {
          // Normal 10s tick
          canvas.drawLine(Offset(x, size.height / 2), Offset(x, size.height), paintLine);
        }
      } else if (s % 5 == 0) { // Every 5 seconds, short tick
        canvas.drawLine(Offset(x, size.height * 0.7), Offset(x, size.height), paintLine..color = Colors.white24);
      }
    }

    // Draw center pointer
    canvas.drawLine(Offset(centerOffset, 15), Offset(centerOffset, size.height), paintCenter);
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.currentSeconds != currentSeconds ||
           oldDelegate.totalSeconds != totalSeconds;
  }
}
