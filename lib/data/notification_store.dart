import 'package:flutter/foundation.dart';

import '../core/commadesk_api.dart';

enum NotificationSeverity { danger, warning, info, subscription }

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

/// Inbox notifications from CommaDesk `GET /api/v1/notifications`.
/// AI retail alerts from `GET /api/v1/alerts` are merged when available.
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
    // Local-only toggles until CommaDesk exposes mobile alert prefs.
    notifyListeners();
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _loading;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> fetchAlerts() async {
    _loading = true;
    notifyListeners();

    try {
      final items = <AppNotification>[];

      // In-app inbox
      try {
        final raw = await CommaDeskApi.instance.getJson('/notifications');
        final data = CommaDeskApi.unwrapBody(raw);
        final list = data is Map && data['items'] is List
            ? CommaDeskApi.asMapList(data['items'])
            : CommaDeskApi.asMapList(data);

        for (final item in list) {
          final createdAt =
              DateTime.tryParse(item['created_at']?.toString() ?? '') ??
                  DateTime.now();
          items.add(AppNotification(
            id: item['id']?.toString() ?? '',
            title: item['title']?.toString() ?? 'Thông báo',
            message: item['body']?.toString() ?? '',
            source: item['sender_name']?.toString() ?? 'CommaDesk',
            time: _formatTime(createdAt),
            severity: NotificationSeverity.info,
            read: item['is_read'] == true || item['isRead'] == true,
          ));
        }
      } catch (e) {
        debugPrint('[NotificationStore] inbox error: $e');
      }

      // AI / retail alerts
      if (motionAlertsEnabled || offlineAlertsEnabled) {
        try {
          final raw = await CommaDeskApi.instance.getJson('/alerts');
          final list = raw is List
              ? CommaDeskApi.asMapList(raw)
              : CommaDeskApi.asMapList(CommaDeskApi.unwrapBody(raw));

          for (final item in list) {
            final title = item['title']?.toString() ??
                item['ref_event_id']?.toString() ??
                'Cảnh báo AI';
            if (!motionAlertsEnabled &&
                title.toLowerCase().contains('motion')) {
              continue;
            }
            if (!offlineAlertsEnabled &&
                (title.contains('Camera') || title.contains('offline'))) {
              continue;
            }

            final createdAt =
                DateTime.tryParse(item['created_at']?.toString() ?? '') ??
                    DateTime.now();
            final status = (item['status'] ?? '').toString().toLowerCase();
            final severity = status.contains('warn') || status.contains('danger')
                ? NotificationSeverity.warning
                : NotificationSeverity.info;

            items.add(AppNotification(
              id: 'alert_${item['ref_event_id'] ?? item['id'] ?? title}',
              title: title,
              message: item['message']?.toString() ?? '',
              source: item['instance_id']?.toString() ?? 'Camera AI',
              time: _formatTime(createdAt),
              severity: severity,
              read: false,
            ));
          }
        } catch (e) {
          debugPrint('[NotificationStore] alerts error: $e');
        }
      }

      _notifications
        ..clear()
        ..addAll(items);
    } catch (e) {
      debugPrint('[NotificationStore] fetchAlerts error: $e');
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

    try {
      await CommaDeskApi.instance.patch('/notifications/$id/read');
    } catch (e) {
      debugPrint('[NotificationStore] mark read failed: $e');
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();

    try {
      await CommaDeskApi.instance.patch('/notifications/read-all');
    } catch (e) {
      debugPrint('[NotificationStore] mark all read failed: $e');
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
  }

  void setMotionAlertsEnabled(bool value) {
    motionAlertsEnabled = value;
    notifyListeners();
    fetchAlerts();
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

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${time.day}/${time.month}/${time.year}';
  }
}
