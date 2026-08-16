import re

with open('/home/ubuntu/mobile/lib/data/video_preload_cache.dart', 'r') as f:
    content = f.read()

content = content.replace("import 'dart:collection';", "import 'dart:async';\nimport 'dart:collection';")

target_vars = """  final Map<String, VideoPlayerController> _ready = {};
  final Map<String, Future<VideoPlayerController?>> _inflight = {};
  final Map<String, int> _refs = {};
  final LinkedHashSet<String> _lru = LinkedHashSet();
  final Set<String> _pinned = {};"""

replacement_vars = """  final Map<String, VideoPlayerController> _ready = {};
  final Map<String, Future<VideoPlayerController?>> _inflight = {};
  final Map<String, int> _refs = {};
  final LinkedHashSet<String> _lru = LinkedHashSet();
  final Set<String> _pinned = {};

  static const int maxConcurrentWarm = 2;
  int _activeWarms = 0;
  final Queue<({String id, String url, Completer<VideoPlayerController?> completer})> _warmQueue = Queue();"""

content = content.replace(target_vars, replacement_vars)

target_warm = """    final pending = _inflight[cameraId];
    if (pending != null) return pending;

    final future = _create(cameraId, hlsUrl);
    _inflight[cameraId] = future;
    return future.whenComplete(() => _inflight.remove(cameraId));
  }"""

replacement_warm = """    final pending = _inflight[cameraId];
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
  }"""

content = content.replace(target_warm, replacement_warm)

target_clear = """    _ready.clear();
    _lru.clear();
    _inflight.clear();
    _pinned.clear();
    _refs.clear();"""

replacement_clear = """    _ready.clear();
    _lru.clear();
    _inflight.clear();
    _pinned.clear();
    _refs.clear();

    for (final task in _warmQueue) {
      if (!task.completer.isCompleted) {
        task.completer.complete(null);
      }
    }
    _warmQueue.clear();"""

content = content.replace(target_clear, replacement_clear)

with open('/home/ubuntu/mobile/lib/data/video_preload_cache.dart', 'w') as f:
    f.write(content)

print("Patched video_preload_cache.dart")
