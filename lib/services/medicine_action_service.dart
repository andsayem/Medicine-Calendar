import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class MedicineActionService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Snooze 10 minutes
  static Future<void> snooze(int id) async {
    await _plugin.cancel(id);

    await _plugin.zonedSchedule(
      id,
      '⏰ Snoozed Medicine',
      'Reminder after snooze',
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_channel',
          'Medicine Reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
    );
  }

  // Mark as taken
  static Future<void> markAsTaken(int id) async {
    await _plugin.cancel(id);
  }
}
