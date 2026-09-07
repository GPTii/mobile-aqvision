import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'debounced_notifier.dart';
import 'video_preload_cache.dart';
import '../utils/network_error_handler.dart';
import 'notification_store.dart';
import '../utils/app_strings.dart';

List<String> get kCameraTypes => [
  'Camera Dome',
  'Camera thân trụ'.tr,
  'Camera PTZ xoay',
  'Camera mini Wifi',
];

class CameraGroup {
  final String id;
  String name;

  CameraGroup({required this.id, required this.name});
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

  // API specific fields
  String? app;
  String? hlsUrl;
  String? fmp4Url;
  String? targetUrl;
  String? playProtocol;
  String? mapLink;

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
    this.mapLink,
  });
}

class CameraStore extends ChangeNotifier with DebouncedNotify {
  static final CameraStore instance = CameraStore._();

  final List<CameraGroup> _groups = [];
  List<Camera> _cameras = [];
  http.Client? _sseClient;

  /// Online / recording flag flips only — does not rebuild list structure.
  final ValueNotifier<int> statusEpoch = ValueNotifier(0);
  final IdListenables _cameraTicks = IdListenables();

  CameraStore._();

  List<CameraGroup> get groups => List.unmodifiable(_groups);
  List<Camera> get cameras => List.unmodifiable(_cameras);

  int get onlineCount => _cameras.where((c) => c.online).length;

  /// Listen for one camera's status/metadata ticks (SSE, toggle, recording flag).
  Listenable cameraListenable(String cameraId) => _cameraTicks.of(cameraId);

  /// Structure + status (headers that show online counts).
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

  /// Update local `recording` flag without a full proxies refetch.
  void setRecordingFlag(String cameraId, bool value) {
    final cam = cameraById(cameraId);
    if (cam == null || cam.recording == value) return;
    cam.recording = value;
    _bumpStatus(cameraId);
  }

