import 'package:flutter/foundation.dart';

/// Shared UI lifecycle flags — keep video decoders off when not needed.
class AppState {
  AppState._();

  /// When false (e.g. detail route), grid thumbnails should dispose decoders.
  static final ValueNotifier<bool> isVideoGridActive = ValueNotifier(true);

  /// Current bottom-nav index in [HomeShell].
  static final ValueNotifier<int> homeTabIndex = ValueNotifier(0);

  /// True when grid videos for [tabIndex] are allowed to play.
  static bool videoAllowedForTab(int tabIndex) =>
      isVideoGridActive.value && homeTabIndex.value == tabIndex;
}
