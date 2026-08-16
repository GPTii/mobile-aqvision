import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class CapturedPhoto {
  static const MethodChannel _channel = MethodChannel('aqvision/photo_library');

  static Future<Uint8List> capture(GlobalKey repaintBoundaryKey) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Không tìm thấy khung hình camera');
    }

    final devicePixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final image = await boundary.toImage(
      pixelRatio: devicePixelRatio.clamp(1.0, 3.0),
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Không thể tạo ảnh chụp');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  static Future<String> saveToPhotos(Uint8List bytes) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Thiết bị này chưa hỗ trợ lưu vào Photos');
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final path = await _channel.invokeMethod<String>('saveImage', {
      'bytes': bytes,
      'fileName': 'AQVision_$timestamp.png',
    });
    if (path == null || path.isEmpty) {
      throw StateError('Photos không trả về vị trí ảnh đã lưu');
    }
    return path;
  }

  static Future<bool> showPreviewAndSave(
    BuildContext context,
    Uint8List bytes,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _CapturedPhotoDialog(bytes: bytes),
        ) ??
        false;
  }
}

class _CapturedPhotoDialog extends StatefulWidget {
  final Uint8List bytes;

  const _CapturedPhotoDialog({required this.bytes});

  @override
  State<_CapturedPhotoDialog> createState() => _CapturedPhotoDialogState();
}

class _CapturedPhotoDialogState extends State<_CapturedPhotoDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await CapturedPhoto.saveToPhotos(widget.bytes);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Không thể lưu ảnh vào Photos: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.photo_camera_rounded, size: 22),
                SizedBox(width: 10),
                Text(
                  'Ảnh vừa chụp',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Flexible(
            child: ColoredBox(
              color: Colors.black,
              child: Image.memory(
                widget.bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Xóa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_alt_rounded),
                    label: Text(_saving ? 'Đang lưu...' : 'Lưu'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}