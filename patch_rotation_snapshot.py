import re

def main():
    file_path = "lib/screens/home/record_list_screen.dart"
    with open(file_path, "r") as f:
        content = f.read()

    # 1. Add missing imports
    if "import 'package:flutter/services.dart';" not in content:
        content = "import 'package:flutter/services.dart';\n" + content
    if "import 'package:image_gallery_saver/image_gallery_saver.dart';" not in content:
        content = "import 'package:image_gallery_saver/image_gallery_saver.dart';\n" + content
    if "import 'dart:typed_data';" not in content:
        content = "import 'dart:typed_data';\n" + content

    # 2. Update _takeSnapshot
    old_snapshot = """  Future<void> _takeSnapshot() async {
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
  }"""
  
    new_snapshot = """  Future<void> _takeSnapshot() async {
    try {
      _showSnack('Đang xử lý ảnh chụp...', error: false);
      final boundary = _videoKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: "snapshot_${DateTime.now().millisecondsSinceEpoch}"
      );
      
      if (result != null && result['isSuccess'] == true) {
        _showSnack('Đã lưu ảnh vào Thư viện!', error: false);
      } else {
        _showSnack('Lưu ảnh thất bại.', error: true);
      }
    } catch (e) {
      _showSnack('Lỗi chụp ảnh: $e', error: true);
    }
  }"""
    content = content.replace(old_snapshot, new_snapshot)
    
    # 3. Update _toggleFullscreen
    old_fullscreen = """  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }"""
    
    new_fullscreen = """  void _toggleFullscreen() {
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
  
  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    widget.controller.removeListener(_listener);
    super.dispose();
  }"""
    content = content.replace(old_fullscreen, new_fullscreen)
    
    # Wait, the dispose method is actually part of _TimelineScrubberState. 
    # Let me fix that. The _toggleFullscreen is in _RecordingListScreenState.
    # Let's override dispose in _RecordingListScreenState carefully.
    
    old_dispose = """  @override
  void dispose() {
    _vpController?.dispose();
    super.dispose();
  }"""
  
    new_dispose = """  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _vpController?.dispose();
    super.dispose();
  }"""
    content = content.replace(old_dispose, new_dispose)
    
    # Remove the bad dispose from my new_fullscreen variable
    new_fullscreen_fixed = """  void _toggleFullscreen() {
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
  }"""
    content = content.replace(new_fullscreen, new_fullscreen_fixed)
    
    # 4. Remove record button and _toggleVideoRecord
    record_fn = """
  Future<void> _toggleVideoRecord() async {
    _showSnack('Tính năng ghi hình trực tiếp đang phát triển.');
  }
"""
    content = content.replace(record_fn, "")
    
    record_btn = """                                  // Record
                                  IconButton(
                                    icon: const Icon(Icons.videocam_outlined, color: Colors.white, size: 28),
                                    onPressed: _toggleVideoRecord,
                                  ),"""
    content = content.replace(record_btn, "")
    
    # Fix the timeline custom paint size if it's landscape? 
    # If landscape, the timeline will just be wider, which CustomPainter handles perfectly because it uses size.width.

    with open(file_path, "w") as f:
        f.write(content)

if __name__ == "__main__":
    main()
