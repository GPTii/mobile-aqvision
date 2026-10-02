import '../config/api_config.dart';
import '../config/api_defaults.dart';
import '../data/camera_store.dart';
import '../utils/app_strings.dart';
import 'gateway_session.dart';

/// Outcome of [syncGatewayCamerasToCloud], for a one-line summary.
class CloudSyncResult {
  final List<String> created = [];
  final List<String> existing = [];
  final List<String> skipped = [];
  final Map<String, String> failed = {};

  String get summary {
    final parts = <String>[
      if (created.isNotEmpty) 'Đã thêm {n} camera vào app'.trArgs({'n': created.length}),
      if (existing.isNotEmpty) '{n} camera đã có sẵn'.trArgs({'n': existing.length}),
      if (skipped.isNotEmpty) '{n} camera đẩy sang server khác'.trArgs({'n': skipped.length}),
      if (failed.isNotEmpty)
        'Lỗi: {list}'.trArgs({'list': failed.entries.map((e) => '${e.key} (${e.value})').join(', ')}),
    ];
    return parts.isEmpty ? 'Không có camera nào để thêm.'.tr : parts.join(' · ');
  }
}

/// After cameras are saved on a gateway, create the matching cloud cameras so
/// they show up in the app right away (live view, recording) — nothing to type.
///
/// The gateway pushes each camera to our media server (auto-push, README_BLE
/// §9) at `rtsp://<mediaIngestHost>:1936/<path>`; the cloud camera pulls the
/// same path from the server's local ingest (`mediaIngestInternal/<path>`)
/// under `live/<stream>`. Cameras pushed elsewhere are skipped: the cloud
/// cannot pull those.
Future<CloudSyncResult> syncGatewayCamerasToCloud(GatewaySession session, {Iterable<String>? onlyMounts}) async {
  final result = CloudSyncResult();

  // mount -> push target. Older gateways have no /api/rtsp/autopush: only
  // their manual outputs push, so use exactly those (never guess a path that
  // nothing publishes to — the cloud camera would stay offline).
  final targets = <String, String>{};
  try {
    final auto = await session.autopush();
    for (final c in (auto['cameras'] as List? ?? const []).cast<Map>()) {
      if (c['push'] == true && c['camera_enabled'] != false && auto['enabled'] == true) {
        targets['${c['mount']}'] = '${c['target']}';
      }
    }
  } catch (_) {
    for (final o in await session.outputs()) {
      if (o['enabled'] != false && o['camera'] != null) {
        targets.putIfAbsent('${o['camera']}', () => '${o['url']}');
      }
    }
  }
  if (onlyMounts != null) {
    final keep = onlyMounts.toSet();
    targets.removeWhere((m, _) => !keep.contains(m));
  }

  await CameraStore.instance.fetchCameras();
  final existingCodes = {for (final c in CameraStore.instance.cameras) c.cameraCode};
  final existingUrls = {for (final c in CameraStore.instance.cameras) (c.targetUrl ?? '').trim()};

  for (final MapEntry(key: mount, value: target) in targets.entries) {
    final uri = Uri.tryParse(target);
    final path = (uri?.path ?? '').replaceFirst(RegExp(r'^/+'), '');
    if (uri == null ||
        uri.scheme != 'rtsp' ||
        (uri.host != ApiDefaults.mediaIngestHost && uri.host != ApiConfig.mediaIngestHost) ||
        path.isEmpty ||
        path.contains('***')) {
      result.skipped.add(mount);
      continue;
    }
    final url = '${ApiDefaults.mediaIngestInternal}/$path';
    // Stream names are unique server-wide: use the path's last segment.
    final stream = path.split('/').last;
    if (existingCodes.contains(stream) || existingUrls.contains(url)) {
      result.existing.add(mount);
      continue;
    }
    try {
      await CameraStore.instance.addCamera(
        name: stream,
        cameraCode: stream,
        type: kCameraTypes.first,
        ipAddress: url,
        location: '',
        groupIds: const [],
      );
      result.created.add(mount);
    } catch (e) {
      final msg = '$e'.replaceFirst('Exception: ', '');
      // Not in our list but taken server-wide: another account's camera uses
      // this stream name. Fix on the gateway with a {gateway_id}_{mount} URL.
      result.failed[mount] = msg.contains('đã tồn tại')
          ? 'Tên luồng "{stream}" đã được tài khoản khác dùng'.trArgs({'stream': stream})
          : msg;
    }
  }
  return result;
}
