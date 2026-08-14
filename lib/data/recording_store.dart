import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecordingFile {
  final String date;       // YYYY-MM-DD
  final String fileName;   // e.g. 08-30-00.mp4
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

  String get mp4Url =>
      '$serverUrl/record/$app/$stream/$date/$fileName?access_token=$token';

  String get displayTime {
    final parts = fileName.replaceAll('.mp4', '').split('-');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return fileName;
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

  bool isRecording(String cameraId) => _isRecording[cameraId] ?? false;
  bool isLoading(String cameraId) => _loading[cameraId] ?? false;
  List<RecordingFile> recordingsFor(String cameraId) =>
      _cache[cameraId] ?? [];

  String get _baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      final port = Uri.base.port;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://$host:3002/api';
      }
      return '${Uri.base.scheme}://${Uri.base.authority}/api';
    }
    return 'http://dev1.aqvision.net/api';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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
    final token = await _getToken();
    if (token == null) return;
    _loading[cameraId] = true;
    notifyListeners();

    final dates = _datesBetween(startDate, endDate);
    final results = <RecordingFile>[];

    try {
      await Future.wait(dates.take(7).map((d) async {
        try {
          final uri = Uri.parse(
              '$_baseUrl/rapidmedia/getMP4RecordFile?vhost=__defaultVhost__&app=$app&stream=$stream&period=$d');
          final res = await http.get(uri, headers: {
            'Authorization': 'Bearer $token',
          }).timeout(const Duration(seconds: 10));
          if (res.statusCode == 200) {
            final json = jsonDecode(res.body);
            if (json['code'] == 0 && json['data']?['paths'] != null) {
              final paths = (json['data']['paths'] as List).cast<String>();
              for (final p in paths.reversed) {
                results.add(RecordingFile(
                  date: d,
                  fileName: p,
                  app: app,
                  stream: stream,
                  serverUrl: '$_baseUrl/media',
                  token: token,
                ));
              }
            }
          }
        } catch (_) {}
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
      notifyListeners();
    }
  }

  /// Check if a camera is currently recording.
  Future<void> checkRecordStatus({
    required String cameraId,
    required String app,
    required String stream,
  }) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final uri = Uri.parse(
          '$_baseUrl/rapidmedia/isRecording?type=0&vhost=__defaultVhost__&app=$app&stream=$stream');
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        _isRecording[cameraId] = (json['status'] == true || json['status'] == 1);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Start manual recording.
  Future<void> startRecord({
    required String cameraId,
    required String app,
    required String stream,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final uri = Uri.parse(
        '$_baseUrl/rapidmedia/startRecord?type=0&vhost=__defaultVhost__&app=$app&stream=$stream');
    final res = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      _isRecording[cameraId] = true;
      notifyListeners();
    } else {
      throw Exception('Lỗi bắt đầu ghi hình');
    }
  }

  /// Stop manual recording.
  Future<void> stopRecord({
    required String cameraId,
    required String app,
    required String stream,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final uri = Uri.parse(
        '$_baseUrl/rapidmedia/stopRecord?type=0&vhost=__defaultVhost__&app=$app&stream=$stream');
    final res = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      _isRecording[cameraId] = false;
      notifyListeners();
    } else {
      throw Exception('Lỗi dừng ghi hình');
    }
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
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final uri = Uri.parse(
        '$_baseUrl/rapidmedia/deleteRecordDirectory?vhost=__defaultVhost__&app=${file.app}&stream=${file.stream}&period=${file.date}&path=${file.fileName}');
    final res = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      _cache[cameraId]?.removeWhere((r) => r.id == file.id);
      notifyListeners();
    } else {
      throw Exception('Lỗi xóa bản ghi');
    }
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
