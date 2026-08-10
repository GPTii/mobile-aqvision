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
  String groupId;
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
    required this.groupId,
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

  CameraStore._();

  List<CameraGroup> get groups => List.unmodifiable(_groups);
  List<Camera> get cameras => List.unmodifiable(_cameras);

  List<Camera> camerasInGroup(String groupId) =>
      _cameras.where((c) => c.groupId == groupId).toList();

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
    return "https://api.aqvision.net/api";
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
    
    final uri = Uri.parse("$_baseUrl/v1/streams");
    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
    }).timeout(const Duration(seconds: 10));
    
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List data = json["data"] ?? [];
      
      _cameras = data.map((item) => Camera(
        id: (item["id"] ?? 0).toString(),
        name: item["name"] ?? "Camera",
        cameraCode: item["stream"] ?? "CAM-0000",
        type: kCameraTypes[0],
        ipAddress: item["targetUrl"] ?? "", // Map targetUrl to ipAddress just for UI
        location: "Góc camera", // Mocked for UI
        groupId: (item["groupId"] ?? 0).toString(),
        online: item["status"] == "Online",
        resolution: "1080p",
        recording: true,
        lastSeen: "Vừa mới",
        app: item["app"] ?? "live",
        hlsUrl: item["playbackUrls"]?["hls"],
        targetUrl: item["sourceUrl"] ?? item["targetUrl"],
      )).toList();
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
    required String groupId,
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
      "app": "live", // Hardcode for now, or map to cameraCode
      "stream": cameraCode,
      "url": ipAddress, // Using ipAddress as RTSP Url in UI mapping
      "groupId": int.tryParse(groupId) ?? 0,
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
    String? groupId,
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
      "app": camera?.app ?? "live",
      "stream": cameraCode ?? camera?.cameraCode,
      "url": ipAddress ?? camera?.targetUrl,
      "groupId": groupId == "" ? "" : (groupId != null ? (int.tryParse(groupId) ?? 0) : null),
    }));
    
    if (res.statusCode == 200) {
      await fetchCameras();
    } else {
      throw Exception("Lỗi cập nhật camera");
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
}
