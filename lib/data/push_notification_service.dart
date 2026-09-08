import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/notifications_screen.dart';
import '../utils/network_error_handler.dart';
import 'notification_store.dart';

/// Displays real OS-level notifications (lock screen / notification tray),
/// backed by Firebase Cloud Messaging.
///
/// - App in foreground: FCM never auto-shows a system notification, so we
///   render one ourselves via `flutter_local_notifications` on every
///   `FirebaseMessaging.onMessage`.
/// - App in background/terminated with a `notification` payload block: the
///   OS already shows it automatically (nothing to do here).
/// - App in background/terminated with a data-only payload: the background
///   handler renders it manually, same as the foreground path.
/// - Tapping the notification (from any state) opens the in-app
///   Notifications screen.
class PushNotificationService {
  PushNotificationService._();

  static const String _channelId = 'aqpc_default_channel';
  static const String _channelName = 'Thông báo';
  static const String _channelDesc = 'Thông báo hệ thống, camera và cảnh báo từ AQ Vision';

  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static int _nextId = 0;

  static bool _pluginReady = false;

  /// Sets up the local-notifications plugin + Android channel. Safe to call
  /// from both the main isolate and the background message isolate.
  static Future<void> _ensurePlugin() async {
    if (_pluginReady) return;
    _pluginReady = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) => _openNotificationsScreen(),
    );

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ));

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Full setup, called once from the main isolate at app start: plugin +
  /// channel + the foreground/tap listeners.
  static Future<void> init() async {
    await _ensurePlugin();

    // Foreground: FCM delivers the message but never shows a system
    // notification on its own — we must draw it ourselves.
    FirebaseMessaging.onMessage.listen((message) {
      _show(message);
      NotificationStore.instance.fetchAlerts();
    });

    // Background/terminated: user tapped the system notification tray entry.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _openNotificationsScreen();
    });

    // App was launched from a terminated state by tapping a notification.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _openNotificationsScreen();
    }
  }

  /// Used by the background message isolate: only prepares the plugin, does
  /// not touch FCM stream listeners (those belong to the main isolate).
  static Future<void> showFromRemoteMessageInBackground(RemoteMessage message) async {
    await _ensurePlugin();
    await _show(message);
  }

  static Future<void> _show(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString() ?? message.data['message']?.toString();

    if (title == null && body == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _local.show(
      _nextId++,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }

  static void _openNotificationsScreen() {
    final navigator = globalNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }
}
