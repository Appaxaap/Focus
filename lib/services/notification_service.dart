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
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isInitializing = false;
  Completer<void>? _initializationCompleter;

  bool get isInitialized => _isInitialized;

  /// Ensure service is ready before using
  Future<void> get onReady async {
    if (_isInitialized) return;
    if (!_isInitializing) {
      initialize();
    }
    return _initializationCompleter?.future ?? Future.value();
  }

  void initialize() {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;
    _initializationCompleter = Completer<void>();
    _init();
  }

  Future<void> _init() async {
    try {
      tz.initializeTimeZones();
      await _setDeviceTimezone();

      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (kDebugMode) {
            print('🔔 Notification tapped: ${response.payload}');
          }
        },
      );

      _isInitialized = true;
      _isInitializing = false;
      _initializationCompleter?.complete();
    } catch (e, s) {
      if (kDebugMode) {
        print('❌ Notification init failed: $e');
        print(s);
      }
      _isInitializing = false;
      _initializationCompleter?.completeError(e, s);
    }
  }

  Future<void> setTimezone(String timezoneName) async {
    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
      if (kDebugMode) {
        final now = tz.TZDateTime.now(tz.local);
        print('✅ Manually set timezone to: ${tz.local.name}');
        print('🕒 Current time: $now');
        print('⏰ UTC offset: ${now.timeZoneOffset}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to set timezone $timezoneName: $e');
      }
      throw e;
    }
  }

  /// Enhanced timezone detection and setup
  Future<void> _setDeviceTimezone() async {
    try {
      final String tzName = await FlutterTimezone.getLocalTimezone();

      if (kDebugMode) {
        print('🌍 Detected timezone: $tzName');
      }

      // Try to set the detected timezone
      try {
        tz.setLocalLocation(tz.getLocation(tzName));
        if (kDebugMode) {
          print('✅ Timezone set to: ${tz.local.name}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to set timezone $tzName: $e');
        }

        // Fallback: Try common UAE timezones
        final fallbackTimezones = [
          'Asia/Dubai',
          'Asia/Muscat', // Same as Dubai (+4)
          'UTC',
        ];

        for (final fallback in fallbackTimezones) {
          try {
            tz.setLocalLocation(tz.getLocation(fallback));
            if (kDebugMode) {
              print('✅ Fallback timezone set to: $fallback');
            }
            break;
          } catch (e) {
            if (kDebugMode) {
              print('❌ Fallback $fallback failed: $e');
            }
          }
        }
      }

      // Final verification
      final now = tz.TZDateTime.now(tz.local);
      final offset = now.timeZoneOffset;

      if (kDebugMode) {
        print('🕒 Final timezone: ${tz.local.name}');
        print('⏰ UTC offset: ${offset.inHours}h ${offset.inMinutes % 60}m');
        print('📅 Local time: $now');
        print('🌍 UTC time: ${now.toUtc()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in timezone detection: $e');
      }

      // Ultimate fallback to Dubai
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Dubai'));
        if (kDebugMode) {
          print('✅ Ultimate fallback to Dubai timezone');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Ultimate fallback failed, using UTC: $e');
        }
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }
  }

  /// Create notification channel with enhanced settings (Android)
  Future<void> _createNotificationChannel() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      const channel = AndroidNotificationChannel(
        'task_reminders',
        'Task Reminders',
        description: 'Notifications for upcoming tasks',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
      );

      await androidImplementation.createNotificationChannel(channel);

      if (kDebugMode) {
        print('✅ Created notification channel: ${channel.id}');

        // Verify channel was created
        final channels = await androidImplementation.getNotificationChannels();
        final ourChannel = channels?.firstWhere(
          (c) => c.id == 'task_reminders',
          orElse: () =>
              const AndroidNotificationChannel('', '', description: ''),
        );

        if (ourChannel?.id == 'task_reminders') {
          print('✅ Channel verification successful');
          print('   📢 Importance: ${ourChannel?.importance}');
          print('   🔊 Sound: ${ourChannel?.playSound}');
          print('   📳 Vibration: ${ourChannel?.enableVibration}');
        } else {
          print('❌ Channel verification failed');
        }
      }
    }
  }

  /// Enhanced permission checking and requesting
  Future<bool> requestAllPermissions() async {
    try {
      if (kDebugMode) {
        print('🔐 Starting comprehensive permission check...');
      }

      // Check basic notification permission
      final notificationStatus = await Permission.notification.status;
      if (kDebugMode) {
        print('📱 Current notification permission: $notificationStatus');
      }

      if (!notificationStatus.isGranted) {
        final newStatus = await Permission.notification.request();
        if (kDebugMode) {
          print('📱 After request notification permission: $newStatus');
        }
        if (!newStatus.isGranted) {
          if (kDebugMode) {
            print('❌ Basic notification permission denied');
          }
          return false;
        }
      }

      // Android-specific permissions
      if (Platform.isAndroid) {
        // Check exact alarm permission (Android 12+)
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (kDebugMode) {
          print('⏰ Exact alarm permission: $exactAlarmStatus');
        }

        if (!exactAlarmStatus.isGranted) {
          final androidImplementation = _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

          if (androidImplementation != null) {
            final canSchedule =
                await androidImplementation.requestExactAlarmsPermission() ??
                false;

            if (kDebugMode) {
              print('⏰ Exact alarms permission result: $canSchedule');
            }

            if (!canSchedule) {
              if (kDebugMode) {
                print('❌ Exact alarms permission denied');
              }
              return false;
            }
          }
        }

        // Check and request battery optimization exemption
        final batteryStatus =
            await Permission.ignoreBatteryOptimizations.status;
        if (kDebugMode) {
          print('🔋 Battery optimization status: $batteryStatus');
        }

        if (batteryStatus.isDenied) {
          final batteryResult = await Permission.ignoreBatteryOptimizations
              .request();
          if (kDebugMode) {
            print('🔋 Battery optimization after request: $batteryResult');
          }
        }
      }

      if (kDebugMode) {
        print('✅ All critical permissions granted');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting permissions: $e');
      }
      return false;
    }
  }

  /// Enhanced notification scheduling with better debugging
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await onReady; // Ensure initialization

    // Create timezone-aware datetime
    final scheduledTZ = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
    );

    final now = tz.TZDateTime.now(tz.local);

    if (kDebugMode) {
      print('🔧 ENHANCED NOTIFICATION DEBUG:');
      print('   📍 Local timezone: ${tz.local.name}');
      print(
        '   📅 Input DateTime: $scheduledDate (${scheduledDate.runtimeType})',
      );
      print('   🎯 Scheduled TZ DateTime: $scheduledTZ');
      print('   🕐 Current TZ DateTime: $now');
      print('   ⏰ UTC Offset: ${scheduledTZ.timeZoneOffset}');
      print('   📊 Time until: ${scheduledTZ.difference(now)}');
      print('   ✅ Is in future: ${scheduledTZ.isAfter(now)}');
      print('   🆔 Notification ID: $id');
      print('   📧 Title: $title');
      print('   💬 Body: $body');
    }

    if (!scheduledTZ.isAfter(now)) {
      final error =
          'Cannot schedule notification in the past. '
          'Scheduled: $scheduledTZ, Current: $now';
      if (kDebugMode) {
        print('❌ $error');
      }
      throw PlatformException(code: 'INVALID_TIME', message: error);
    }

    // Enhanced Android notification details
    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming tasks',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      when: null, // Let system handle the time display
      autoCancel: true,
      ongoing: false,
      styleInformation: BigTextStyleInformation(''), // Enable expandable text
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: null, // Don't repeat
      );

      if (kDebugMode) {
        print('✅ Successfully scheduled notification:');
        print('   🆔 ID: $id');
        print('   🎯 Local time: $scheduledTZ');
        print('   🌍 UTC equivalent: ${scheduledTZ.toUtc()}');
        print('   ⏳ Time until notification: ${scheduledTZ.difference(now)}');

        await debugPendingNotifications();

        // Additional verification
        final pending = await _notificationsPlugin
            .pendingNotificationRequests();
        final ourNotification = pending.where((n) => n.id == id).firstOrNull;
        if (ourNotification != null) {
          print('✅ Notification verified in pending list');
          print('   📧 Verified Title: ${ourNotification.title}');
          print('   💬 Verified Body: ${ourNotification.body}');
        } else {
          print('⚠️ Notification NOT found in pending list!');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Failed to schedule notification:');
        print('   🚨 Error: $e');
        print('   📍 Type: ${e.runtimeType}');
        print('   📋 Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Cancel one notification
  Future<void> cancelNotification(int id) async {
    await onReady;
    await _notificationsPlugin.cancel(id);
    if (kDebugMode) {
      print('✅ Cancelled notification ID: $id');
      await debugPendingNotifications();
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await onReady;
    await _notificationsPlugin.cancelAll();
    if (kDebugMode) {
      print('✅ Cancelled all notifications');
      await debugPendingNotifications();
    }
  }

  /// Enhanced debug method for pending notifications
  Future<void> debugPendingNotifications() async {
    if (!_isInitialized) return;

    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      if (kDebugMode) {
        print('📋 === PENDING NOTIFICATIONS DEBUG ===');
        print('   📊 Total pending: ${pending.length}');

        if (pending.isEmpty) {
          print('   ❌ No pending notifications found!');
        } else {
          for (final n in pending) {
            print('   📌 ID: ${n.id}');
            print('      📧 Title: ${n.title}');
            print('      💬 Body: ${n.body}');
            print('      🏷️ Payload: ${n.payload}');
            print('   ---');
          }
        }
        print('📋 === END PENDING NOTIFICATIONS ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting pending notifications: $e');
      }
    }
  }

  /// Get notification permission status details
  Future<Map<String, dynamic>> getPermissionStatus() async {
    final result = <String, dynamic>{};

    result['notification'] = await Permission.notification.status;
    result['scheduleExactAlarm'] = await Permission.scheduleExactAlarm.status;

    if (Platform.isAndroid) {
      result['ignoreBatteryOptimizations'] =
          await Permission.ignoreBatteryOptimizations.status;

      // Check if the app can schedule exact alarms
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        try {
          result['canScheduleExactAlarms'] = await androidImplementation
              .canScheduleExactNotifications();
        } catch (e) {
          result['canScheduleExactAlarms'] = 'Error: $e';
        }
      }
    }

    return result;
  }
}
