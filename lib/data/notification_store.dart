import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationSeverity { danger, warning, info }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String source;
  final String time;
  final NotificationSeverity severity;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    this.message = '',
    required this.source,
    required this.time,
    required this.severity,
    this.read = false,
  });
}

/// Notifications feed backed by the real `/api/v1/notifications` API.
/// Falls back to empty list on error.
class NotificationStore extends ChangeNotifier {
  static final NotificationStore instance = NotificationStore._();

  final List<AppNotification> _notifications = [];
  bool _loading = false;

  bool motionAlertsEnabled = true;
  bool offlineAlertsEnabled = true;
  bool systemAlertsEnabled = true;

  NotificationStore._();

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _loading;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  String get _baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://$host:3002/api';
      }
      return '${Uri.base.scheme}://${Uri.base.authority}/api';
    }
    return 'https://dev1.aqvision.net/api';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Fetch real system alerts from the backend.
  Future<void> fetchAlerts() async {
    final token = await _getToken();
    if (token == null) return;

    _loading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/v1/notifications');
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List data = json['data']?['items'] ?? [];

        // Get cleared timestamp from prefs
        final prefs = await SharedPreferences.getInstance();
        final clearedAt = prefs.getInt('alerts_cleared_at') ?? 0;
        final readAt = prefs.getInt('alerts_read_at') ?? 0;

        _notifications.clear();
        for (int i = 0; i < data.length; i++) {
          final item = data[i];
          final alertTime = DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now();
          final alertMs = alertTime.millisecondsSinceEpoch;

          // Skip alerts that were cleared locally
          if (alertMs <= clearedAt) continue;

          // Map server type to Flutter severity
          NotificationSeverity severity;
          switch (item['type']) {
            case 'critical':
            case 'error':
              severity = NotificationSeverity.danger;
              break;
            case 'warning':
              severity = NotificationSeverity.warning;
              break;
            default:
              severity = NotificationSeverity.info;
          }

          // Filter by user preferences
          final title = item['title'] ?? '';
          if (!offlineAlertsEnabled && title.contains('Camera')) continue;
          if (!systemAlertsEnabled && (title.contains('CPU') || title.contains('Memory') || title.contains('Disk'))) continue;

          _notifications.add(AppNotification(
            id: item['id']?.toString() ?? 'alert_$i',
            title: title,
            message: item['message'] ?? '',
            source: item['source'] ?? _extractSource(title),
            time: _formatTime(alertTime),
            severity: severity,
            read: item['isRead'] == true || alertMs <= readAt,
          ));
        }
      }
    } catch (e) {
      debugPrint('NotificationStore.fetchAlerts error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    for (final n in _notifications) {
      if (n.id == id) {
        n.read = true;
        break;
      }
    }
    notifyListeners();
    
    final token = await _getToken();
    if (token == null) return;
    try {
      await http.patch(
        Uri.parse('$_baseUrl/v1/notifications'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.read = true;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alerts_read_at', DateTime.now().millisecondsSinceEpoch);
    notifyListeners();

    final token = await _getToken();
    if (token == null) return;
    try {
      await http.patch(
        Uri.parse('$_baseUrl/v1/notifications'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
    } catch (_) {}
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alerts_cleared_at', DateTime.now().millisecondsSinceEpoch);
    _notifications.clear();
    notifyListeners();
  }

  void setMotionAlertsEnabled(bool value) {
    motionAlertsEnabled = value;
    notifyListeners();
    fetchAlerts(); // Refresh with new filter
  }

  void setOfflineAlertsEnabled(bool value) {
    offlineAlertsEnabled = value;
    notifyListeners();
    fetchAlerts();
  }

  void setSystemAlertsEnabled(bool value) {
    systemAlertsEnabled = value;
    notifyListeners();
    fetchAlerts();
  }

  // --- Helpers ---

  String _extractSource(String title) {
    if (title.contains('Camera')) return 'Camera';
    if (title.contains('CPU') || title.contains('Memory') || title.contains('Disk')) return 'Hệ thống';
    return 'Hệ thống';
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${time.day}/${time.month}/${time.year}';
  }
}
