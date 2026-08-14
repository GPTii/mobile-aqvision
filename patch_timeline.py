import re

def main():
    file_path = "lib/screens/home/record_list_screen.dart"
    with open(file_path, "r") as f:
        content = f.read()

    # 1. Replace _VideoSlider class with _TimelineScrubber
    
    scrubber_code = """class _TimelineScrubber extends StatefulWidget {
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
"""
    
    # Remove old _VideoSlider
    start_idx = content.find("class _VideoSlider extends StatefulWidget {")
    if start_idx != -1:
        content = content[:start_idx]
        
    content += "\n" + scrubber_code

    # 2. Add dependencies and overlay controls in the build method
    # We need dart:ui and rendering
    if "import 'dart:ui' as ui;" not in content:
        content = "import 'dart:ui' as ui;\nimport 'dart:io';\nimport 'package:flutter/rendering.dart';\n" + content

    # Add a GlobalKey for RepaintBoundary
    if "final GlobalKey _videoKey = GlobalKey();" not in content:
        content = content.replace("class _RecordingListScreenState extends State<RecordingListScreen> {", 
                                  "class _RecordingListScreenState extends State<RecordingListScreen> {\n  final GlobalKey _videoKey = GlobalKey();\n  bool _isFullscreen = false;")

    # Add snapshot function
    snapshot_fn = """
  Future<void> _takeSnapshot() async {
    try {
      final boundary = _videoKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      // In a real app we'd save it to gallery, here we just show a snackbar
      _showSnack('Đã chụp ảnh màn hình thành công!', error: false);
    } catch (e) {
      _showSnack('Lỗi chụp ảnh: $e', error: true);
    }
  }

  Future<void> _toggleVideoRecord() async {
    _showSnack('Tính năng ghi hình trực tiếp đang phát triển.');
  }
  
  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }
"""
    if "Future<void> _takeSnapshot() async {" not in content:
        content = content.replace("Future<void> _changeSpeed() async {", snapshot_fn + "\n  Future<void> _changeSpeed() async {")

    # Now replace the stack with video player overlay
    old_stack = """                          VideoPlayer(_vpController!),
                          _VideoSlider(controller: _vpController!),
                          Positioned(
                            top: 6,
                            right: 6,"""
                            
    new_stack = """                          RepaintBoundary(
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
                                  // Record
                                  IconButton(
                                    icon: const Icon(Icons.videocam_outlined, color: Colors.white, size: 28),
                                    onPressed: _toggleVideoRecord,
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
                            right: 6,"""
                            
    content = content.replace(old_stack, new_stack)
    
    # Also we need to put the Scrubber below the video player.
    # We will remove the Advanced Controls section and put _TimelineScrubber instead.
    
    old_controls = """                // Advanced Controls
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
                  ),"""
                  
    new_controls = """                // Scrubber PA2
                if (_vpController != null && _vpController!.value.isInitialized)
                  _TimelineScrubber(controller: _vpController!),"""
                  
    content = content.replace(old_controls, new_controls)
    
    # Let's add Fullscreen wrapper. If _isFullscreen is true, we should probably hide the rest of the UI.
    # To do this safely, we can just conditionally render the List and Header if !_isFullscreen.
    
    header_regex = r"(// Header\s+DecoratedBox\([\s\S]*?)(// Video Player \(when playing\))"
    match = re.search(header_regex, content)
    if match:
        header_code = match.group(1)
        content = content.replace(header_code, "if (!_isFullscreen)\n                  " + header_code.replace("\n", "\n                  ") + "\n                ")

    list_regex = r"(// List\s+Expanded\([\s\S]*?\),)"
    match = re.search(list_regex, content)
    if match:
        list_code = match.group(1)
        content = content.replace(list_code, "if (!_isFullscreen)\n                  " + list_code.replace("\n", "\n                  "))
        
    with open(file_path, "w") as f:
        f.write(content)

if __name__ == "__main__":
    main()
