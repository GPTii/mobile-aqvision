import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

enum AppLanguage { vi, en }

/// User-facing preferences shown in Cài đặt (Ngoại hình / Ngôn ngữ /
/// Tự động cập nhật / Phát bằng mạng di động).
///
/// These persist the user's *choice*, but note the scope of what's actually
/// wired up: the app has no dark `ThemeData` or `flutter_localizations` yet,
/// so switching theme/language here does not repaint the UI or retranslate
/// strings — it only remembers the preference for when that work lands.
/// `playOnMobileData` and `autoUpdateEnabled` are likewise stored but not
/// yet enforced (no connectivity gate on playback, no update-check backend).
class SettingsStore extends ChangeNotifier {
  static final SettingsStore instance = SettingsStore._();
  SettingsStore._();

  static const _kTheme = 'settings_theme_mode';
  static const _kLanguage = 'settings_language';
  static const _kPlayOnMobileData = 'settings_play_on_mobile_data';
  static const _kAutoUpdate = 'settings_auto_update_enabled';

  AppThemeMode themeMode = AppThemeMode.system;
  AppLanguage language = AppLanguage.vi;
  bool playOnMobileData = true;
  bool autoUpdateEnabled = true;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    themeMode = AppThemeMode.values.firstWhere(
      (m) => m.name == prefs.getString(_kTheme),
      orElse: () => AppThemeMode.system,
    );
    language = AppLanguage.values.firstWhere(
      (l) => l.name == prefs.getString(_kLanguage),
      orElse: () => AppLanguage.vi,
    );
    playOnMobileData = prefs.getBool(_kPlayOnMobileData) ?? true;
    autoUpdateEnabled = prefs.getBool(_kAutoUpdate) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, mode.name);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, lang.name);
  }

  Future<void> setPlayOnMobileData(bool value) async {
    playOnMobileData = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPlayOnMobileData, value);
  }

  Future<void> setAutoUpdateEnabled(bool value) async {
    autoUpdateEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoUpdate, value);
  }
}
