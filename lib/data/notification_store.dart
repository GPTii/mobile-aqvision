import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/app_strings.dart';
import '../utils/server_text.dart';

enum NotificationSeverity { danger, warning, info, subscription }

class AppNotification {
  final String id;

  /// Raw server text (Vietnamese) — use [displayTitle] / [displayMessage] in UI.
  final String title;
  final String message;
  final String rawSource;
  final DateTime createdAt;
  final NotificationSeverity severity;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    this.message = '',
    required this.rawSource,
    required this.createdAt,
    required this.severity,
    this.read = false,
  });

  // Localized at render time so switching language updates existing items.
  String get displayTitle => localizeServerText(title);
  String get displayMessage => localizeServerText(message);

  String get source {
    if (rawSource == 'camera' || rawSource.contains('Camera')) return 'Camera';
    if (rawSource.contains('CPU') || rawSource.contains('Memory') || rawSource.contains('Disk')) return 'Hệ thống'.tr;
    return rawSource.isNotEmpty ? rawSource : 'Hệ thống'.tr;
  }

  String get time {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Vừa xong'.tr;
    if (diff.inMinutes < 60) return '{n} phút trước'.trArgs({'n': diff.inMinutes});
    if (diff.inHours < 24) return '{n} giờ trước'.trArgs({'n': diff.inHours});
    if (diff.inDays < 7) return '{n} ngày trước'.trArgs({'n': diff.inDays});
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

/// Notifications feed backed by the real `/api/system/alerts` API.
/// When called from Mobile with Bearer token, backend returns
/// user-scoped Notifications from DB instead of system-wide alerts.
class NotificationStore extends ChangeNotifier {
  static final NotificationStore instance = NotificationStore._();

  final List<AppNotification> _notifications = [];
  bool _loading = false;

  bool motionAlertsEnabled = true;
  bool offlineAlertsEnabled = true;
  bool systemAlertsEnabled = true;

  NotificationStore._() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    motionAlertsEnabled = prefs.getBool('motionAlertsEnabled') ?? true;
    offlineAlertsEnabled = prefs.getBool('offlineAlertsEnabled') ?? true;
    systemAlertsEnabled = prefs.getBool('systemAlertsEnabled') ?? true;
    notifyListeners();
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _loading;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  String get _baseUrl => ApiConfig.apiBase;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Fetch user-scoped notifications from the backend.
  /// The `/api/system/alerts` endpoint detects Bearer token and returns
  /// only the current user's notifications from the Notification table.
  Future<void> fetchAlerts() async {
    final token = await _getToken();
    if (token == null) return;

    _loading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/system/alerts');
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List data = json['data'] ?? [];

        _notifications.clear();
        for (int i = 0; i < data.length; i++) {
          final item = data[i];
          final alertTime = DateTime.tryParse(item['time'] ?? '') ?? DateTime.now();

          // Map server type to Flutter severity
          NotificationSeverity severity;
          switch (item['type']) {
            case 'error':
            case 'critical':
              severity = NotificationSeverity.danger;
              break;
            case 'warning':
              severity = NotificationSeverity.warning;
              break;
            case 'subscription':
              severity = NotificationSeverity.subscription;
              break;
            default:
              severity = NotificationSeverity.info;
          }

          // Filter by user preferences
          final title = item['title'] ?? '';
          if (!offlineAlertsEnabled &&
              (title.contains('Camera') || title.contains('ngắt kết nối') || title.contains('kết nối lại'))) continue;
          if (!systemAlertsEnabled &&
              (title.contains('CPU') ||
                  title.contains('Memory') ||
                  title.contains('Disk') ||
                  title.contains('Cập nhật'))) continue;
          if (!motionAlertsEnabled && (title.contains('chuyển động') || title.toLowerCase().contains('motion')))
            continue;

          _notifications.add(AppNotification(
            id: item['id']?.toString() ?? 'alert_$i',
            title: title,
            message: item['message'] ?? '',
            rawSource: item['source'] as String? ?? title,
            createdAt: alertTime,
            severity: severity,
            read: item['read'] == true || item['isRead'] == true,
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

  /// Mark a single notification as read (synced to server).
  void markAsRead(String id) async {
    for (final n in _notifications) {
      if (n.id == id) {
        n.read = true;
        break;
      }
    }
    notifyListeners();

    final token = await _getToken();
    if (token != null) {
      try {
        await http.patch(
          Uri.parse('${ApiConfig.apiV1Base}/notifications'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'id': id}),
        );
      } catch (e) {
        debugPrint('Failed to mark notification as read: $e');
      }
    }
  }

  /// Mark all notifications as read (synced to server).
  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();

    final token = await _getToken();
    if (token != null) {
      try {
        await http.patch(
          Uri.parse('${ApiConfig.apiV1Base}/notifications'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({}),
        );
      } catch (e) {
        debugPrint('Failed to mark all notifications as read: $e');
      }
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
  }

  void setMotionAlertsEnabled(bool value) async {
    motionAlertsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('motionAlertsEnabled', value);
    notifyListeners();
    _syncPrefsWithServer();
    fetchAlerts();
  }

  void setOfflineAlertsEnabled(bool value) async {
    offlineAlertsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offlineAlertsEnabled', value);
    notifyListeners();
    _syncPrefsWithServer();
    fetchAlerts();
  }

  void setSystemAlertsEnabled(bool value) async {
    systemAlertsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('systemAlertsEnabled', value);
    notifyListeners();
    _syncPrefsWithServer();
    fetchAlerts();
  }

  Future<void> _syncPrefsWithServer() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      await http.patch(
        Uri.parse('${ApiConfig.apiV1Base}/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'motionAlerts': motionAlertsEnabled,
          'offlineAlerts': offlineAlertsEnabled,
          'systemAlerts': systemAlertsEnabled,
        }),
      );
    } catch (e) {
      debugPrint('Failed to sync prefs with server: $e');
    }
  }
}
