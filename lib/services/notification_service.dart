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
    if (kIsWeb) return;
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    
    String timeZoneName = "UTC";
    try {
      timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint("🔔 [INIT] Notification Service Local Timezone: $timeZoneName");
    } catch (e) {
      debugPrint("⚠️ [INIT] Failed to set local timezone ($timeZoneName): $e. Falling back to UTC.");
      tz.setLocalLocation(tz.getLocation("UTC"));
    }

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
      macOS: iosSettings,
    );

    // 5. Initialize Plugin
    await _notificationsPlugin.initialize(
      settings: settings,
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
        icon: 'ic_launcher', // Use app icon for notification
      ),
      warningNotificationOnKill: true, // Survive app kill/swipe on Android
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
    
    // 1. Convert to TZDateTime safely
    // If the date passed is a relative future date, it's safer to calculate it from TZDateTime.now
    final nowTZ = tz.TZDateTime.now(tz.local);
    final nowSystem = DateTime.now();
    
    // Calculate the difference between now and the target date
    final duration = scheduledDate.difference(nowSystem);
    
    // Create the target TZDateTime relative to the current location's time
    var tzDateTime = nowTZ.add(duration);

    debugPrint("🔔 [NOTIFICATION] TZ Local: ${tz.local.name}");
    debugPrint("🔔 [NOTIFICATION] System Time: $nowSystem");
    debugPrint("🔔 [NOTIFICATION] TZ Local Time: $nowTZ");
    debugPrint("🔔 [NOTIFICATION] Target Time: $tzDateTime (ID: $id)");
    debugPrint("🔔 [NOTIFICATION] Can schedule exact: $canScheduleExact");

    // 2. Ensure it's in the future (minimum 2 seconds)
    if (tzDateTime.isBefore(nowTZ.add(const Duration(seconds: 2)))) {
      debugPrint("⚠️ [WARNING] Time is past or too close! Adjusting to 10s from now.");
      tzDateTime = nowTZ.add(const Duration(seconds: 10));
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: NotificationDetails(
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
      );
      debugPrint("✅ [SUCCESS] Notification $id scheduled successfully for $tzDateTime.");
    } catch (e) {
      debugPrint("❌ [ERROR] Failed to schedule notification: $e");
      
      // Fallback: If exact fails, try inexact
      if (e.toString().contains("exact_alarm")) {
         debugPrint("🔄 [FALLBACK] Attempting inexact scheduling...");
         await _notificationsPlugin.zonedSchedule(
           id: id,
           title: title,
           body: body,
           scheduledDate: tzDateTime,
           notificationDetails: const NotificationDetails(
             android: AndroidNotificationDetails('match_reminders', 'Match Reminders')
           ),
           androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
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
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
