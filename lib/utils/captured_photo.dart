import 'app_strings.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_colors.dart';

class CapturedPhoto {
  static Future<Uint8List> capture(GlobalKey repaintBoundaryKey) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Không tìm thấy khung hình camera'.tr);
    }

    final devicePixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final image = await boundary.toImage(
      pixelRatio: devicePixelRatio.clamp(1.0, 3.0),
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Không thể tạo ảnh chụp'.tr);
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  static Future<String> saveToLocalAppStorage(Uint8List bytes) async {
    if (kIsWeb) {
      throw UnsupportedError('Thiết bị này chưa hỗ trợ lưu trữ cục bộ'.tr);
    }
    final directory = await getApplicationDocumentsDirectory();
    final galleryDir = Directory('${directory.path}/AQVision_Screenshots');
    if (!await galleryDir.exists()) {
      await galleryDir.create(recursive: true);
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final filePath = '${galleryDir.path}/AQVision_$timestamp.png';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
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
      await CapturedPhoto.saveToLocalAppStorage(widget.bytes);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Không thể lưu ảnh cục bộ: '.tr + error.toString();
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
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.photo_camera_rounded, size: 22),
                SizedBox(width: 10),
                Text(
                  'Ảnh vừa chụp'.tr,
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
                style: TextStyle(color: AppColors.danger, fontSize: 12),
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
                    label: Text('Xóa'.tr),
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
                    label: Text(_saving ? 'Đang lưu...'.tr : 'Lưu'.tr),
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
