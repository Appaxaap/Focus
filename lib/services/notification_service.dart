import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isInitializing = false;
  Completer<void>? _initializationCompleter;

  bool get isInitialized => _isInitialized;
  bool get isSupported => !Platform.isWindows;

  // Public readiness gate
  Future<void> get onReady async {
    if (!isSupported) return;
    if (_isInitialized) return;

    _initializationCompleter ??= Completer<void>();

    if (!_isInitializing) {
      _initialize();
    }

    return _initializationCompleter!.future;
  }

  void initialize() {
    if (!isSupported || _isInitialized || _isInitializing) return;
    _initializationCompleter ??= Completer<void>();
    _initialize();
  }

  Future<void> _initialize() async {
    _isInitializing = true;

    try {
      tz.initializeTimeZones();
      await _setDeviceTimezone();

      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _notificationsPlugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: (response) {
          if (kDebugMode) {
            debugPrint('Notification tapped: ${response.payload}');
          }
        },
      );

      _isInitialized = true;
      _initializationCompleter?.complete();
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Notification init failed: $e');
        debugPrint('$s');
      }

      _initializationCompleter?.completeError(e, s);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _setDeviceTimezone() async {
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    if (kDebugMode) {
      final now = tz.TZDateTime.now(tz.local);
      debugPrint('Timezone: ${tz.local.name}');
      debugPrint('Local time: $now');
    }
  }

  Future<void> _createNotificationChannel() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) return;

    const channel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Notifications for upcoming tasks',
      importance: Importance.max,
    );

    await android.createNotificationChannel(channel);

    if (kDebugMode) {
      debugPrint('Notification channel created: ${channel.id}');
    }
  }

  Future<bool> requestAllPermissions() async {
    if (!isSupported) return false;

    try {
      final notification = await Permission.notification.request();
      if (!notification.isGranted) return false;

      if (Platform.isAndroid) {
        final exactAlarm = await Permission.scheduleExactAlarm.status;
        if (!exactAlarm.isGranted) {
          final android = _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

          final allowed =
              await android?.requestExactAlarmsPermission() ?? false;

          if (!allowed) return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Permission error: $e');
      }
      return false;
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!isSupported) return;

    await onReady;

    final scheduled = tz.TZDateTime.from(scheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    if (!scheduled.isAfter(now)) {
      throw PlatformException(
        code: 'INVALID_TIME',
        message: 'Cannot schedule notification in the past',
      );
    }

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    if (kDebugMode) {
      debugPrint('Notification scheduled for $scheduled');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!isSupported) return;
    await onReady;
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    if (!isSupported) return;
    await onReady;
    await _notificationsPlugin.cancelAll();
  }

  Future<void> debugPendingNotifications() async {
    if (!kDebugMode || !_isInitialized) return;

    final pending = await _notificationsPlugin.pendingNotificationRequests();

    debugPrint('Pending notifications: ${pending.length}');
    for (final n in pending) {
      debugPrint('ID ${n.id} | ${n.title}');
    }
  }
}
