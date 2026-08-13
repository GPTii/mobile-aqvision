import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SystemStats {
  final int totalCameras;
  final int onlineCameras;
  final int offlineCameras;
  final double cpuLoadPercent;
  final int ramTotal;
  final int ramUsed;
  final int ramFree;
  final int diskTotal;
  final int diskUsed;
  final int diskFree;

  SystemStats({
    required this.totalCameras,
    required this.onlineCameras,
    required this.offlineCameras,
    required this.cpuLoadPercent,
    required this.ramTotal,
    required this.ramUsed,
    required this.ramFree,
    required this.diskTotal,
    required this.diskUsed,
    required this.diskFree,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    final cams = json['cameras'] ?? {};
    final sys = json['system'] ?? {};
    final cpu = sys['cpu'] ?? {};
    final ram = sys['ram'] ?? {};
    final disk = sys['disk'] ?? {};

    return SystemStats(
      totalCameras: cams['total'] ?? 0,
      onlineCameras: cams['online'] ?? 0,
      offlineCameras: cams['offline'] ?? 0,
      cpuLoadPercent: (cpu['loadPercent'] ?? 0.0).toDouble(),
      ramTotal: ram['total'] ?? 0,
      ramUsed: ram['used'] ?? 0,
      ramFree: ram['free'] ?? 0,
      diskTotal: disk['total'] ?? 0,
      diskUsed: disk['used'] ?? 0,
      diskFree: disk['free'] ?? 0,
    );
  }
}

class StatsStore extends ChangeNotifier {
  static final StatsStore instance = StatsStore._();

  StatsStore._();

  SystemStats? _stats;
  SystemStats? get stats => _stats;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get _baseUrl {
    if (kIsWeb) {
      final port = Uri.base.port;
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : "localhost";
      if (port != 3002 && (host == 'localhost' || host == '127.0.0.1')) {
        return "http://$host:3002/api/v1";
      }
      return "${Uri.base.scheme}://${Uri.base.authority}/api/v1";
    }
    return "https://api.aqvision.net/api/v1";
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> fetchStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return;

      final uri = Uri.parse("$_baseUrl/stats");
      final res = await http.get(uri, headers: {
        "Authorization": "Bearer $token",
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        _stats = SystemStats.fromJson(json);
      }
    } catch (e) {
      // Ignore errors for now
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
