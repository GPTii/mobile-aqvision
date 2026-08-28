import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../core/commadesk_api.dart';
import 'debounced_notifier.dart';
import 'video_preload_cache.dart';
import '../utils/network_error_handler.dart';
import 'notification_store.dart';

const kCameraTypes = [
  'Camera Dome',
  'Camera thân trụ',
  'Camera PTZ xoay',
  'Camera mini Wifi',
];

class CameraGroup {
  final String id;
  String name;
  final List<String> cameraIds;

  CameraGroup({
    required this.id,
    required this.name,
    this.cameraIds = const [],
  });
}

class Camera {
  final String id;
  String name;
  String cameraCode;
  String type;
  String ipAddress;
  String location;
  List<String> groupIds;
  bool online;
  String resolution;
  bool recording;
  final String lastSeen;

  String? app;
  String? hlsUrl;
  String? fmp4Url;
  String? targetUrl;
  String? playProtocol;
  String? mediaServerRef;

  Camera({
    required this.id,
    required this.name,
    required this.cameraCode,
    required this.type,
    required this.ipAddress,
    required this.location,
    required this.groupIds,
    this.online = true,
    this.resolution = '1080p',
    this.recording = false,
    this.lastSeen = '--:--',
    this.app,
    this.hlsUrl,
    this.fmp4Url,
    this.targetUrl,
    this.playProtocol,
    this.mediaServerRef,
  });
}

class CameraStore extends ChangeNotifier with DebouncedNotify {
  static final CameraStore instance = CameraStore._();

  final List<CameraGroup> _groups = [];
  List<Camera> _cameras = [];
  Timer? _pollTimer;

  final ValueNotifier<int> statusEpoch = ValueNotifier(0);
  final IdListenables _cameraTicks = IdListenables();

  CameraStore._();

  List<CameraGroup> get groups => List.unmodifiable(_groups);
  List<Camera> get cameras => List.unmodifiable(_cameras);

  int get onlineCount => _cameras.where((c) => c.online).length;

  Listenable cameraListenable(String cameraId) => _cameraTicks.of(cameraId);
  Listenable get listAndStatus => Listenable.merge([this, statusEpoch]);

  List<Camera> camerasInGroup(String groupId) =>
      _cameras.where((c) => c.groupIds.contains(groupId)).toList();

