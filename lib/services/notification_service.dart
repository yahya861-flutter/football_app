import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    debugPrint("🔔 Notification Service Initialized. Local Timezone: $timeZoneName");

    // 2. Setup Android Settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. Setup iOS Settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4. Combined Settings
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 5. Initialize Plugin
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );

    // 6. Request permissions
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      // Request notification permission (Android 13+)
      await androidImplementation?.requestNotificationsPermission();
      
      // Request exact alarm permission (Android 12+)
      await androidImplementation?.requestExactAlarmsPermission();
      
      debugPrint("🔔 Permissions requested for Android.");
    }
  }

  // --- ALARM SECTION (using alarm package) ---

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String assetAudioPath = 'assets/marimba.mp3', // Default or user-provided
  }) async {
    debugPrint("⏰ [ALARM] Scheduling Alarm $id for $scheduledTime");

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: scheduledTime,
      assetAudioPath: assetAudioPath,
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: const Duration(seconds: 3),
      ),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: "Stop",
      ),
    );

    try {
      await Alarm.set(alarmSettings: alarmSettings);
      debugPrint("✅ [ALARM] Success: Alarm $id set.");
    } catch (e) {
      debugPrint("❌ [ALARM] Error: $e");
    }
  }

  Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
  }

  // --- NOTIFICATION SECTION (using flutter_local_notifications) ---

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // 1. Convert to TZDateTime
    var tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    debugPrint("🔔 [DEBUG] System Time: ${DateTime.now()}");
    debugPrint("🔔 [DEBUG] TZ Local Time: $now");
    debugPrint("🔔 [DEBUG] Target Time: $tzDateTime");

    // 2. Ensure it's in the future
    if (tzDateTime.isBefore(now)) {
      debugPrint("⚠️ [WARNING] Scheduled time is in the past! Adding 5 seconds offset.");
      tzDateTime = now.add(const Duration(seconds: 5));
    }

    debugPrint("🔔 [DEBUG] Final Schedule Time: $tzDateTime (ID: $id)");

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'match_reminders',
            'Match Reminders',
            channelDescription: 'Notifications for football match reminders',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("✅ [SUCCESS] Notification $id scheduled for $tzDateTime.");
    } catch (e) {
      debugPrint("❌ [ERROR] Failed to schedule: $e");
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    debugPrint("🔔 [DEBUG] Showing Immediate Notification (ID: $id)");

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'match_reminders',
            'Match Reminders',
            channelDescription: 'Notifications for football match reminders',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint("✅ [SUCCESS] Notification $id shown.");
    } catch (e) {
      debugPrint("❌ [ERROR] Failed to show: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
