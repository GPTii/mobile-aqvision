import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class AppThemeStore extends ChangeNotifier {
  static final AppThemeStore instance = AppThemeStore._();
  AppThemeStore._();

  bool _isDark = false;
  bool get isDark => _isDark;

  String _lang = 'vi';
  String get lang => _lang;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? false;
    _lang = prefs.getString('lang') ?? 'vi';
    AppColors.updateTheme(_isDark);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    AppColors.updateTheme(_isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _lang = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', _lang);
    notifyListeners();
  }
}
