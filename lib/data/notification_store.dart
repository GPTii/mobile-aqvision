import 'package:flutter/foundation.dart';

enum NotificationSeverity { danger, warning, info }

class AppNotification {
  final String id;
  final String title;
  final String source;
  final String time;
  final NotificationSeverity severity;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.source,
    required this.time,
    required this.severity,
    this.read = false,
  });
}

/// Notifications feed + per-type alert preferences, shared across the app
/// so the bell badge and the settings toggles stay in sync.
class NotificationStore extends ChangeNotifier {
  static final NotificationStore instance = NotificationStore._();

  final List<AppNotification> _notifications = [];
  int _seq = 0;

  bool motionAlertsEnabled = true;
  bool offlineAlertsEnabled = true;
  bool systemAlertsEnabled = true;

  NotificationStore._() {
    _seedInitialData();
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.read).length;

  void markAsRead(String id) {
    for (final n in _notifications) {
      if (n.id == id) {
        n.read = true;
        break;
      }
    }
    notifyListeners();
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void setMotionAlertsEnabled(bool value) {
    motionAlertsEnabled = value;
    notifyListeners();
  }

  void setOfflineAlertsEnabled(bool value) {
    offlineAlertsEnabled = value;
    notifyListeners();
  }

  void setSystemAlertsEnabled(bool value) {
    systemAlertsEnabled = value;
    notifyListeners();
  }

  void _add({
    required String title,
    required String source,
    required String time,
    required NotificationSeverity severity,
    bool read = false,
  }) {
    _notifications.add(
      AppNotification(
        id: 'notif_${_seq++}',
        title: title,
        source: source,
        time: time,
        severity: severity,
        read: read,
      ),
    );
  }

  void _seedInitialData() {
    _add(
      title: 'Phát hiện chuyển động bất thường',
      source: 'Cổng chính',
      time: '5 phút trước',
      severity: NotificationSeverity.danger,
    );
    _add(
      title: 'Camera mất kết nối',
      source: 'Kho hàng',
      time: '22 phút trước',
      severity: NotificationSeverity.warning,
    );
    _add(
      title: 'Cập nhật firmware thành công',
      source: 'Hệ thống',
      time: '1 giờ trước',
      severity: NotificationSeverity.info,
      read: true,
    );
    _add(
      title: 'Camera mất kết nối',
      source: 'Bãi đỗ xe ngoài',
      time: '3 giờ trước',
      severity: NotificationSeverity.warning,
      read: true,
    );
    _add(
      title: 'Phát hiện chuyển động bất thường',
      source: 'Phòng khách - Cam 3',
      time: 'Hôm qua',
      severity: NotificationSeverity.danger,
      read: true,
    );
  }
}
