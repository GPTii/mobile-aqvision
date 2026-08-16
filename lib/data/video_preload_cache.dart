import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Keeps a small set of warmed [VideoPlayerController]s so opening a camera
/// can play immediately instead of waiting for HLS init.
class VideoPreloadCache {
  VideoPreloadCache._();
  static final VideoPreloadCache instance = VideoPreloadCache._();

  static const int maxWarm = 6;

  final Map<String, VideoPlayerController> _ready = {};
  final Map<String, Future<VideoPlayerController?>> _inflight = {};
  final Map<String, int> _refs = {};
  final LinkedHashSet<String> _lru = LinkedHashSet();
  final Set<String> _pinned = {};

  static const int maxConcurrentWarm = 2;
  int _activeWarms = 0;
  final Queue<({String id, String url, Completer<VideoPlayerController?> completer})> _warmQueue = Queue();

  bool isReady(String cameraId) {
    final c = _ready[cameraId];
    return c != null && c.value.isInitialized;
  }

  /// Read-only access for grid tiles (does not bump refcount).
  VideoPlayerController? peek(String cameraId) {
    final c = _ready[cameraId];
    if (c == null || !c.value.isInitialized) return null;
    if ((_refs[cameraId] ?? 0) > 0) return null; // detail owns the surface
    _touch(cameraId);
    return c;
  }

  void pin(String cameraId) => _pinned.add(cameraId);

  void unpin(String cameraId) => _pinned.remove(cameraId);

  /// Warm a stream in the background (muted). Safe to call repeatedly.
  Future<VideoPlayerController?> warm(String cameraId, String hlsUrl) {
    if (hlsUrl.isEmpty) return Future.value(null);

    final existing = _ready[cameraId];
    if (existing != null && existing.value.isInitialized) {
      _touch(cameraId);
      return Future.value(existing);
    }

    final pending = _inflight[cameraId];
    if (pending != null) return pending;

    final completer = Completer<VideoPlayerController?>();
    _inflight[cameraId] = completer.future;

    _warmQueue.add((id: cameraId, url: hlsUrl, completer: completer));
    _processQueue();

    return completer.future;
  }

  void _processQueue() async {
    if (_activeWarms >= maxConcurrentWarm || _warmQueue.isEmpty) return;

    final task = _warmQueue.removeFirst();
    _activeWarms++;

    try {
      final c = await _create(task.id, task.url);
      if (!task.completer.isCompleted) task.completer.complete(c);
    } catch (e) {
      if (!task.completer.isCompleted) task.completer.complete(null);
    } finally {
      _inflight.remove(task.id);
      _activeWarms--;
      _processQueue();
    }
  }

  Future<void> warmMany(Iterable<({String id, String url})> items) async {
    final list =
        items.where((e) => e.url.isNotEmpty).take(maxWarm).toList();
    await Future.wait(list.map((e) => warm(e.id, e.url)));
  }

  /// Detail / fullscreen acquire. Pair every call with [release].
  VideoPlayerController? acquire(String cameraId) {
    final c = _ready[cameraId];
    if (c == null || !c.value.isInitialized) return null;
    _refs[cameraId] = (_refs[cameraId] ?? 0) + 1;
    _touch(cameraId);
    return c;
  }

  /// Return an acquired controller. When refs hit 0, keep warm for the grid.
  void release(String cameraId, {bool keepWarm = true}) {
    final next = (_refs[cameraId] ?? 1) - 1;
    if (next > 0) {
      _refs[cameraId] = next;
      return;
    }
    _refs.remove(cameraId);
    final c = _ready[cameraId];
    if (c == null) return;
    if (!keepWarm) {
      _evict(cameraId);
      return;
    }
    try {
      c.setVolume(0);
      if (!c.value.isPlaying) c.play();
    } catch (_) {}
  }

  /// Drop unpinned, unused controllers (leaving video grids).
  void disposeUnpinned() {
    final ids = _ready.keys
        .where((id) =>
            !_pinned.contains(id) && (_refs[id] ?? 0) == 0)
        .toList();
    for (final id in ids) {
      _evict(id);
    }
  }

  void invalidate(String cameraId) {
    _inflight.remove(cameraId);
    _refs.remove(cameraId);
    _evict(cameraId);
  }

  void clear() {
    for (final c in _ready.values) {
      c.dispose();
    }
    _ready.clear();
    _lru.clear();
    _inflight.clear();
    _pinned.clear();
    _refs.clear();

    for (final task in _warmQueue) {
      if (!task.completer.isCompleted) {
        task.completer.complete(null);
      }
    }
    _warmQueue.clear();
  }

  Future<VideoPlayerController?> _create(String cameraId, String hlsUrl) async {
    try {
      _evictIfNeeded();
      final controller = VideoPlayerController.networkUrl(Uri.parse(hlsUrl));
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(true);
      await controller.play();
      final stale = _ready[cameraId];
      if (stale != null && stale != controller) {
        controller.dispose();
        return stale;
      }
      _ready[cameraId] = controller;
      _touch(cameraId);
      return controller;
    } catch (e) {
      debugPrint('[VideoPreload] warm failed $cameraId: $e');
      return null;
    }
  }

  void _touch(String cameraId) {
    _lru.remove(cameraId);
    _lru.add(cameraId);
  }

  void _evictIfNeeded() {
    while (_ready.length >= maxWarm) {
      String? victim;
      for (final id in _lru) {
        if (!_pinned.contains(id) && (_refs[id] ?? 0) == 0) {
          victim = id;
          break;
        }
      }
      if (victim == null) break;
      _evict(victim);
    }
  }

  void _evict(String cameraId) {
    _lru.remove(cameraId);
    final c = _ready.remove(cameraId);
    c?.dispose();
  }
}
