import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'debounced_notifier.dart';

class RecordingFile {
  final String date;       // YYYY-MM-DD
  final String fileName;   // e.g. 2026-08-14-12-00-00-0.mp4
  final String app;
  final String stream;
  final String serverUrl;  // base URL of media server
  final String token;      // auth token

  RecordingFile({
    required this.date,
    required this.fileName,
    required this.app,
    required this.stream,
    required this.serverUrl,
    required this.token,
  });

  String get mp4Url => mp4Uri.toString();

  /// `/api/media/record/...` — encode stream names with spaces (`cam demo2`).
  ///
  /// Auth: `?access_token=` là cách duy nhất `/api/media/[...path]` chấp nhận
  /// cho mobile (nó chỉ đọc cookie `session`, header Bearer, hoặc query
  /// `access_token` — KHÔNG đọc `auth_token`). Query param cũng cần thiết cho
  /// nút tải về vì trình duyệt ngoài app không có cookie.
  Uri get mp4Uri {
    var base = Uri.parse(serverUrl);
    if (base.scheme == 'https' && base.host.startsWith('dev1')) {
      base = base.replace(scheme: 'http', port: 80);
    }
    return base.replace(
      pathSegments: [
        ...base.pathSegments.where((s) => s.isNotEmpty),
        'record',
        app,
        stream,
        date,
        fileName,
      ],
      queryParameters: {
        'access_token': token,
      },
    );
  }

  /// ZLM MP4 names: `YYYY-MM-DD-HH-MM-SS-index.mp4` → `HH:MM:SS`.
  /// Legacy short names: `HH-MM-SS.mp4` → `HH:MM:SS`.
  String get displayTime {
    final parts = fileName.replaceAll('.mp4', '').split('-');
    if (parts.length >= 6 && parts[0].length == 4) {
      return 'Bắt đầu: ${parts[3]}:${parts[4]}:${parts[5]}';
    } else if (parts.length >= 3) {
      return 'Bắt đầu: ${parts[0]}:${parts[1]}:${parts[2]}';
    }
    return fileName;
  }

  String get durationText {
    final parts = fileName.replaceAll('.mp4', '').split('-');
    if (parts.length >= 7 && parts[0].length == 4) {
      int? dur = int.tryParse(parts[6]);
      if (dur != null && dur > 0) return 'Thời lượng: $dur giây';
    }
    return '';
  }

  String get id => '$date/$fileName';
}

class RecordingStore extends ChangeNotifier {
  static final RecordingStore instance = RecordingStore._();
  RecordingStore._();

  // Per-camera cache: cameraId -> list of recordings
  final Map<String, List<RecordingFile>> _cache = {};
  // Per-camera recording status
  final Map<String, bool> _isRecording = {};
  // Per-camera loading state
  final Map<String, bool> _loading = {};
  final IdListenables _cameraTicks = IdListenables();

  bool isRecording(String cameraId) => _isRecording[cameraId] ?? false;
  bool isLoading(String cameraId) => _loading[cameraId] ?? false;
  List<RecordingFile> recordingsFor(String cameraId) =>
      _cache[cameraId] ?? [];

  /// Rebuild only UI that cares about this camera's recordings / REC state.
  Listenable listenableFor(String cameraId) => _cameraTicks.of(cameraId);

  void _notifyCamera(String cameraId) => _cameraTicks.bump(cameraId);

