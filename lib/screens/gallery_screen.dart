import '../utils/app_strings.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  Map<String, List<File>> _groupedFiles = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final galleryDir = Directory('${directory.path}/AQVision_Screenshots');
      if (!await galleryDir.exists()) {
        setState(() {
          _groupedFiles = {};
          _loading = false;
        });
        return;
      }

      final files = galleryDir.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified)); // Newest first

      final Map<String, List<File>> grouped = {};
      final dateFormat = DateFormat('yyyy-MM-dd');

      for (var file in files) {
        final stat = file.statSync();
        final dateKey = dateFormat.format(stat.modified);
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(file);
      }

      setState(() {
        _groupedFiles = grouped;
        _loading = false;
      });
    } catch (e) {
      print('Error loading images: $e');
      setState(() => _loading = false);
    }
  }

  void _openImageViewer(File file) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FullScreenImageViewer(
        file: file,
        onDeleted: () {
          _loadImages();
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Thư viện ảnh'.tr, style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _groupedFiles.isEmpty
              ? Center(
                  child: Text(
                    'Chưa có ảnh nào được lưu'.tr,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groupedFiles.keys.length,
                  itemBuilder: (context, index) {
                    final date = _groupedFiles.keys.elementAt(index);
                    final files = _groupedFiles[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            date,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: files.length,
                          itemBuilder: (context, imgIndex) {
                            final file = files[imgIndex];
                            return GestureDetector(
                              onTap: () => _openImageViewer(file),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final File file;
  final VoidCallback onDeleted;

  const FullScreenImageViewer({super.key, required this.file, required this.onDeleted});

  Future<void> _share(BuildContext context) async {
    final xfile = XFile(file.path);
    await Share.shareXFiles([xfile], text: 'Ảnh chụp từ hệ thống AQ-VISION'.tr);
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xoá ảnh?'.tr),
        content: Text('Ảnh này sẽ bị xoá vĩnh viễn khỏi thiết bị.'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Huỷ'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text('Xoá'.tr),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (file.existsSync()) {
        file.deleteSync();
      }
      onDeleted();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _share(context),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(file, fit: BoxFit.contain, gaplessPlayback: true),
        ),
      ),
    );
  }
}
