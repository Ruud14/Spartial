import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for showing local notifications.
class LocalNotification {
  static final _notifications = FlutterLocalNotificationsPlugin();

  /// Creates the notification details.
  static Future _notificationDetails() async {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'channel id',
        'Info Notification',
      ),
      iOS: IOSNotificationDetails(),
    );
  }

  /// Initializes onSelectNotification.
  static Future init({bool initScheduled = false}) async {
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iOS = IOSInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: iOS);
    await _notifications.initialize(settings,
        onSelectNotification: (payload) async {});
  }

  /// Shows the notification with title and body.
  static void show({required String title, required String body}) async {
    _notifications.show(0, title, body, await _notificationDetails());
  }

  /// Hides the notification.
  static void hide() async {
    await _notifications.cancel(0);
  }
}
