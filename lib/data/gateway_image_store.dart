import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Avatar photo per gateway, kept on this phone only (the server has no field
/// for it). Without a choice a gateway shows the AQPTech product photo.
class GatewayImageStore extends ChangeNotifier {
  GatewayImageStore._() {
    _load();
  }

  static final GatewayImageStore instance = GatewayImageStore._();

  static const companyAsset = 'assets/images/gateway_company.jpg';
  static const trafficAsset = 'assets/images/gateway_traffic.jpg';

  static const _key = 'gateway_images';

  /// gateway id -> asset path (`assets/...`) or a file in the app documents dir.
  Map<String, String> _images = {};

  /// Product photo matching the gateway: traffic for names like
  /// "Giao thông" / "traffic", the company one otherwise.
  static String defaultAsset(String id, String name) {
    final s = '$id $name'.toLowerCase();
    return s.contains('traffic') || s.contains('giao thông') || s.contains('giaothong') ? trafficAsset : companyAsset;
  }

  /// The user's pick, or null to use [defaultAsset].
  String? custom(String gatewayId) => _images[gatewayId];

  Future<void> _load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw != null) _images = Map<String, String>.from(jsonDecode(raw) as Map);
    notifyListeners();
  }

  /// Uses one of the bundled product photos.
  Future<void> setAsset(String gatewayId, String asset) async {
    await _deleteFile(_images[gatewayId]);
    _images = {..._images, gatewayId: asset};
    await _save();
  }

  /// Copies a picked photo into app storage so it survives gallery cleanup.
  Future<void> setFile(String gatewayId, String pickedPath) async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/gateway_images');
    await dir.create(recursive: true);
    final safeId = gatewayId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    // New name each time so Image.file doesn't show the cached old photo.
    final dest = '${dir.path}/${safeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(pickedPath).copy(dest);
    await _deleteFile(_images[gatewayId]);
    _images = {..._images, gatewayId: dest};
    await _save();
  }

  /// Back to the default product photo.
  Future<void> reset(String gatewayId) async {
    if (!_images.containsKey(gatewayId)) return;
    await _deleteFile(_images[gatewayId]);
    _images = {..._images}..remove(gatewayId);
    await _save();
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null || path.startsWith('assets/')) return;
    try {
      await File(path).delete();
    } catch (_) {
      // already gone
    }
  }

  Future<void> _save() async {
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(_images));
  }
}
