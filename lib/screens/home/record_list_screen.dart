import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/camera_store.dart';
import '../../data/recording_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/captured_photo.dart';
import '../../utils/app_strings.dart';
import '../../widgets/app_ui.dart';

enum _RecordingSource { cloud, sdCard }

class RecordingListScreen extends StatefulWidget {
  final String cameraId;

  const RecordingListScreen({super.key, required this.cameraId});

  @override
  State<RecordingListScreen> createState() => _RecordingListScreenState();
}

class _RecordingListScreenState extends State<RecordingListScreen> {
  final GlobalKey _videoKey = GlobalKey();
  final ScrollController _timelineController = ScrollController();

  bool _isFullscreen = false;
  DateTime _selectedDate = DateTime.now();
  _RecordingSource _source = _RecordingSource.cloud;
  double _pxPerMinute = 3.0;
  VideoPlayerController? _vpController;
  RecordingFile? _playing;
  bool _enableMp4 = false;
  int? _playingElapsedSeconds;
  late VoidCallback _playbackListener;
  bool _autoPlayed = false;

  Camera? get _camera => CameraStore.instance.cameraById(widget.cameraId);

  @override
  void initState() {
    super.initState();
    _playbackListener = () {
      final ctrl = _vpController;
      if (ctrl == null || !mounted) return;
      final s = ctrl.value.position.inSeconds;
      if (s != _playingElapsedSeconds) setState(() => _playingElapsedSeconds = s);
    };
    _load();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _vpController?.removeListener(_playbackListener);
    _vpController?.dispose();
    _timelineController.dispose();
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
    final dayStr = _fmt(_selectedDate);
    await store.fetchRecordings(
      cameraId: cam.id,
      app: cam.app ?? 'live',
      stream: cam.cameraCode,
      serverUrl: cam.targetUrl ?? '',
      startDate: dayStr,
      endDate: dayStr,
    );
    if (mounted) {
      setState(() => _enableMp4 = cam.recording);
      _scrollToRelevantTime();
      _autoPlayLatest();
    }
  }

  /// On first open, start the most recent recording of the day right away.
  void _autoPlayLatest() {
    if (_autoPlayed || _playing != null) return;
    final cam = _camera;
    if (cam == null) return;
    final recordings = RecordingStore.instance.recordingsFor(cam.id);
    if (recordings.isEmpty) return;
    _autoPlayed = true;
    final latest = recordings.reduce((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate > 0 ? a : b;
      return (a.startOfDaySeconds ?? 0) >= (b.startOfDaySeconds ?? 0) ? a : b;
    });
    _playFile(latest);
  }

