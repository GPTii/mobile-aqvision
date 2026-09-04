import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static Color background = const Color(0xFFFFFFFF);
  static Color surface = const Color(0xFFF6F7FA);
  static Color card = const Color(0xFFFFFFFF);
  static Color border = const Color(0xFFE8E9EE);
  static Color headerBackground = const Color(0xFFFFECEC);
  static Color accent = const Color(0xFFFF5354);
  static Color accentSecondary = const Color(0xFFB23A3B);
  static Color info = const Color(0xFF4C86FF);
  static Color success = const Color(0xFF1AA971);
  static Color warning = const Color(0xFFE0930C);
  static Color danger = const Color(0xFFE23C4E);
  static Color textPrimary = const Color(0xFF15151A);
  static Color textSecondary = const Color(0xFF63656D);
  static Color textMuted = const Color(0xFF9A9CA5);
  static Color divider = const Color(0xFFE8E9EE);

  static LinearGradient accentGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5354), Color(0xFFB23A3B)],
  );

  static LinearGradient infoGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C86FF), Color(0xFF2F5FD6)],
  );

  static LinearGradient mediaPlaceholderGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E313A), Color(0xFF1B1D22)],
  );
  
  static Color mediaPlaceholderIcon = const Color(0x40FFFFFF);

  static void updateTheme(bool isDark) {
    if (isDark) {
      background = const Color(0xFF15151A);
      surface = const Color(0xFF0D0D12);
      card = const Color(0xFF1E1E24);
      border = const Color(0xFF2A2A35);
      headerBackground = const Color(0xFF2A1515);
      textPrimary = const Color(0xFFFFFFFF);
      textSecondary = const Color(0xFFA0A0AB);
      textMuted = const Color(0xFF63656D);
      divider = const Color(0xFF2A2A35);
    } else {
      background = const Color(0xFFFFFFFF);
      surface = const Color(0xFFF6F7FA);
      card = const Color(0xFFFFFFFF);
      border = const Color(0xFFE8E9EE);
      headerBackground = const Color(0xFFFFECEC);
      textPrimary = const Color(0xFF15151A);
      textSecondary = const Color(0xFF63656D);
      textMuted = const Color(0xFF9A9CA5);
      divider = const Color(0xFFE8E9EE);
    }
  }
}
