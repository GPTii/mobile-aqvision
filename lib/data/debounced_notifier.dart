import 'dart:async';

import 'package:flutter/foundation.dart';

/// Mixin that batches rapid [notifyListeners] calls into one frame.
mixin DebouncedNotify on ChangeNotifier {
  Timer? _debounceTimer;
  bool _notifyScheduled = false;

  /// Immediate notify (list structure changes: add/remove/fetch).
  void notifyNow() {
    _debounceTimer?.cancel();
    _notifyScheduled = false;
    notifyListeners();
  }

  /// Coalesce many updates (e.g. SSE) into a single notify.
  void notifySoon([Duration delay = const Duration(milliseconds: 320)]) {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Per-id tick notifiers so UI can rebuild one camera/row without the whole store.
class IdListenables {
  final Map<String, ValueNotifier<int>> _ticks = {};

  Listenable of(String id) => _ticks.putIfAbsent(id, () => ValueNotifier(0));

  void bump(String id) {
    final n = _ticks.putIfAbsent(id, () => ValueNotifier(0));
    n.value++;
  }

  void dispose() {
    for (final n in _ticks.values) {
      n.dispose();
    }
    _ticks.clear();
  }
}