  String get _baseUrl => ApiConfig.apiBase;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Luồng B: cookie `auth_token` after `POST /api/auth/login`.
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? prefs.getString('token');
  }

  String _appName(String? app) =>
      (app == null || app.trim().isEmpty) ? 'live' : app.trim();

  /// Web proxy `/api/rapidmedia/*` — send cookie `auth_token`, do not send `secret`.
  Future<Map<String, dynamic>> _rapidGet(
    String action,
    Map<String, String> query, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final authToken = await _getAuthToken();
    if (authToken == null) throw Exception('Chưa đăng nhập');

    final uri = Uri.parse('$_baseUrl/rapidmedia/$action').replace(
      queryParameters: query,
    );
    final res = await http.get(uri, headers: {
      'Cookie': 'auth_token=$authToken',
      'Accept': 'application/json',
    }).timeout(timeout);

    debugPrint('[RECORD] $action → ${res.statusCode} ${res.body}');

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Phiên ghi hình hết hạn. Hãy đăng xuất rồi đăng nhập lại.');
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('unexpected body');
      }
      json = decoded;
    } catch (_) {
      throw Exception('Máy chủ ghi hình trả về lỗi (${res.statusCode})');
    }

    final payload = json.containsKey('code')
        ? json
        : (json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json);

    if (res.statusCode != 200) {
      throw Exception(_messageFrom(json, payload, fallback: 'Lỗi ghi hình (${res.statusCode})'));
    }
    return payload;
  }

  bool _isApiOk(Map<String, dynamic> json) {
    final code = json['code'];
    if (code != null) return code == 0 || code == '0';
    return json['success'] == true || json['result'] == true;
  }

  String _messageFrom(
    Map<String, dynamic> json,
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    final raw = (payload['msg'] ?? json['error'] ?? json['message'] ?? payload['error'])
        ?.toString();
    final code = payload['code'];
    if (code == -500 || raw == 'can not find the stream') {
      return 'Camera chưa online trên máy chủ ghi hình';
    }
    if (code == -100) return 'Không có quyền ghi hình';
    if (code == -300) return 'Thiếu thông tin camera để ghi hình';
    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'success') {
      return fallback;
    }
    return raw;
  }

  /// Fetch all recording files for [camera] between [startDate] and [endDate].
  /// Dates format: "YYYY-MM-DD"
  Future<void> fetchRecordings({
    required String cameraId,
    required String app,
    required String stream,
    required String serverUrl,
    required String startDate,
    required String endDate,
  }) async {
    final token = await _getAuthToken();
    if (token == null) return;
    _loading[cameraId] = true;
    _notifyCamera(cameraId);

    final resolvedApp = _appName(app);
    final allDates = _datesBetween(startDate, endDate);
    // Prefer the most recent days when the range is longer than 7.
    final dates = allDates.length <= 7
        ? allDates
        : allDates.sublist(allDates.length - 7);
    final results = <RecordingFile>[];

    try {
      await Future.wait(dates.map((d) async {
        try {
          final json = await _rapidGet('getMP4RecordFile', {
            'vhost': '__defaultVhost__',
            'app': resolvedApp,
            'stream': stream,
            'period': d,
          });
          if (_isApiOk(json) && json['data']?['paths'] != null) {
            final paths = (json['data']['paths'] as List).cast<String>();
            for (final p in paths.reversed) {
              results.add(RecordingFile(
                date: d,
                fileName: p,
                app: resolvedApp,
                stream: stream,
                serverUrl: '$_baseUrl/media',
                token: token,
              ));
            }
          }
        } catch (e) {
          debugPrint('[RECORD] getMP4RecordFile $d failed: $e');
        }
      }));

      results.sort((a, b) {
        final dc = b.date.compareTo(a.date);
        if (dc != 0) return dc;
        return b.fileName.compareTo(a.fileName);
      });

      _cache[cameraId] = results;
    } catch (_) {
      _cache[cameraId] = [];
    } finally {
      _loading[cameraId] = false;
      _notifyCamera(cameraId);
    }
  }

  /// Check if a camera is currently recording MP4 (`type=1`).
  Future<void> checkRecordStatus({
    required String cameraId,
    required String app,
    required String stream,
  }) async {
    try {
      final json = await _rapidGet(
        'isRecording',
        {
          'type': '1',
          'vhost': '__defaultVhost__',
          'app': _appName(app),
          'stream': stream,
        },
        timeout: const Duration(seconds: 8),
      );
      if (_isApiOk(json)) {
        final next = json['status'] == true || json['status'] == 1;
        if (_isRecording[cameraId] != next) {
          _isRecording[cameraId] = next;
          _notifyCamera(cameraId);
        }
      }
    } catch (e) {
      debugPrint('[RECORD] isRecording failed: $e');
    }
  }

  /// Start manual MP4 recording (`type=1`).
  Future<void> startRecord({
    required String cameraId,
    required String app,
    required String stream,
  }) async {
    final json = await _rapidGet('startRecord', {
      'type': '1',
      'vhost': '__defaultVhost__',
      'app': _appName(app),
      'stream': stream,
    });
    if (_isApiOk(json)) {
      _isRecording[cameraId] = true;
      _notifyCamera(cameraId);
      return;
    }
    throw Exception(_messageFrom(json, json, fallback: 'Lỗi bắt đầu ghi hình'));
  }

  /// Stop manual MP4 recording (`type=1`).
  Future<void> stopRecord({
    required String cameraId,
    required String app,
    required String stream,
  }) async {
    final json = await _rapidGet('stopRecord', {
      'type': '1',
      'vhost': '__defaultVhost__',
      'app': _appName(app),
      'stream': stream,
    });
    if (_isApiOk(json)) {
      _isRecording[cameraId] = false;
      _notifyCamera(cameraId);
      return;
    }
    throw Exception(_messageFrom(json, json, fallback: 'Lỗi dừng ghi hình'));
  }

  /// Toggle enableMp4 auto-record for a proxy camera.
  Future<void> toggleAutoRecord({
    required String cameraId,
    required bool enable,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final uri = Uri.parse('$_baseUrl/proxies/$cameraId');
    final res = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'enableMp4': enable}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Lỗi cập nhật cài đặt ghi hình');
    }
  }

  /// Delete a recording file.
  Future<void> deleteRecording({
    required String cameraId,
    required RecordingFile file,
  }) async {
    final json = await _rapidGet('deleteRecordDirectory', {
      'vhost': '__defaultVhost__',
      'app': file.app,
      'stream': file.stream,
      'period': file.date,
      'name': file.fileName,
    });
    if (_isApiOk(json)) {
      _cache[cameraId]?.removeWhere((r) => r.id == file.id);
      _notifyCamera(cameraId);
      return;
    }
    throw Exception(_messageFrom(json, json, fallback: 'Lỗi xóa bản ghi'));
  }

  static String errorText(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  /// Request a 30s clip from the backend.
  Future<String> requestClip(RecordingFile file, int startTime, int duration) async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    
    final uri = Uri.parse('$_baseUrl/recordings/clip');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'app': file.app,
        'stream': file.stream,
        'date': file.date,
        'fileName': file.fileName,
        'startTime': startTime,
        'duration': duration,
      }),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        return json['url'] as String;
      }
      throw Exception('Lỗi tạo bản cắt');
    } else {
      final json = jsonDecode(res.body);
      throw Exception(json['error'] ?? 'Lỗi tạo bản cắt');
    }
  }

  // helpers
  List<String> _datesBetween(String start, String end) {
    final dates = <String>[];
    DateTime cur = DateTime.parse(start);
    final endDate = DateTime.parse(end);
    while (!cur.isAfter(endDate)) {
      dates.add(cur.toIso8601String().split('T')[0]);
      cur = cur.add(const Duration(days: 1));
    }
    return dates;
  }

  String get todayStr => DateTime.now().toIso8601String().split('T')[0];
}
