import 'package:flutter/material.dart';

/// Shared color palette for the app: a light, white-based UI with a red
/// brand accent (sampled from the AQP logo mark) and a blue secondary
/// accent carried over from the existing web dashboard.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF6F7FA);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8E9EE);

  // Pastel tint of the brand red — used as a soft header background so
  // headers don't blend into the plain white page.
  static const headerBackground = Color(0xFFFAEAED);

  // Brand red, sampled from the AQP logo mark.
  static const accent = Color(0xFFD1273F);
  static const accentSecondary = Color(0xFF7A1B2C);

  // Secondary/informational blue, carried over from the web dashboard.
  static const info = Color(0xFF4C86FF);

  static const success = Color(0xFF1AA971);
  static const warning = Color(0xFFE0930C);
  static const danger = Color(0xFFE23C4E);

  static const textPrimary = Color(0xFF15151A);
  static const textSecondary = Color(0xFF63656D);
  static const textMuted = Color(0xFF9A9CA5);
  static const divider = Color(0xFFE8E9EE);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentSecondary],
  );

  static const infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C86FF), Color(0xFF2F5FD6)],
  );

  // Video/camera preview placeholders read best as a dark "screen" — a
  // pale tint on white looks washed out and barely visible.
  static const mediaPlaceholderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E313A), Color(0xFF1B1D22)],
  );
  static const mediaPlaceholderIcon = Color(0x40FFFFFF);
}
