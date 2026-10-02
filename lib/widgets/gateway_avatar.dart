import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/gateway_image_store.dart';
import '../data/gateway_store.dart';
import '../theme/app_colors.dart';
import '../utils/app_strings.dart';

/// Gateway photo: the user's pick, else the AQPTech product photo.
class GatewayAvatar extends StatelessWidget {
  final SavedGateway gateway;
  final double size;
  final double radius;

  const GatewayAvatar({super.key, required this.gateway, this.size = 56, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GatewayImageStore.instance,
      builder: (context, _) {
        final path = GatewayImageStore.instance.custom(gateway.id) ??
            GatewayImageStore.defaultAsset(gateway.id, gateway.name);
        final fallback = Image.asset(
          GatewayImageStore.defaultAsset(gateway.id, gateway.name),
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: path.startsWith('assets/')
              ? Image.asset(path, width: size, height: size, fit: BoxFit.cover, filterQuality: FilterQuality.high)
              : Image.file(
                  File(path),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => fallback,
                ),
        );
      },
    );
  }
}

/// "Đổi ảnh gateway": gallery, camera, the two product photos, or default.
Future<void> showGatewayImageSheet(BuildContext context, SavedGateway gateway) async {
  final store = GatewayImageStore.instance;
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      Widget sample(String asset, String label) => Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(ctx, asset),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.asset(asset, fit: BoxFit.cover, filterQuality: FilterQuality.high),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(label, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
          );

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Text('Ảnh gateway'.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  sample(GatewayImageStore.companyAsset, 'Gateway Công ty'.tr),
                  const SizedBox(width: 12),
                  sample(GatewayImageStore.trafficAsset, 'Gateway Giao thông'.tr),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.photo_library_outlined, color: AppColors.accent),
                title: Text('Chọn từ thư viện'.tr),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.photo_camera_outlined, color: AppColors.accent),
                title: Text('Chụp ảnh'.tr),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              if (store.custom(gateway.id) != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.restart_alt_rounded, color: AppColors.textMuted),
                  title: Text('Dùng ảnh mặc định'.tr),
                  onTap: () => Navigator.pop(ctx, 'reset'),
                ),
            ],
          ),
        ),
      );
    },
  );
  if (choice == null || !context.mounted) return;

  try {
    switch (choice) {
      case 'reset':
        await store.reset(gateway.id);
      case 'gallery' || 'camera':
        final camera = choice == 'camera';
        // CAMERA is declared in the manifest (QR scan), so Android needs it granted first.
        if (camera && !(await Permission.camera.request()).isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Chưa cấp quyền Camera'.tr)));
          }
          return;
        }
        final picked = await ImagePicker().pickImage(
          source: camera ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 90,
        );
        if (picked != null) await store.setFile(gateway.id, picked.path);
      default:
        await store.setAsset(gateway.id, choice);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không đổi được ảnh: {e}'.trArgs({'e': e}))));
    }
  }
}
