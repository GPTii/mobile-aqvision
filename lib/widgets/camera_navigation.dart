import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/camera_store.dart';
import '../data/video_preload_cache.dart';
import '../screens/home/camera_detail_screen.dart';

/// Open camera detail with a warm HLS controller already pinned for instant play.
Future<void> openCameraDetail(BuildContext context, String cameraId) async {
  final camera = CameraStore.instance.cameraById(cameraId);
  final url = camera?.hlsUrl ?? '';
  final cache = VideoPreloadCache.instance;

  cache.pin(cameraId);
  if (url.isNotEmpty) {
    // Kick warm if grid hasn't finished init yet — don't await navigation.
    cache.warm(cameraId, url);
  }

  AppState.isVideoGridActive.value = false;
  cache.disposeUnpinned();

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CameraDetailScreen(cameraId: cameraId),
    ),
  );

  cache.unpin(cameraId);
  AppState.isVideoGridActive.value = true;
}

/// After camera list loads, warm the first online streams for snappy open.
void preloadVisibleCameras({int limit = 6}) {
  final items = CameraStore.instance.cameras
      .where((c) => c.online && (c.hlsUrl?.isNotEmpty ?? false))
      .take(limit)
      .map((c) => (id: c.id, url: c.hlsUrl!));
  VideoPreloadCache.instance.warmMany(items);
}
