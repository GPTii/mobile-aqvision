import 'package:flutter/foundation.dart';

import 'camera_store.dart';

class SystemStats {
  final int totalCameras;
  final int onlineCameras;
  final int offlineCameras;
  final double cpuLoadPercent;
  final int ramTotal;
  final int ramUsed;
  final int ramFree;
  final int diskTotal;
  final int diskUsed;
  final int diskFree;

  SystemStats({
    required this.totalCameras,
    required this.onlineCameras,
    required this.offlineCameras,
    this.cpuLoadPercent = 0,
    this.ramTotal = 0,
    this.ramUsed = 0,
    this.ramFree = 0,
    this.diskTotal = 0,
    this.diskUsed = 0,
    this.diskFree = 0,
  });
}

/// Camera overview derived from [CameraStore] — CommaDesk has no `/stats` endpoint.
class StatsStore extends ChangeNotifier {
  static final StatsStore instance = StatsStore._();

  StatsStore._();

  SystemStats? _stats;
  SystemStats? get stats => _stats;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchStats() async {
    final hadData = _stats != null;
    _isLoading = true;
    if (!hadData) notifyListeners();

    try {
      await CameraStore.instance.fetchCameras();
      final cams = CameraStore.instance.cameras;
      final online = cams.where((c) => c.online).length;
      _stats = SystemStats(
        totalCameras: cams.length,
        onlineCameras: online,
        offlineCameras: cams.length - online,
      );
    } catch (e) {
      debugPrint('[StatsStore] $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
