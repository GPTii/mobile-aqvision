import 'package:flutter/foundation.dart';

class CameraStorageUsage {
  final String id;
  final String name;
  final double usedStorageMb;

  CameraStorageUsage({
    required this.id,
    required this.name,
    required this.usedStorageMb,
  });
}

/// CommaDesk chưa có API quota lưu trữ cloud recording cho mobile.
/// Store giữ interface cũ và trả empty thay vì gọi endpoint AQ-VISION.
class StorageStore extends ChangeNotifier {
  static final StorageStore instance = StorageStore._();

  StorageStore._();

  double usedStorageMb = 0;
  double storageQuotaMb = 0;
  double percent = 0;
  String tier = 'good';
  List<CameraStorageUsage> cameras = [];
  bool loading = false;
  String? error;

  Future<void>? _inFlight;

  Future<void> fetchStorage() {
    return _inFlight ??= _doFetchStorage().whenComplete(() => _inFlight = null);
  }

  Future<void> _doFetchStorage() async {
    loading = true;
    error =
        'CommaDesk chưa cung cấp API dung lượng ghi hình — hiển thị 0 MB.';
    usedStorageMb = 0;
    storageQuotaMb = 0;
    percent = 0;
    tier = 'good';
    cameras = [];
    loading = false;
    notifyListeners();
  }
}