  void _scrollToRelevantTime() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_timelineController.hasClients) return;
      final isToday = _fmt(_selectedDate) == _fmt(DateTime.now());
      final nowSeconds = isToday
          ? DateTime.now().hour * 3600 + DateTime.now().minute * 60
          : 8 * 3600; // default scroll to 08:00 for past days
      final target = (nowSeconds / 60 * _pxPerMinute) - 200;
      _timelineController.jumpTo(target.clamp(0, _timelineController.position.maxScrollExtent));
    });
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtShort(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}';

  void _shiftDay(int delta) {
    final next = _selectedDate.add(Duration(days: delta));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = next);
    _load();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      initialDate: _selectedDate,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: AppColors.accent)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      await _load();
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
    final ok = await _confirmDialog('Xóa bản ghi?'.tr,
        'Xóa file {file} ngày {date}? Không thể hoàn tác.'.trArgs({'file': file.fileName, 'date': file.date}));
    if (!ok) return;
    try {
      await RecordingStore.instance.deleteRecording(cameraId: widget.cameraId, file: file);
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
    if (_playing?.id == file.id) return;
    _vpController?.removeListener(_playbackListener);
    _vpController?.dispose();
    final ctrl = VideoPlayerController.networkUrl(file.mp4Uri);
    setState(() {
      _vpController = ctrl;
      _playing = file;
      _playingElapsedSeconds = 0;
    });
    try {
      await ctrl.initialize();
      await ctrl.setVolume(1.0);
      ctrl.addListener(_playbackListener);
      ctrl.play();
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack('Không thể phát video: {e}'.trArgs({'e': e}), error: true);
      _vpController?.dispose();
      if (mounted)
        setState(() {
          _vpController = null;
          _playing = null;
        });
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
      _showSnack('Lỗi chụp ảnh: {e}'.trArgs({'e': e}), error: true);
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Future<void> _changeSpeed() async {
    if (_vpController == null) return;
    final speed = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Tốc độ phát'.tr, style: TextStyle(fontWeight: FontWeight.w700))),
            ListTile(title: Text('1.0x (Bình thường)'.tr), onTap: () => Navigator.pop(ctx, 1.0)),
            ListTile(title: const Text('1.5x'), onTap: () => Navigator.pop(ctx, 1.5)),
            ListTile(title: const Text('2.0x'), onTap: () => Navigator.pop(ctx, 2.0)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (speed != null && mounted) {
      await _vpController!.setPlaybackSpeed(speed);
      setState(() {});
    }
  }

  Future<void> _cutVideo() async {
    final file = _playing;
    if (file == null || _vpController == null) return;
    final pos = _vpController!.value.position.inSeconds;
    final ok = await _confirmDialog(
        'Cắt đoạn video'.tr,
        'Hệ thống sẽ tạo 1 đoạn video dài 30 giây bắt đầu từ giây thứ {pos} của bản ghi hiện tại. Tiếp tục?'
            .trArgs({'pos': pos}));
    if (!ok) return;
    _showSnack('Đang xử lý cắt video...'.tr);
    try {
      final clipUrl = await RecordingStore.instance.requestClip(file, pos, 30);
      _showSnack('Cắt thành công! Đã lưu tại: {url}'.trArgs({'url': clipUrl}));
    } catch (e) {
      _showSnack(RecordingStore.errorText(e), error: true);
    }
  }

  Future<void> _downloadFile(RecordingFile recording) async {
    try {
      _showSnack('Đang tải video...'.tr);
      final uri = Uri.parse(recording.mp4Url);
      final res = await http.Client().send(http.Request('GET', uri));
      if (res.statusCode == 200) {
        final dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) dir.createSync(recursive: true);
        final file = File('${dir.path}/${recording.fileName}');
        await res.stream.pipe(file.openWrite());
        _showSnack('Đã lưu video vào thư mục Download'.tr);
      } else {
        _showSnack('Lỗi tải video'.tr, error: true);
      }
    } catch (e) {
      _showSnack('Lỗi: {e}'.trArgs({'e': e}), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cam = _camera;
    if (cam == null) return AppBackground(child: Scaffold(backgroundColor: Colors.transparent));

    return ListenableBuilder(
      listenable: RecordingStore.instance.listenableFor(cam.id),
      builder: (ctx, _) {
        final store = RecordingStore.instance;
        final isRec = store.isRecording(cam.id);
        final isLoading = store.isLoading(cam.id);
        final recordings = store.recordingsFor(cam.id)
          ..sort((a, b) => (a.startOfDaySeconds ?? 0).compareTo(b.startOfDaySeconds ?? 0));

        return AppBackground(
            child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                if (!_isFullscreen)
                  _Header(camera: cam, isRec: isRec, enableMp4: _enableMp4, onToggleAutoRecord: _toggleAutoRecord),
                _VideoArea(
                  videoKey: _videoKey,
                  controller: _vpController,
                  isFullscreen: _isFullscreen,
                  onClose: () {
                    _vpController?.removeListener(_playbackListener);
                    _vpController?.dispose();
                    setState(() {
                      _vpController = null;
                      _playing = null;
                      _playingElapsedSeconds = null;
                    });
                  },
                ),
                if (_vpController != null && _vpController!.value.isInitialized)
                  _PlaybackControls(
                    controller: _vpController!,
                    isFullscreen: _isFullscreen,
                    onPlayPause: () =>
                        setState(() => _vpController!.value.isPlaying ? _vpController!.pause() : _vpController!.play()),
                    onMute: () =>
                        setState(() => _vpController!.setVolume(_vpController!.value.volume == 0 ? 1.0 : 0.0)),
                    onSpeed: _changeSpeed,
                    onSnapshot: _takeSnapshot,
                    onCut: _cutVideo,
                    onFullscreen: _toggleFullscreen,
                  ),
                if (!_isFullscreen) ...[
                  _SourceTabs(
                    source: _source,
                    onChanged: (s) => setState(() => _source = s),
                  ),
                  _DateNav(
                    label: _fmtShort(_selectedDate),
                    onPrev: () => _shiftDay(-1),
                    onNext: () => _shiftDay(1),
                    onTapLabel: _pickDate,
                  ),
                  Expanded(
                    child: isLoading
                        ? Center(child: CircularProgressIndicator(color: AppColors.accent))
                        : recordings.isEmpty
                            ? _EmptyRecordings(onRefresh: _load)
                            : RefreshIndicator(
                                onRefresh: _load,
                                color: AppColors.accent,
                                child: _DayTimeline(
                                  scrollController: _timelineController,
                                  recordings: recordings,
                                  playing: _playing,
                                  playingElapsedSeconds: _playingElapsedSeconds,
                                  pxPerMinute: _pxPerMinute,
                                  onZoomIn: () => setState(() => _pxPerMinute = (_pxPerMinute + 1).clamp(1.0, 8.0)),
                                  onZoomOut: () => setState(() => _pxPerMinute = (_pxPerMinute - 1).clamp(1.0, 8.0)),
                                  onTapRecording: _playFile,
                                  onDeleteRecording: _deleteRecording,
                                  onDownloadRecording: _downloadFile,
                                ),
                              ),
                  ),
                ],
              ],
            ),
          ),
        ));
      },
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Camera camera;
  final bool isRec;
  final bool enableMp4;
  final ValueChanged<bool> onToggleAutoRecord;

  const _Header({required this.camera, required this.isRec, required this.enableMp4, required this.onToggleAutoRecord});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Builder(
                    builder: (context) => IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                        )),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bản ghi'.tr,
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                      Text(camera.name, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (isRec) const _PulsingRecBadge(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
              child: Row(
                children: [
                  Icon(Icons.fiber_manual_record_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                      child:
                          Text('Tự động ghi hình'.tr, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(value: enableMp4, onChanged: onToggleAutoRecord, activeColor: AppColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingRecBadge extends StatefulWidget {
  const _PulsingRecBadge();
  @override
  State<_PulsingRecBadge> createState() => _PulsingRecBadgeState();
}

class _PulsingRecBadgeState extends State<_PulsingRecBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
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
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record_rounded, size: 8, color: Colors.white),
            const SizedBox(width: 4),
            const Text('REC', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ── Video area ───────────────────────────────────────────────────────────────

class _VideoArea extends StatelessWidget {
  final GlobalKey videoKey;
  final VideoPlayerController? controller;
  final bool isFullscreen;
  final VoidCallback onClose;

  const _VideoArea(
      {required this.videoKey, required this.controller, required this.isFullscreen, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final ready = controller != null && controller!.value.isInitialized;
    final content = Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: ready
              ? RepaintBoundary(key: videoKey, child: VideoPlayer(controller!))
              : DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.mediaPlaceholderGradient),
                  child: Center(
                    child: Icon(Icons.movie_creation_outlined, size: 36, color: AppColors.mediaPlaceholderIcon),
                  ),
                ),
        ),
        if (ready)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );

    if (isFullscreen) {
      return Expanded(child: Container(color: Colors.black, child: content));
    }
    return Container(
      color: Colors.black,
      child: AspectRatio(aspectRatio: 16 / 9, child: content),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isFullscreen;
  final VoidCallback onPlayPause;
  final VoidCallback onMute;
  final VoidCallback onSpeed;
  final VoidCallback onSnapshot;
  final VoidCallback onCut;
  final VoidCallback onFullscreen;

  const _PlaybackControls({
    required this.controller,
    required this.isFullscreen,
    required this.onPlayPause,
    required this.onMute,
    required this.onSpeed,
    required this.onSnapshot,
    required this.onCut,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF17171B),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SeekBar(controller: controller),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 24),
                onPressed: onPlayPause,
              ),
              IconButton(
                icon: Icon(controller.value.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white, size: 22),
                onPressed: onMute,
              ),
              TextButton(
                onPressed: onSpeed,
                child: Text('${controller.value.playbackSpeed.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 22), onPressed: onSnapshot),
              IconButton(icon: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 22), onPressed: onCut),
              IconButton(
                icon: Icon(isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                    color: Colors.white, size: 24),
                onPressed: onFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draggable progress bar: "01:23 ━━━●──── 05:00".
class _SeekBar extends StatefulWidget {
  final VideoPlayerController controller;

  const _SeekBar({required this.controller});

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  /// Position under the finger while dragging, in milliseconds.
  double? _dragMs;

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final totalMs = value.duration.inMilliseconds.toDouble();
        final max = totalMs > 0 ? totalMs : 1.0;
        final current = (_dragMs ?? value.position.inMilliseconds.toDouble()).clamp(0.0, max);
        const timeStyle = TextStyle(color: Colors.white, fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]);
        return Row(
          children: [
            const SizedBox(width: 8),
            Text(_fmt(Duration(milliseconds: current.round())), style: timeStyle),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.accent,
                  overlayColor: AppColors.accent.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: current,
                  max: max,
                  onChanged: totalMs > 0 ? (v) => setState(() => _dragMs = v) : null,
                  onChangeEnd: (v) async {
                    await widget.controller.seekTo(Duration(milliseconds: v.round()));
                    if (mounted) setState(() => _dragMs = null);
                  },
                ),
              ),
            ),
            Text(_fmt(value.duration), style: timeStyle),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}

// ── Source tabs (Cloud / SD card) ───────────────────────────────────────────

class _SourceTabs extends StatelessWidget {
  final _RecordingSource source;
  final ValueChanged<_RecordingSource> onChanged;

  const _SourceTabs({required this.source, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SourceTabItem(
            icon: Icons.cloud_outlined,
            label: 'Cloud',
            active: source == _RecordingSource.cloud,
            onTap: () => onChanged(_RecordingSource.cloud),
          ),
          const SizedBox(width: 36),
          _SourceTabItem(
            icon: Icons.sd_card_outlined,
            label: 'Thẻ nhớ'.tr,
            active: source == _RecordingSource.sdCard,
            onTap: () => onChanged(_RecordingSource.sdCard),
          ),
        ],
      ),
    );
  }
}

class _SourceTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SourceTabItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: color)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: active ? 20 : 0,
                height: 2.5,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date navigator ───────────────────────────────────────────────────────────

class _DateNav extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTapLabel;

  const _DateNav({required this.label, required this.onPrev, required this.onNext, required this.onTapLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppColors.cardRadius),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                    onPressed: onPrev,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: onTapLabel,
                      child: Center(
                        child: Text(label,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onPressed: onNext,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyRecordings extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyRecordings({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('Không có bản ghi'.tr,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Bật tự động ghi hình hoặc nhấn "Ghi hình"'.tr,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 16),
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

// ── Day timeline: vertical time axis + clip cards ──────────────────────────

class _DayTimeline extends StatelessWidget {
  final ScrollController scrollController;
  final List<RecordingFile> recordings;
  final RecordingFile? playing;
  final int? playingElapsedSeconds;
  final double pxPerMinute;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final ValueChanged<RecordingFile> onTapRecording;
  final ValueChanged<RecordingFile> onDeleteRecording;
  final ValueChanged<RecordingFile> onDownloadRecording;

  static const double _axisWidth = 52;
  static const double _spineGap = 14;
  static const double _cardHeight = 78;
  static const double _cardWidth = 168;

  const _DayTimeline({
    required this.scrollController,
    required this.recordings,
    required this.playing,
    required this.playingElapsedSeconds,
    required this.pxPerMinute,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onTapRecording,
    required this.onDeleteRecording,
    required this.onDownloadRecording,
  });

  double _yFor(int seconds) => seconds / 60 * pxPerMinute;

  int? get _selectedSeconds {
    final p = playing;
    if (p == null) return null;
    final start = p.startOfDaySeconds;
    if (start == null) return null;
    return start + (playingElapsedSeconds ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final totalHeight = _yFor(24 * 3600) + 40;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: SizedBox(
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 10-minute tick labels + spine
                  for (int m = 0; m <= 24 * 60; m += 10) _TimeTick(minute: m, y: _yFor(m * 60), axisWidth: _axisWidth),

                  // recorded-range highlight on the spine
                  for (final r in recordings)
                    if (r.startOfDaySeconds != null)
                      Positioned(
                        left: _axisWidth,
                        top: _yFor(r.startOfDaySeconds!),
                        width: 3,
                        height: (_yFor((r.durationSeconds ?? 60))).clamp(3, double.infinity),
                        child: DecoratedBox(decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.55))),
                      ),

                  // selected/playing position marker
                  if (_selectedSeconds != null) ...[
                    Positioned(
                      top: _yFor(_selectedSeconds!) - 1,
                      left: _axisWidth - 4,
                      child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.card, width: 2))),
                    ),
                    Positioned(
                      top: _yFor(_selectedSeconds!) - 11,
                      left: _axisWidth + _spineGap,
                      child: _SelectedTimeBadge(seconds: _selectedSeconds!),
                    ),
                  ],

                  // clip cards
                  for (final r in recordings)
                    if (r.startOfDaySeconds != null)
                      Positioned(
                        top: (_yFor(r.startOfDaySeconds!) - _cardHeight / 2).clamp(0, double.infinity),
                        left: _axisWidth + _spineGap + 78,
                        child: _RecordingCard(
                          recording: r,
                          width: _cardWidth,
                          height: _cardHeight,
                          isPlaying: playing?.id == r.id,
                          onTap: () => onTapRecording(r),
                          onDelete: () => onDeleteRecording(r),
                          onDownload: () => onDownloadRecording(r),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
        _ZoomControl(onZoomIn: onZoomIn, onZoomOut: onZoomOut),
      ],
    );
  }
}

class _TimeTick extends StatelessWidget {
  final int minute;
  final double y;
  final double axisWidth;
  const _TimeTick({required this.minute, required this.y, required this.axisWidth});

  @override
  Widget build(BuildContext context) {
    final h = (minute ~/ 60).toString().padLeft(2, '0');
    final m = (minute % 60).toString().padLeft(2, '0');
    return Positioned(
      top: y - 7,
      left: 0,
      width: axisWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$h:$m', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
          const SizedBox(width: 6),
          Container(width: 6, height: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}

class _SelectedTimeBadge extends StatelessWidget {
  final int seconds;
  const _SelectedTimeBadge({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
      child: Text('$h:$m:$s', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

String _startTimeLabel(RecordingFile recording) {
  final s = recording.startOfDaySeconds;
  if (s == null) return '--:--:--';
  final h = (s ~/ 3600).toString().padLeft(2, '0');
  final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
  final sec = (s % 60).toString().padLeft(2, '0');
  return '$h:$m:$sec';
}

class _RecordingCard extends StatelessWidget {
  final RecordingFile recording;
  final double width;
  final double height;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const _RecordingCard({
    required this.recording,
    required this.width,
    required this.height,
    required this.isPlaying,
    required this.onTap,
    required this.onDelete,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(recording.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onDownload,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isPlaying ? AppColors.accent : AppColors.border, width: isPlaying ? 1.6 : 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                    child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.mediaPlaceholderGradient))),
                Center(
                  child: Icon(
                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    color: Colors.white70,
                    size: 26,
                  ),
                ),
                Positioned(
                  left: 6,
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration:
                        BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _startTimeLabel(recording),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (recording.durationSeconds != null) ...[
                          const SizedBox(width: 4),
                          Text("${recording.durationSeconds}'",
                              style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ],
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

class _ZoomControl extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  const _ZoomControl({required this.onZoomIn, required this.onZoomOut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(icon: Icons.add_rounded, onTap: onZoomIn),
          const SizedBox(height: 8),
          _ZoomButton(icon: Icons.remove_rounded, onTap: onZoomOut),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