  String get _baseUrl => ApiConfig.apiBase;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchGroups() async {
    final token = await _getToken();
    if (token == null) return;

    final uri = Uri.parse('$_baseUrl/groups');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];
      _groups.clear();
      for (final item in data) {
        _groups.add(CameraGroup(
          id: item['id'].toString(),
          name: item['name'] ?? 'Nhóm'.tr,
        ));
      }
      notifyNow();
    }
  }

  Future<void> fetchCameras() async {
    final token = await _getToken();
    if (token == null) return;

    final uri = Uri.parse('$_baseUrl/proxies');
    http.Response res;
    try {
      res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));
    } on SocketException catch (_) {
      showNetworkErrorDialog();
      return;
    } on TimeoutException catch (_) {
      showNetworkErrorDialog();
      return;
    } catch (_) {
      return;
    }

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json['data'] ?? [];

      final mediaBaseUrl = ApiConfig.mediaBase;

      _cameras = data.map((item) {
        final app = item['app'] ?? 'live';
        final stream = item['stream'] ?? 'cam';
        final itemUrl = (item['url'] ?? '').toString().trim();

        String hlsUrl = '';
        String fmp4Url = '';
        if (itemUrl.contains('.m3u8') || itemUrl.startsWith('http')) {
          hlsUrl = itemUrl;
          fmp4Url = itemUrl.replaceAll('/hls.m3u8', '.live.mp4'); // Fallback logic
        } else {
          hlsUrl = '$mediaBaseUrl/$app/$stream/hls.m3u8?access_token=$token';
          fmp4Url = '$mediaBaseUrl/$app/$stream.live.mp4?access_token=$token';
        }

        return Camera(
          id: (item['id'] ?? 0).toString(),
          name: item['stream'] ?? 'Camera',
          cameraCode: item['stream'] ?? 'CAM-0000',
          type: item['cameraType'] ?? kCameraTypes[0],
          ipAddress: item['url'] ?? '',
          location: item['location'] ?? 'Chưa xác định'.tr,
          groupIds: (item['groupIds'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          online: item['status'] == 'Online',
          resolution: '1080p',
          recording: item['enableMp4'] == true,
          lastSeen: 'Vừa mới'.tr,
          app: app,
          hlsUrl: hlsUrl,
          fmp4Url: fmp4Url,
          targetUrl: item['url'],
          playProtocol: item['playProtocol'],
          mapLink: item['mapLink'],
        );
      }).toList();
      notifyNow();
      statusEpoch.value++;
      // Warm first online streams so detail opens without HLS cold-start.
      Future.microtask(() {
        final items = _cameras
            .where((c) => c.online && (c.hlsUrl?.isNotEmpty ?? false))
            .take(VideoPreloadCache.maxWarm)
            .map((c) => (id: c.id, url: c.hlsUrl!));
        VideoPreloadCache.instance.warmMany(items);
      });
    }
  }

  String suggestCameraCode() => 'live';
  String suggestIpAddress() => 'rtsp://';

  Future<CameraGroup> addGroup(String name) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final uri = Uri.parse('$_baseUrl/groups');
    final res = await http.post(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }, body: jsonEncode({'name': name.trim()}));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final json = jsonDecode(res.body);
      final data = json['data'];
      final group = CameraGroup(id: data['id'].toString(), name: data['name']);
      _groups.add(group);
      notifyNow();
      return group;
    } else {
      final json = jsonDecode(res.body);
      throw Exception(json['error'] ?? 'Lỗi thêm nhóm'.tr);
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    final group = groupById(groupId);
    if (group == null || newName.trim().isEmpty) return;
    group.name = newName.trim();
    notifyNow();
  }

  Future<void> deleteGroup(String groupId) async {
    final token = await _getToken();
    if (token == null) return;

    final uri = Uri.parse('$_baseUrl/groups/$groupId');
    await http.delete(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    _groups.removeWhere((g) => g.id == groupId);
    await fetchCameras(); // notifies once after cameras refresh
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
    String? lastSeen,
  }) async {
    lastSeen ??= 'Vừa thêm'.tr;
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/proxies');
    final res = await http.post(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }, body: jsonEncode({
      'app': 'live',
      'stream': cameraCode,
      'url': ipAddress,
      'groupIds': groupIds.map((id) => int.tryParse(id) ?? 0).toList(),
      'enableHls': true,
      'enableMp4': recording,
    }));

    if (res.statusCode == 200 || res.statusCode == 201) {
      await fetchCameras();
      return _cameras.firstWhere(
        (c) => c.cameraCode == cameraCode,
        orElse: () => _cameras.last,
      );
    } else {
      final json = jsonDecode(res.body);
      throw Exception(json['error'] ?? 'Lỗi thêm camera'.tr);
    }
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
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/proxies/$cameraId');

    final res = await http.patch(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }, body: jsonEncode({
      if (cameraCode != null) 'stream': cameraCode,
      if (ipAddress != null) 'url': ipAddress,
      if (groupIds != null)
        'groupIds': groupIds.map((id) => int.tryParse(id) ?? 0).toList(),
      if (recording != null) 'enableMp4': recording,
    }));

    if (res.statusCode == 200) {
      await fetchCameras();
    } else {
      throw Exception('Lỗi cập nhật camera'.tr);
    }
  }

  Future<void> deleteCamera(String cameraId) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/proxies/$cameraId');
    final res = await http.delete(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (res.statusCode == 200) {
      _cameras.removeWhere((c) => c.id == cameraId);
      notifyNow();
    } else {
      throw Exception('Lỗi xóa camera'.tr);
    }
  }

  /// Toggle camera connection (reconnect / disconnect).
  Future<void> toggleConnection(String cameraId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final camera = cameraById(cameraId);
    if (camera == null) throw Exception('Camera not found');

    final action = camera.online ? 'disconnect' : 'reconnect';
    final uri = Uri.parse('$_baseUrl/proxies/$cameraId');
    final res = await http.put(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }, body: jsonEncode({'action': action}));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final data = json['data'];
      if (data != null && data['status'] != null) {
        camera.online = data['status'] == 'Online';
      } else {
        camera.online = !camera.online;
      }
      _bumpStatus(cameraId);
      NotificationStore.instance.fetchAlerts();
    } else {
      throw Exception(
          'Lỗi khi ${action == 'disconnect' ? 'ngắt kết nối'.tr : 'kết nối lại'.tr} camera');
    }
  }

  Future<void> connectRealtime() async {
    final token = await _getToken();
    if (token == null) return;

    _sseClient?.close();
    _sseClient = http.Client();

    try {
      final req = http.Request('GET', Uri.parse('$_baseUrl/v1/realtime'));
      req.headers['Authorization'] = 'Bearer $token';

      final res = await _sseClient!.send(req);

      res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6);
          try {
            final data = jsonDecode(dataStr);
            if (data['id'] != null && data['status'] != null) {
              final cam = cameraById(data['id'].toString());
              if (cam != null) {
                final online = data['status'] == 'Online';
                if (cam.online != online) {
                  cam.online = online;
                  _bumpStatus(cam.id);
                }
              }
            }
          } catch (_) {}
        }
      }, onError: (_) {
        Future.delayed(const Duration(seconds: 5), connectRealtime);
      }, onDone: () {
        Future.delayed(const Duration(seconds: 5), connectRealtime);
      });
    } catch (e) {
      Future.delayed(const Duration(seconds: 5), connectRealtime);
    }
  }

  void disconnectRealtime() {
    _sseClient?.close();
    _sseClient = null;
  }
}
