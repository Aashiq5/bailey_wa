import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification service for showing local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bailey_wa_channel',
      'Bailey WA Notifications',
      channelDescription: 'Notifications for Bailey WhatsApp Automation',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> showNewMessageNotification({
    required String senderName,
    required String message,
    String? chatId,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'New message from $senderName',
      body: message,
      payload: chatId,
    );
  }

  static Future<void> showMessageCheckNotification({
    required int newMessagesCount,
  }) async {
    if (newMessagesCount > 0) {
      await showNotification(
        id: 0,
        title: 'Bailey WA',
        body: 'You have $newMessagesCount new message(s)',
      );
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
