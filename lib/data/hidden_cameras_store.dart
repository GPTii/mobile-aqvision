import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cameras the user chose to hide from the Home tab. Kept on this phone only;
/// the camera itself is untouched and still shows on the Camera tab.
class HiddenCamerasStore extends ChangeNotifier {
  HiddenCamerasStore._() {
    _load();
  }

  static final HiddenCamerasStore instance = HiddenCamerasStore._();

  static const _key = 'home_hidden_cameras';

  Set<String> _ids = {};

  bool isHidden(String cameraId) => _ids.contains(cameraId);

  Set<String> get ids => Set.unmodifiable(_ids);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids = (prefs.getStringList(_key) ?? []).toSet();
    notifyListeners();
  }

  Future<void> hide(String cameraId) => _save({..._ids, cameraId});

  Future<void> show(String cameraId) => _save({..._ids}..remove(cameraId));

  Future<void> showAll() => _save({});

  Future<void> _save(Set<String> ids) async {
    _ids = ids;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}
