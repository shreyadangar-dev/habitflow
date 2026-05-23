import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId   = 'hf_reminders';
  static const _channelName = 'Habit Reminders';

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  static Future<void> scheduleDaily(int habitId, String habitName, int hour, int minute) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(_channelId, _channelName,
          channelDescription: 'Daily habit reminders',
          importance: Importance.high, priority: Priority.high),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );
    await _plugin.periodicallyShow(
      habitId, '🔥 HabitFlow', 'Time for your habit: $habitName',
      RepeatInterval.daily, details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancel(int habitId) => _plugin.cancel(habitId);
  static Future<void> cancelAll() => _plugin.cancelAll();
}
