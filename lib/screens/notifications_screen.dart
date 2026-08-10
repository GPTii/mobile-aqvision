import 'package:flutter/material.dart';

import '../data/notification_store.dart';
import '../theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationStore.instance,
      builder: (context, _) {
        final notifications = NotificationStore.instance.notifications;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: _Header(context: context, hasUnread: NotificationStore.instance.unreadCount > 0),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      const _SectionLabel('Cài đặt cảnh báo'),
                      const SizedBox(height: 10),
                      const _SettingsCard(),
                      const SizedBox(height: 24),
                      const _SectionLabel('Gần đây'),
                      const SizedBox(height: 10),
                      if (notifications.isEmpty)
                        const _EmptyNotifications()
                      else
                        _NotificationList(notifications: notifications),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final BuildContext context;
  final bool hasUnread;

  const _Header({required this.context, required this.hasUnread});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'Thông báo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: hasUnread ? () => NotificationStore.instance.markAllAsRead() : null,
            child: Text(
              'Đánh dấu đã đọc',
              style: TextStyle(
                color: hasUnread ? AppColors.accent : AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    final store = NotificationStore.instance;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _SettingRow(
            icon: Icons.directions_walk_rounded,
            label: 'Phát hiện chuyển động',
            value: store.motionAlertsEnabled,
            onChanged: (v) => store.setMotionAlertsEnabled(v),
          ),
          Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
          _SettingRow(
            icon: Icons.wifi_off_rounded,
            label: 'Camera mất kết nối',
            value: store.offlineAlertsEnabled,
            onChanged: (v) => store.setOfflineAlertsEnabled(v),
          ),
          Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
          _SettingRow(
            icon: Icons.info_outline_rounded,
            label: 'Cập nhật hệ thống',
            value: store.systemAlertsEnabled,
            onChanged: (v) => store.setSystemAlertsEnabled(v),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
          Switch.adaptive(
            activeColor: AppColors.accent,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<AppNotification> notifications;

  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: List.generate(notifications.length, (i) {
          final notif = notifications[i];
          return Column(
            children: [
              _NotificationTile(notification: notif),
              if (i != notifications.length - 1)
                Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  Color get _color {
    switch (notification.severity) {
      case NotificationSeverity.danger:
        return AppColors.danger;
      case NotificationSeverity.warning:
        return AppColors.warning;
      case NotificationSeverity.info:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (notification.severity) {
      case NotificationSeverity.danger:
        return Icons.error_rounded;
      case NotificationSeverity.warning:
        return Icons.wifi_off_rounded;
      case NotificationSeverity.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => NotificationStore.instance.markAsRead(notification.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 18, color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${notification.source} · ${notification.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        'Không có thông báo nào',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
      ),
    );
  }
}
