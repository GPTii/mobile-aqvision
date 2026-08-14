import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const kCameraTypes = [
  'Camera Dome',
  'Camera thân trụ',
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
  String? targetUrl;

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
    this.targetUrl,
  });
}

class CameraStore extends ChangeNotifier {
  static final CameraStore instance = CameraStore._();

  final List<CameraGroup> _groups = [];
  List<Camera> _cameras = [];
  http.Client? _sseClient;

  CameraStore._();

  List<CameraGroup> get groups => List.unmodifiable(_groups);
  List<Camera> get cameras => List.unmodifiable(_cameras);

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
  
  String get _baseUrl {
    if (kIsWeb) {
      final port = Uri.base.port;
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : "localhost";
      if (port != 3002 && (host == 'localhost' || host == '127.0.0.1')) {
        return "http://$host:3002/api";
      }
      return "${Uri.base.scheme}://${Uri.base.authority}/api";
    }
    return "http://dev1.aqvision.net/api";
  }
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> fetchGroups() async {
    final token = await _getToken();
    if (token == null) return;
    
    final uri = Uri.parse("$_baseUrl/groups");
    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
    }).timeout(const Duration(seconds: 10));
    
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json["data"] ?? [];
      _groups.clear();
      for (final item in data) {
        _groups.add(CameraGroup(
          id: item["id"].toString(),
          name: item["name"] ?? "Nhóm",
        ));
      }
      notifyListeners();
    }
  }

  Future<void> fetchCameras() async {
    final token = await _getToken();
    if (token == null) return;
    
    final uri = Uri.parse("$_baseUrl/proxies");
    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
    }).timeout(const Duration(seconds: 10));
    
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json["data"] ?? [];
      
      final mediaHost = uri.host.isNotEmpty ? uri.host : "dev1.aqvision.net";
      final mediaBaseUrl = uri.port == 3002 ? "http://$mediaHost:3002/api/media" : "https://$mediaHost/api/media";
      
      _cameras = data.map((item) {
        final app = item["app"] ?? "live";
        final stream = item["stream"] ?? "cam";
        final itemUrl = (item["url"] ?? "").toString().trim();
        
        String hlsUrl = "";
        if (itemUrl.contains(".m3u8") || itemUrl.startsWith("http")) {
          hlsUrl = itemUrl;
        } else {
          hlsUrl = "$mediaBaseUrl/$app/$stream/hls.m3u8?access_token=$token";
        }

        return Camera(
          id: (item["id"] ?? 0).toString(),
          name: item["stream"] ?? "Camera", // Map stream to name for UI
          cameraCode: item["stream"] ?? "CAM-0000",
          type: kCameraTypes[0],
          ipAddress: item["url"] ?? "", // Map url to ipAddress
          location: "Góc camera", // Mocked for UI
          groupIds: (item["groupIds"] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          online: item["status"] == "Online",
          resolution: "1080p",
          recording: item["enableMp4"] == true, // Map enableMp4 to recording
          lastSeen: "Vừa mới",
          app: app,
          hlsUrl: hlsUrl,
          targetUrl: item["url"],
        );
      }).toList();
      notifyListeners();
    }
  }

  String suggestCameraCode() => 'live'; // Usually the 'app' or stream prefix in API
  String suggestIpAddress() => 'rtsp://';

  Future<CameraGroup> addGroup(String name) async {
    final token = await _getToken();
    if (token == null) throw Exception("Unauthorized");
    
    final uri = Uri.parse("$_baseUrl/groups");
    final res = await http.post(uri, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    }, body: jsonEncode({"name": name.trim()}));
    
    if (res.statusCode == 200 || res.statusCode == 201) {
      final json = jsonDecode(res.body);
      final data = json["data"];
      final group = CameraGroup(id: data["id"].toString(), name: data["name"]);
      _groups.add(group);
      notifyListeners();
      return group;
    } else {
      final json = jsonDecode(res.body);
      throw Exception(json["error"] ?? "Lỗi thêm nhóm");
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    final group = groupById(groupId);
    if (group == null || newName.trim().isEmpty) return;
    group.name = newName.trim();
    notifyListeners();
  }

  Future<void> deleteGroup(String groupId) async {
    final token = await _getToken();
    if (token == null) return;
    
    final uri = Uri.parse("$_baseUrl/groups/$groupId");
    await http.delete(uri, headers: {
      "Authorization": "Bearer $token",
    });
    
    _groups.removeWhere((g) => g.id == groupId);
    notifyListeners();
    await fetchCameras(); // Cameras might have been unlinked
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
    final token = await _getToken();
    final uri = Uri.parse("$_baseUrl/proxies");
    final res = await http.post(uri, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    }, body: jsonEncode({
      "app": "live",
      "stream": cameraCode,
      "url": ipAddress,
      "groupIds": groupIds.map((id) => int.tryParse(id) ?? 0).toList(),
      "enableHls": true,
      "enableMp4": recording,
    }));
    
    if (res.statusCode == 200 || res.statusCode == 201) {
      await fetchCameras();
      return _cameras.firstWhere((c) => c.cameraCode == cameraCode, orElse: () => _cameras.last);
    } else {
      final json = jsonDecode(res.body);
      throw Exception(json["error"] ?? "Lỗi thêm camera");
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
    final uri = Uri.parse("$_baseUrl/proxies/$cameraId");
    final camera = cameraById(cameraId);
    
    final res = await http.patch(uri, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    }, body: jsonEncode({
      if (cameraCode != null) "stream": cameraCode,
      if (ipAddress != null) "url": ipAddress,
      if (groupIds != null) "groupIds": groupIds.map((id) => int.tryParse(id) ?? 0).toList(),
      if (recording != null) "enableMp4": recording,
    }));
    
    if (res.statusCode == 200) {
      await fetchCameras();
    } else {
      throw Exception("Lỗi cập nhật camera");
    }
  }

  Future<void> toggleManualRecording(String app, String stream, bool start) async {
    final token = await _getToken();
    final action = start ? "startRecord" : "stopRecord";
    final baseUrlUri = Uri.parse(_baseUrl);
    final uri = Uri(
      scheme: baseUrlUri.scheme,
      host: baseUrlUri.host,
      port: baseUrlUri.port,
      path: "${baseUrlUri.path}/rapidmedia/$action",
      queryParameters: {
        "vhost": "__defaultVhost__",
        "app": app,
        "stream": stream,
        "type": "1"
      }
    );
    
    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
    });
    
    if (res.statusCode != 200) {
      throw Exception("Lỗi khi ${start ? "bắt đầu" : "dừng"} ghi hình");
    }
  }

  Future<void> deleteCamera(String cameraId) async {
    final token = await _getToken();
    final uri = Uri.parse("$_baseUrl/proxies/$cameraId");
    final res = await http.delete(uri, headers: {
      "Authorization": "Bearer $token",
    });
    
    if (res.statusCode == 200) {
      _cameras.removeWhere((c) => c.id == cameraId);
      notifyListeners();
    } else {
      throw Exception("Lỗi xóa camera");
    }
  }

  /// Toggle camera connection (reconnect / disconnect).
  /// Uses the same PUT /api/proxies/{id} endpoint as the web dashboard.
  Future<void> toggleConnection(String cameraId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final camera = cameraById(cameraId);
    if (camera == null) throw Exception('Camera not found');

    final action = camera.online ? 'disconnect' : 'reconnect';
    final uri = Uri.parse("$_baseUrl/proxies/$cameraId");
    final res = await http.put(uri, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    }, body: jsonEncode({"action": action}));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final data = json["data"];
      if (data != null && data["status"] != null) {
        camera.online = data["status"] == "Online";
      } else {
        camera.online = !camera.online;
      }
      notifyListeners();
    } else {
      throw Exception('Lỗi khi ${action == "disconnect" ? "ngắt kết nối" : "kết nối lại"} camera');
    }
  }

  Future<void> connectRealtime() async {
    final token = await _getToken();
    if (token == null) return;

    _sseClient?.close();
    _sseClient = http.Client();

    try {
      final req = http.Request("GET", Uri.parse("$_baseUrl/v1/realtime"));
      req.headers["Authorization"] = "Bearer $token";
      
      final res = await _sseClient!.send(req);

      res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (line.startsWith("data: ")) {
          final dataStr = line.substring(6);
          try {
            final data = jsonDecode(dataStr);
            if (data["id"] != null && data["status"] != null) {
              final cam = cameraById(data["id"].toString());
              if (cam != null) {
                cam.online = data["status"] == "Online";
                notifyListeners();
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
