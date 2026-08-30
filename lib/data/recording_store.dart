import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../core/commadesk_api.dart';
import 'debounced_notifier.dart';

class RecordingFile {
  final String date;
  final String fileName;
  final String app;
  final String stream;
  final String serverUrl;
  final String token;

  RecordingFile({
    required this.date,
    required this.fileName,
    required this.app,
    required this.stream,
    required this.serverUrl,
    required this.token,
  });

  String get mp4Url => mp4Uri.toString();

  Uri get mp4Uri {
    var base = Uri.parse(serverUrl);
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
        if (token.isNotEmpty) 'token': token,
      },
    );
  }

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
      final dur = int.tryParse(parts[6]);
      if (dur != null && dur > 0) return 'Thời lượng: $dur giây';
    }
    return '';
  }

  String get id => '$date/$fileName';
}

class RecordingStore extends ChangeNotifier {
  static final RecordingStore instance = RecordingStore._();
  RecordingStore._();

  final Map<String, List<RecordingFile>> _cache = {};
  final Map<String, bool> _isRecording = {};
  final Map<String, bool> _loading = {};
  final IdListenables _cameraTicks = IdListenables();

  bool isRecording(String cameraId) => _isRecording[cameraId] ?? false;
  bool isLoading(String cameraId) => _loading[cameraId] ?? false;
  List<RecordingFile> recordingsFor(String cameraId) => _cache[cameraId] ?? [];

  Listenable listenableFor(String cameraId) => _cameraTicks.of(cameraId);
  void _notifyCamera(String cameraId) => _cameraTicks.bump(cameraId);

  String _appName(String? app) =>
      (app == null || app.trim().isEmpty) ? 'live' : app.trim();

  /// MediaServer `/index/api/*` via Luồng A (secret in dart-define) or CommaDesk proxy (JWT).
  Future<Map<String, dynamic>> _mediaGet(
    String action,
    Map<String, String> query, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (ApiConfig.hasMediaRecording) {
      return _directMediaGet(action, query, timeout: timeout);
    }
    return _proxyMediaGet(action, query, timeout: timeout);
  }

  Future<Map<String, dynamic>> _directMediaGet(
    String action,
    Map<String, String> query, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final params = {
      'secret': ApiConfig.mediaApiSecret,
      ...query,
    };
    final uri = Uri.parse('${ApiConfig.mediaManagementBase}/index/api/$action')
        .replace(queryParameters: params);

    final res = await http.get(uri).timeout(timeout);
    debugPrint('[RECORD] direct $action → ${res.statusCode}');
    return _parseMediaResponse(res, action);
  }

  Future<Map<String, dynamic>> _proxyMediaGet(
    String action,
    Map<String, String> query, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final res = await CommaDeskApi.instance.get(
      '/media-recording/$action',
      query: query,
      timeout: timeout,
    );
    debugPrint('[RECORD] proxy $action → ${res.statusCode}');
    if (res.statusCode == 503) {
      throw Exception(
        'Chưa cấu hình MEDIA_MANAGEMENT_URL và MEDIA_API_SECRET trên máy chủ CommaDesk',
      );
    }
    return _parseMediaResponse(res, action);
  }

  Map<String, dynamic> _parseMediaResponse(http.Response res, String action) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('unexpected body');
      }
      json = decoded;
    } catch (_) {
      if (res.statusCode == 401 || res.statusCode == 403) {
        throw Exception('Không có quyền ghi hình');
      }
      throw Exception('Máy chủ ghi hình trả về lỗi (${res.statusCode})');
    }

    if (res.statusCode != 200) {
      final err = json['error']?.toString();
      if (err != null && err.isNotEmpty) {
        throw Exception(err);
      }
      throw Exception(_messageFrom(json, json, fallback: 'Lỗi ghi hình'));
    }
    return json;
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
    final raw = (payload['msg'] ?? json['error'] ?? json['message'])
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

  Future<void> fetchRecordings({
    required String cameraId,
    required String app,
    required String stream,
    required String serverUrl,
    required String startDate,
    required String endDate,
  }) async {
    final token = await CommaDeskApi.instance.readAccessToken() ?? '';
    _loading[cameraId] = true;
    _notifyCamera(cameraId);

    final resolvedApp = _appName(app);
    final allDates = _datesBetween(startDate, endDate);
    final dates = allDates.length <= 7
        ? allDates
        : allDates.sublist(allDates.length - 7);
    final results = <RecordingFile>[];

    try {
      await Future.wait(dates.map((d) async {
        try {
          final json = await _mediaGet('getMP4RecordFile', {
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
                serverUrl: ApiConfig.mediaPublicBase,
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

  Future<void> checkRecordStatus({
    required String cameraId,
    required String app,
    required String stream,
  }) async {
    try {
      final json = await _mediaGet(
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

  Future<void> startRecord({
    required String cameraId,
    required String app,
    required String stream,
  }) async {
    final json = await _mediaGet('startRecord', {
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

  Future<void> stopRecord({
    required String cameraId,
    required String app,
    required String stream,
  }) async {
    final json = await _mediaGet('stopRecord', {
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

  Future<void> deleteRecording({
    required String cameraId,
    required RecordingFile file,
  }) async {
    final json = await _mediaGet('deleteRecordDirectory', {
      'vhost': '__defaultVhost__',
      'app': file.app,
      'stream': file.stream,
      'period': file.date,
      'name': file.fileName,
    });
    if (_isApiOk(json)) {
      final list = _cache[cameraId];
      if (list != null) {
        _cache[cameraId] = list.where((r) => r.id != file.id).toList();
        _notifyCamera(cameraId);
      }
      return;
    }
    throw Exception(_messageFrom(json, json, fallback: 'Lỗi xóa bản ghi'));
  }

  /// Auto-record toggle is not exposed on CommaDesk catalog yet.
  Future<void> toggleAutoRecord({
    required String cameraId,
    required bool enable,
  }) async {
    debugPrint(
      '[RECORD] toggleAutoRecord($cameraId, $enable) — chưa có API CommaDesk tương đương',
    );
  }

  static String errorText(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  /// Request a clip — CommaDesk chưa có `/recordings/clip`; cần MediaServer trực tiếp.
  Future<String> requestClip(
    RecordingFile file,
    int startTime,
    int duration,
  ) async {
    if (!ApiConfig.hasMediaRecording) {
      throw Exception(
        'Cắt clip thủ công chưa hỗ trợ qua CommaDesk API — dùng dashboard hoặc MediaServer.',
      );
    }
    throw Exception(
      'Cắt clip thủ công chưa hỗ trợ qua CommaDesk API — dùng dashboard hoặc MediaServer.',
    );
  }

  List<String> _datesBetween(String start, String end) {
    final s = DateTime.tryParse(start);
    final e = DateTime.tryParse(end);
    if (s == null || e == null) return [start];
    final out = <String>[];
    var cur = DateTime(s.year, s.month, s.day);
    final last = DateTime(e.year, e.month, e.day);
    while (!cur.isAfter(last)) {
      out.add(
        '${cur.year.toString().padLeft(4, '0')}-'
        '${cur.month.toString().padLeft(2, '0')}-'
        '${cur.day.toString().padLeft(2, '0')}',
      );
      cur = cur.add(const Duration(days: 1));
    }
    return out;
  }
}