  CameraGroup? groupById(String id) {
    for (final group in _groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  Camera? cameraById(String id) {
    for (final camera in _cameras) {
      if (camera.id == id) return camera;
    }
    return null;
  }

  void _bumpStatus(String cameraId) {
    _cameraTicks.bump(cameraId);
    statusEpoch.value++;
  }

  void setRecordingFlag(String cameraId, bool value) {
    final cam = cameraById(cameraId);
    if (cam == null || cam.recording == value) return;
    cam.recording = value;
    _bumpStatus(cameraId);
  }

  Map<String, List<String>> _groupMembershipFromGroups() {
    final out = <String, List<String>>{};
    for (final g in _groups) {
      for (final camId in g.cameraIds) {
        out.putIfAbsent(camId, () => []).add(g.id);
      }
    }
    return out;
  }

  bool _isOnlineStatus(String? status) {
    final s = (status ?? '').trim().toLowerCase();
    return s == 'online' || s == 'active' || s == 'running';
  }

  Future<void> fetchGroups() async {
    dynamic raw;
    try {
      raw = await CommaDeskApi.instance.getJson('/me/camera-groups');
    } catch (_) {
      raw = await CommaDeskApi.instance.getJson('/camera-groups');
    }

    final list = CommaDeskApi.asMapList(CommaDeskApi.unwrapBody(raw));
    _groups.clear();
    for (final item in list) {
      final idsRaw = item['camera_ids'];
      final cameraIds = idsRaw is List
          ? idsRaw.map((e) => e.toString()).toList()
          : <String>[];
      _groups.add(CameraGroup(
        id: item['id']?.toString() ?? '',
        name: item['name']?.toString() ?? 'Nhóm',
        cameraIds: cameraIds,
      ));
    }
    notifyNow();
  }

  Future<void> fetchCameras() async {
    dynamic raw;
    try {
      raw = await CommaDeskApi.instance.getJson('/me/cameras');
    } catch (_) {
      try {
        raw = await CommaDeskApi.instance.getJson('/cameras');
      } on SocketException catch (_) {
        showNetworkErrorDialog();
        return;
      } on TimeoutException catch (_) {
        showNetworkErrorDialog();
        return;
      } catch (_) {
        return;
      }
    }

    List<Map<String, dynamic>> list;
    final unwrapped = CommaDeskApi.unwrapBody(raw);
    if (unwrapped is List) {
      list = CommaDeskApi.asMapList(unwrapped);
    } else {
      list = CommaDeskApi.asMapList(unwrapped);
    }

    final token = await CommaDeskApi.instance.readAccessToken();
    final membership = _groupMembershipFromGroups();

    _cameras = list.map((item) {
      final app = (item['stream_app'] ?? 'live').toString();
      final stream = (item['stream_name'] ?? item['name'] ?? 'cam').toString();
      final id = item['id']?.toString() ?? '';
      final rtsp = item['rtsp_url']?.toString() ?? '';
      final streamType = (item['stream_type'] ?? 'rtsp').toString();

      String hlsUrl;
      String fmp4Url;
      if (streamType == 'hls' && rtsp.contains('.m3u8')) {
        hlsUrl = rtsp;
        fmp4Url = rtsp.replaceAll('/hls.m3u8', '.live.mp4');
      } else {
        hlsUrl = ApiConfig.buildHlsUrl(
          app: app,
          stream: stream,
          accessToken: token,
        );
        fmp4Url = ApiConfig.buildFmp4Url(
          app: app,
          stream: stream,
          accessToken: token,
        );
      }

      return Camera(
        id: id,
        name: item['name']?.toString() ?? stream,
        cameraCode: stream,
        type: kCameraTypes[0],
        ipAddress: rtsp,
        location: item['store_id']?.toString() ?? 'Góc camera',
        groupIds: membership[id] ?? const [],
        online: _isOnlineStatus(item['status']?.toString()),
        resolution: '1080p',
        recording: false,
        lastSeen: 'Vừa mới',
        app: app,
        hlsUrl: hlsUrl,
        fmp4Url: fmp4Url,
        targetUrl: rtsp,
        playProtocol: streamType,
        mediaServerRef: item['media_server_ref']?.toString(),
      );
    }).toList();

    notifyNow();
    statusEpoch.value++;

    Future.microtask(() {
      final items = _cameras
          .where((c) => c.online && (c.hlsUrl?.isNotEmpty ?? false))
          .take(VideoPreloadCache.maxWarm)
          .map((c) => (id: c.id, url: c.hlsUrl!));
      VideoPreloadCache.instance.warmMany(items);
    });
  }

  String suggestCameraCode() => 'cam1';
  String suggestIpAddress() => 'rtsp://';

  Future<CameraGroup> addGroup(String name) async {
    final raw = await CommaDeskApi.instance.postJson(
      '/camera-groups',
      body: {'name': name.trim()},
    );
    final data = CommaDeskApi.unwrapBody(raw);
    if (data is! Map) throw Exception('Phản hồi nhóm không hợp lệ');
    final map = Map<String, dynamic>.from(data);
    final group = CameraGroup(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? name.trim(),
    );
    _groups.add(group);
    notifyNow();
    return group;
  }

  Future<void> renameGroup(String groupId, String newName) async {
    final group = groupById(groupId);
    if (group == null || newName.trim().isEmpty) return;
    await CommaDeskApi.instance.put(
      '/camera-groups/$groupId',
      body: {'name': newName.trim()},
    );
    group.name = newName.trim();
    notifyNow();
  }

  Future<void> deleteGroup(String groupId) async {
    await CommaDeskApi.instance.delete('/camera-groups/$groupId');
    _groups.removeWhere((g) => g.id == groupId);
    await fetchCameras();
  }

  Future<Camera> addCamera({
    required String name,
    required List<String> groupIds,
    required String cameraCode,
    required String type,
    required String ipAddress,
    required String location,
    String resolution = '1080p',
    bool online = true,
    bool recording = false,
    String lastSeen = 'Vừa thêm',
  }) async {
    await CommaDeskApi.instance.postJson(
      '/cameras',
      body: {
        'name': name.trim().isNotEmpty ? name.trim() : cameraCode,
        'rtsp_url': ipAddress,
        'stream_app': 'live',
        'stream_name': cameraCode,
        if (groupIds.isNotEmpty) 'camera_group_ids': groupIds,
      },
    );
    await fetchGroups();
    await fetchCameras();
    return _cameras.firstWhere(
      (c) => c.cameraCode == cameraCode,
      orElse: () => _cameras.last,
    );
  }

  Future<void> updateCamera(
    String cameraId, {
    String? name,
    List<String>? groupIds,
    String? cameraCode,
    String? type,
    String? ipAddress,
    String? location,
    String? resolution,
    bool? online,
    bool? recording,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
    if (cameraCode != null) body['stream_name'] = cameraCode;
    if (ipAddress != null) body['rtsp_url'] = ipAddress;

    await CommaDeskApi.instance.put('/cameras/$cameraId', body: body);

    if (groupIds != null && groupIds.isNotEmpty) {
      for (final gid in groupIds) {
        await CommaDeskApi.instance.put(
          '/camera-groups/$gid/cameras',
          body: {'camera_ids': [cameraId]},
        );
      }
    }

    await fetchGroups();
    await fetchCameras();
  }

  Future<void> deleteCamera(String cameraId) async {
    final res = await CommaDeskApi.instance.delete('/cameras/$cameraId');
    if (res.statusCode == 200 || res.statusCode == 204) {
      _cameras.removeWhere((c) => c.id == cameraId);
      notifyNow();
    } else {
      throw Exception(CommaDeskApi.messageFromResponse(res));
    }
  }

  Future<void> toggleConnection(String cameraId) async {
    final camera = cameraById(cameraId);
    if (camera == null) throw Exception('Không tìm thấy camera');

    final nextStatus = camera.online ? 'offline' : 'online';
    final res = await CommaDeskApi.instance.put(
      '/cameras/$cameraId/status',
      body: {'status': nextStatus},
    );

    if (res.statusCode == 200) {
      camera.online = nextStatus == 'online';
      _bumpStatus(cameraId);
      NotificationStore.instance.fetchAlerts();
    } else {
      throw Exception(CommaDeskApi.messageFromResponse(res));
    }
  }

  /// Poll camera list periodically (CommaDesk has no proxy-status SSE).
  Future<void> connectRealtime() async {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchCameras();
    });
  }

  void disconnectRealtime() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
