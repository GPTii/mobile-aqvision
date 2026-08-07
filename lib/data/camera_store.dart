import 'package:flutter/foundation.dart';

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
  });
}

/// Single in-memory source of truth for camera groups (rooms) and cameras,
/// shared by the Home and Camera tabs so add/edit/delete reflects everywhere.
class CameraStore extends ChangeNotifier {
  static final CameraStore instance = CameraStore._();

  final List<CameraGroup> _groups = [];
  final List<Camera> _cameras = [];
  int _groupSeq = 0;
  int _cameraSeq = 0;

  CameraStore._() {
    _seedInitialData();
  }

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

  String _nextGroupId() => 'group_${_groupSeq++}';
  String _nextCameraId() => 'camera_${_cameraSeq++}';

  /// Suggests the next free device code/IP so the add-camera form starts
  /// pre-filled with something plausible instead of forcing manual entry.
  String suggestCameraCode() =>
      'CAM-${(_cameraSeq + 1).toString().padLeft(4, '0')}';

  String suggestIpAddress() => '192.168.1.${100 + _cameraSeq}';

  CameraGroup addGroup(String name) {
    final group = CameraGroup(id: _nextGroupId(), name: name.trim());
    _groups.add(group);
    notifyListeners();
    return group;
  }

  void renameGroup(String groupId, String newName) {
    final group = groupById(groupId);
    if (group == null || newName.trim().isEmpty) return;
    group.name = newName.trim();
    notifyListeners();
  }

  void deleteGroup(String groupId) {
    _cameras.removeWhere((c) => c.groupId == groupId);
    _groups.removeWhere((g) => g.id == groupId);
    notifyListeners();
  }

  Camera addCamera({
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
  }) {
    final camera = Camera(
      id: _nextCameraId(),
      name: name.trim(),
      cameraCode: cameraCode.trim(),
      type: type,
      ipAddress: ipAddress.trim(),
      location: location.trim(),
      groupId: groupId,
      online: online,
      resolution: resolution,
      recording: recording,
      lastSeen: lastSeen,
    );
    _cameras.add(camera);
    notifyListeners();
    return camera;
  }

  void updateCamera(
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
  }) {
    final camera = cameraById(cameraId);
    if (camera == null) return;
    if (name != null && name.trim().isNotEmpty) camera.name = name.trim();
    if (groupId != null) camera.groupId = groupId;
    if (cameraCode != null && cameraCode.trim().isNotEmpty) {
      camera.cameraCode = cameraCode.trim();
    }
    if (type != null) camera.type = type;
    if (ipAddress != null && ipAddress.trim().isNotEmpty) {
      camera.ipAddress = ipAddress.trim();
    }
    if (location != null) camera.location = location.trim();
    if (resolution != null) camera.resolution = resolution;
    if (online != null) camera.online = online;
    if (recording != null) camera.recording = recording;
    notifyListeners();
  }

  void deleteCamera(String cameraId) {
    _cameras.removeWhere((c) => c.id == cameraId);
    notifyListeners();
  }

  void _seedInitialData() {
    final livingRoom = addGroup('Phòng khách');
    final kitchen = addGroup('Nhà bếp');
    final parking = addGroup('Bãi đỗ xe');
    final warehouse = addGroup('Kho hàng');

    addCamera(
      name: 'Cam 1',
      groupId: livingRoom.id,
      cameraCode: 'CAM-0001',
      type: kCameraTypes[0],
      ipAddress: '192.168.1.101',
      location: 'Góc trái, gần cửa ra vào',
      recording: true,
      lastSeen: '15:45',
    );
    addCamera(
      name: 'Cam 2',
      groupId: livingRoom.id,
      cameraCode: 'CAM-0002',
      type: kCameraTypes[1],
      ipAddress: '192.168.1.102',
      location: 'Gần tivi, hướng ra sofa',
      recording: true,
      lastSeen: '15:45',
    );
    addCamera(
      name: 'Cam 3',
      groupId: livingRoom.id,
      cameraCode: 'CAM-0003',
      type: kCameraTypes[2],
      ipAddress: '192.168.1.103',
      location: 'Trần nhà, giữa phòng',
      online: false,
      lastSeen: '15:20',
    );

    addCamera(
      name: 'Cam 1',
      groupId: kitchen.id,
      cameraCode: 'CAM-0004',
      type: kCameraTypes[0],
      ipAddress: '192.168.1.104',
      location: 'Trên tủ bếp',
      recording: true,
      lastSeen: '15:40',
    );
    addCamera(
      name: 'Cam 2',
      groupId: kitchen.id,
      cameraCode: 'CAM-0005',
      type: kCameraTypes[1],
      ipAddress: '192.168.1.105',
      location: 'Gần cửa hậu',
      recording: true,
      lastSeen: '15:38',
    );
    addCamera(
      name: 'Cam 3',
      groupId: kitchen.id,
      cameraCode: 'CAM-0006',
      type: kCameraTypes[3],
      ipAddress: '192.168.1.106',
      location: 'Bàn ăn',
      resolution: '4K',
      lastSeen: '15:36',
    );

    addCamera(
      name: 'Cổng chính',
      groupId: parking.id,
      cameraCode: 'CAM-0007',
      type: kCameraTypes[1],
      ipAddress: '192.168.1.107',
      location: 'Trụ cổng, hướng ra đường',
      resolution: '4K',
      recording: true,
      lastSeen: '15:30',
    );
    addCamera(
      name: 'Bãi đỗ xe ngoài',
      groupId: parking.id,
      cameraCode: 'CAM-0008',
      type: kCameraTypes[2],
      ipAddress: '192.168.1.108',
      location: 'Mái hiên, bao quát bãi xe',
      online: false,
      lastSeen: '14:58',
    );

    addCamera(
      name: 'Kho A',
      groupId: warehouse.id,
      cameraCode: 'CAM-0009',
      type: kCameraTypes[0],
      ipAddress: '192.168.1.109',
      location: 'Góc kho, gần kệ hàng A',
      resolution: '720p',
      lastSeen: '13:12',
    );
  }
}
