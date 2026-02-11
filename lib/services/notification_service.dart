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
    DateTime finalTime = scheduledTime;
    final now = DateTime.now();

    debugPrint("⏰ [ALARM] System Time: $now");
    debugPrint("⏰ [ALARM] Request Time: $scheduledTime (ID: $id)");

    // Ensure it's in the future (at least 5 seconds from now)
    if (finalTime.isBefore(now.add(const Duration(seconds: 5)))) {
      debugPrint("⚠️ [ALARM] Requested time is in the past or too soon! Adjusting to 10s from now.");
      finalTime = now.add(const Duration(seconds: 10));
    }

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: finalTime,
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
      debugPrint("✅ [ALARM] Success: Alarm $id set for $finalTime.");
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
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    // Check if exact alarms are allowed (Android 12+)
    bool? canScheduleExact = await androidImplementation?.canScheduleExactNotifications();
    debugPrint("🔔 [NOTIFICATION] Can schedule exact alarms: $canScheduleExact");

    // 1. Convert to TZDateTime safely
    var tzDateTime = tz.TZDateTime.from(scheduledDate.toUtc(), tz.local);
    final now = tz.TZDateTime.now(tz.local);

    debugPrint("🔔 [NOTIFICATION] System Time: ${DateTime.now()}");
    debugPrint("🔔 [NOTIFICATION] TZ Local Time: $now");
    debugPrint("🔔 [NOTIFICATION] Target Time: $tzDateTime (ID: $id)");

    // 2. Ensure it's in the future (minimum 5 seconds)
    if (tzDateTime.isBefore(now.add(const Duration(seconds: 2)))) {
      debugPrint("⚠️ [WARNING] Time is past or too close! Adjusting to 10s from now.");
      tzDateTime = now.add(const Duration(seconds: 10));
    }

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
            showWhen: true,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
            // Try with exact permission
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
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
      debugPrint("✅ [SUCCESS] Notification $id scheduled successfully for $tzDateTime.");
    } catch (e) {
      debugPrint("❌ [ERROR] Failed to schedule notification: $e");
      
      // Fallback: If exact fails, try inexact
      if (e.toString().contains("exact_alms")) {
         debugPrint("🔄 [FALLBACK] Attempting inexact scheduling...");
         await _notificationsPlugin.zonedSchedule(
           id,
           title,
           body,
           tzDateTime,
           const NotificationDetails(android: AndroidNotificationDetails('match_reminders', 'Match Reminders')),
           androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
           uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
         );
      }
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
