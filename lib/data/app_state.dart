import 'package:flutter/foundation.dart';

class AppState {
  /// When true, grid video players are allowed to initialize and play.
  /// When false (e.g., when navigating to a detail screen), they should dispose their decoders.
  static final ValueNotifier<bool> isVideoGridActive = ValueNotifier(true);
}
