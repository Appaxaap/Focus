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
  void Function(NotificationResponse response)? onNotificationResponse;

  bool _isInitialized = false;
  bool _isInitializing = false;
  Completer<void>? _initializationCompleter;

  bool get isInitialized => _isInitialized;
  bool get isSupported =>
      !kIsWeb &&
      (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isWindows ||
          Platform.isLinux);

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
      final windowsIconPath =
          '${File(Platform.resolvedExecutable).parent.path}\\data\\flutter_assets\\assets\\images\\tray_icon.ico';
      final windowsSettings = WindowsInitializationSettings(
        appName: 'Focus',
        appUserModelId: 'com.appaxaap.focus',
        guid: '1f0ea55f-2695-4f68-9f5f-0b8d3e20b913',
        iconPath: windowsIconPath,
      );

      final initialized = await _notificationsPlugin.initialize(
        InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
          macOS: iosSettings,
          windows: windowsSettings,
        ),
        onDidReceiveNotificationResponse: (response) {
          onNotificationResponse?.call(response);
          if (kDebugMode) {
            debugPrint('Notification tapped: ${response.payload}');
          }
        },
      );
      if (initialized != true) {
        throw StateError('Notification plugin initialization failed');
      }

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
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return true;
      }

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
    // Ensure one active reminder per notification ID to avoid duplicate toasts.
    await _notificationsPlugin.cancel(id);

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
    final taskPayload = payload ?? '';
    final windowsDetails = WindowsNotificationDetails(
      actions: [
        WindowsAction(
          content: 'Mark done',
          arguments: 'mark_done::$taskPayload',
        ),
        WindowsAction(
          content: 'Open task',
          arguments: 'open_task::$taskPayload',
        ),
      ],
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
        windows: windowsDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );

    if (kDebugMode) {
      debugPrint('Notification scheduled for $scheduled');
    }
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!isSupported) return;
    await onReady;

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final taskPayload = payload ?? '';
    final windowsDetails = WindowsNotificationDetails(
      actions: [
        WindowsAction(
          content: 'Mark done',
          arguments: 'mark_done::$taskPayload',
        ),
        WindowsAction(
          content: 'Open task',
          arguments: 'open_task::$taskPayload',
        ),
      ],
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
        windows: windowsDetails,
      ),
      payload: payload,
    );
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

  /// Returns a deterministic positive int ID for a task.
  /// Avoids relying on Dart's runtime hashCode for notification IDs.
  int notificationIdForTask(String taskId) {
    // 32-bit FNV-1a hash
    const int fnvPrime = 0x01000193;
    int hash = 0x811C9DC5;
    for (final codeUnit in taskId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    // Keep in signed 31-bit positive range for plugin/platform compatibility.
    return hash & 0x7FFFFFFF;
  }
}
