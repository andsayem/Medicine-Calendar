import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine_model.dart';
import '../utils/constants.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(settings);
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleMedicineReminder(Medicine medicine) async {
    if (medicine.id == null || medicine.reminderTime.isEmpty) {
      return;
    }

    final nextSchedule = _nextInstanceOfTime(medicine.reminderTime);
    if (nextSchedule == null) {
      return;
    }

    await _notificationsPlugin.zonedSchedule(
      medicine.id!,
      'Medicine Reminder',
      'Time to take ${medicine.name} (${medicine.dosage}).',
      nextSchedule,
      await _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> rescheduleMedicines(List<Medicine> medicines) async {
    for (final medicine in medicines) {
      if (medicine.reminderTime.isNotEmpty && medicine.id != null) {
        await scheduleMedicineReminder(medicine);
      }
    }
  }

  tz.TZDateTime? _nextInstanceOfTime(String timeString) {
    try {
      final selectedTime = DateFormat.jm().parse(timeString);
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      return scheduledDate;
    } catch (_) {
      return null;
    }
  }

  Future<NotificationDetails> _notificationDetails() async {
    const androidDetails = AndroidNotificationDetails(
      Constants.notificationChannelId,
      Constants.notificationChannelName,
      channelDescription:
          'Daily medicine reminder notifications for My Medicine Note.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails();
    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }
}
