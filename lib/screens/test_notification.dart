import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TestNotificationPage extends StatelessWidget {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  TestNotificationPage({super.key});

  Future<void> _showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel_id',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(
      9999, // Unique ID for test notification
      'Test Notification',
      'This is a test notification from Focus!',
      platformDetails,
      payload: 'test_payload',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _showTestNotification,
              child: const Text('Send Test Notification'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await notificationsPlugin.cancel(9999);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification cancelled')),
                );
              },
              child: const Text('Cancel Test Notification'),
            ),
          ],
        ),
      ),
    );

  }
}