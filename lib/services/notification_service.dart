import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine_model.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// ===============================
  /// DEFAULT REMINDER TIMES
  /// ===============================

  static const List<Map<String, dynamic>> defaultSchedule = [
    {'label': 'Morning', 'hour': 8, 'minute': 0, 'index': 0},
    {'label': 'Afternoon', 'hour': 14, 'minute': 0, 'index': 1},
    {'label': 'Evening', 'hour': 20, 'minute': 0, 'index': 2},
  ];

  /// ===============================
  /// INITIALIZE
  /// ===============================

  Future<void> initialize() async {
    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(android: android, iOS: ios);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTapNotification,
    );

    await _requestPermissions();
  }

  void _onTapNotification(NotificationResponse response) {
    // open medicine page
  }

  /// ===============================
  /// PERMISSION
  /// ===============================

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final ios = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }

    if (Platform.isAndroid) {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await android?.requestNotificationsPermission();

      await android?.requestExactAlarmsPermission();
    }
  }

  /// ===============================
  /// SAVE CUSTOM TIME
  /// ===============================

  Future<void> saveReminderTime({
    required int index,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'reminder_time_$index',
      jsonEncode({'hour': hour, 'minute': minute}),
    );
  }

  /// ===============================
  /// GET REMINDER SCHEDULE
  /// ===============================

  Future<List<Map<String, dynamic>>> getReminderSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> updated = [];

    for (final item in defaultSchedule) {
      final index = item['index'];

      final saved = prefs.getString('reminder_time_$index');

      if (saved != null) {
        final decoded = jsonDecode(saved);

        updated.add({
          ...item,
          'hour': decoded['hour'],
          'minute': decoded['minute'],
        });
      } else {
        updated.add(item);
      }
    }

    return updated;
  }

  /// ===============================
  /// SCHEDULE MEDICINE
  /// ===============================

  Future<void> scheduleMedicineReminder(Medicine medicine) async {
    if (medicine.id == null || medicine.dosage.isEmpty) {
      return;
    }

    final parts = medicine.dosage.split('+');

    final scheduleMap = await getReminderSchedule();

    for (final item in scheduleMap) {
      final index = item['index'] as int;

      if (index >= parts.length) continue;

      final doseCount = int.tryParse(parts[index].trim()) ?? 0;

      if (doseCount > 0) {
        await _scheduleSingleNotification(
          id: _notificationId(medicine.id!, index),

          title: 'Medicine Reminder',

          body:
              'Take ${medicine.name} '
              '(${medicine.dosage}) '
              '- ${item['label']}',

          hour: item['hour'] as int,

          minute: item['minute'] as int,
        );
      }
    }
  }

  /// ===============================
  /// SINGLE NOTIFICATION
  /// ===============================

  Future<void> _scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _notificationDetails(),

      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,

      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// ===============================
  /// NOTIFICATION STYLE
  /// ===============================

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'medicine_channel',
      'Medicine Reminder',

      channelDescription: 'Medicine reminder notifications',

      importance: Importance.max,
      priority: Priority.high,

      playSound: true,
      enableVibration: true,

      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails();

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// ===============================
  /// TEST NOTIFICATION
  /// ===============================

  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notification',

      channelDescription: 'Test notification channel',

      importance: Importance.max,
      priority: Priority.high,

      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Test Medicine Reminder',
      'This is a test notification '
          'working perfectly!',
      notificationDetails,
    );
  }

  /// ===============================
  /// CANCEL SINGLE
  /// ===============================

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);

    for (var index = 0; index < 3; index++) {
      await _notificationsPlugin.cancel(_notificationId(id, index));
    }
  }

  /// ===============================
  /// CANCEL ALL
  /// ===============================

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// ===============================
  /// RESCHEDULE ALL MEDICINES
  /// ===============================

  Future<void> rescheduleMedicines(List<Medicine> medicines) async {
    for (final medicine in medicines) {
      await scheduleMedicineReminder(medicine);
    }
  }

  /// ===============================
  /// UNIQUE ID
  /// ===============================

  int _notificationId(int medicineId, int doseIndex) {
    return (medicineId * 10) + doseIndex;
  }

  /// ===============================
  /// TEST BACKGROUND
  /// ===============================

  Future<void> testBackgroundNotification() async {
    await _notificationsPlugin.zonedSchedule(
      1,
      "TEST",
      "App closed test notification",

      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)),

      _notificationDetails(),

      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
    );
  }
}
