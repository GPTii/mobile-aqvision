import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Live playback protocol chosen by the user in camera detail.
/// Only the selected protocol is streamed — the other one is never opened.
class PlaybackPrefs {
  PlaybackPrefs._();

  static const String webrtc = 'webrtc';
  static const String hls = 'hls';
  static const String _key = 'live_play_protocol';

  static final ValueNotifier<String> protocol = ValueNotifier(webrtc);
  static bool _loaded = false;

  static bool get isWebRtc => protocol.value == webrtc;

  static Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == webrtc || saved == hls) protocol.value = saved!;
    _loaded = true;
  }

  static Future<void> set(String value) async {
    if (value != webrtc && value != hls) return;
    protocol.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }
}
