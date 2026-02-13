import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:football_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MatchNotificationSettings {
  final int matchId;
  final bool notifyBeforeMatch;
  final int beforeMatchMinutes;
  final bool notifyAtStart;
  final bool notifyAtFullTime;

  MatchNotificationSettings({
    required this.matchId,
    this.notifyBeforeMatch = false,
    this.beforeMatchMinutes = 0,
    this.notifyAtStart = false,
    this.notifyAtFullTime = false,
  });

  Map<String, dynamic> toJson() => {
    'matchId': matchId,
    'notifyBeforeMatch': notifyBeforeMatch,
    'beforeMatchMinutes': beforeMatchMinutes,
    'notifyAtStart': notifyAtStart,
    'notifyAtFullTime': notifyAtFullTime,
  };

  factory MatchNotificationSettings.fromJson(Map<String, dynamic> json) => MatchNotificationSettings(
    matchId: json['matchId'],
    notifyBeforeMatch: json['notifyBeforeMatch'] ?? false,
    beforeMatchMinutes: json['beforeMatchMinutes'] ?? 0,
    notifyAtStart: json['notifyAtStart'] ?? false,
    notifyAtFullTime: json['notifyAtFullTime'] ?? false,
  );

  bool get isActive => notifyBeforeMatch || notifyAtStart || notifyAtFullTime;
}

class NotificationProvider with ChangeNotifier {
  Map<int, MatchNotificationSettings> _settingsMap = {};
  static const String _storageKey = 'match_notification_settings';
  final NotificationService _notificationService = NotificationService();

  NotificationProvider() {
    _loadSettings();
  }

  Map<int, MatchNotificationSettings> get settingsMap => _settingsMap;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        _settingsMap = decoded.map((key, value) => MapEntry(
          int.parse(key),
          MatchNotificationSettings.fromJson(value),
        ));
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading notification settings: $e");
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> encoded = _settingsMap.map((key, value) => MapEntry(
      key.toString(),
      value.toJson(),
    ));
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  MatchNotificationSettings getSettings(int matchId) {
    return _settingsMap[matchId] ?? MatchNotificationSettings(matchId: matchId);
  }

  Future<void> updateSettings(int matchId, MatchNotificationSettings settings, DateTime startTime, String matchTitle) async {
    print("🔔 Updating settings for Match: $matchTitle (ID: $matchId) | StartTime: $startTime");
    // 1. Cancel existing notifications/alarms for this match
    await _cancelMatchNotifications(matchId);

    if (!settings.isActive) {
      _settingsMap.remove(matchId);
    } else {
      _settingsMap[matchId] = settings;
      
      // 2. Schedule new notifications/alarms
      if (settings.notifyBeforeMatch && settings.beforeMatchMinutes > 0) {
        final scheduledDate = startTime.subtract(Duration(minutes: settings.beforeMatchMinutes));
        await _notificationService.scheduleNotification(
          id: matchId * 10 + 1,
          title: "Match Reminder",
          body: "$matchTitle starts in ${settings.beforeMatchMinutes} minutes!",
          scheduledDate: scheduledDate,
        );
      } else if (settings.notifyBeforeMatch && settings.beforeMatchMinutes == 0) {
        await _notificationService.scheduleNotification(
          id: matchId * 10 + 1,
          title: "Match Reminder",
          body: "$matchTitle is starting now!",
          scheduledDate: startTime,
        );
      }

      if (settings.notifyAtStart) {
        await _notificationService.scheduleNotification(
          id: matchId * 10 + 2,
          title: "Match Starting",
          body: "$matchTitle has started!",
          scheduledDate: startTime,
        );
      }

      if (settings.notifyAtFullTime) {
        // Use regular LOCAL NOTIFICATION for full time
        final fullTimeEstimate = startTime.add(const Duration(minutes: 110));
        await _notificationService.scheduleNotification(
          id: matchId * 10 + 3,
          title: "Full Time Check",
          body: "$matchTitle should be over. Check the final score!",
          scheduledDate: fullTimeEstimate,
        );
      }
    }
    
    notifyListeners();
    await _saveSettings();
  }

  Future<void> showTestNotification() async {
    await _notificationService.showNotification(
      id: 999,
      title: "Test Notification",
      body: "This is a test notification triggered immediately!",
    );
  }

  Future<void> scheduleTestAlarm() async {
    final scheduledDate = DateTime.now().add(const Duration(seconds: 10));
    // Test using ALARM package
    await _notificationService.scheduleAlarm(
      id: 888,
      title: "Scheduled Test Alarm",
      body: "This alarm (Loud) was scheduled 10 seconds ago!",
      scheduledTime: scheduledDate,
    );
  }

  Future<void> scheduleTestNotification() async {
    final scheduledDate = DateTime.now().add(const Duration(seconds: 10));
    // Test using flutter_local_notifications (Standard)
    await _notificationService.scheduleNotification(
      id: 777,
      title: "Scheduled Test Notification",
      body: "This notification (Standard) was scheduled 10 seconds ago!",
      scheduledDate: scheduledDate,
    );
  }

  Future<void> toggleAllOff(int matchId) async {
    await _cancelMatchNotifications(matchId);
    _settingsMap.remove(matchId);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> _cancelMatchNotifications(int matchId) async {
    // Ensure both Alarms and Local Notifications are cleared for these IDs
    await _notificationService.stopAlarm(matchId * 10 + 1);
    await _notificationService.stopAlarm(matchId * 10 + 2);
    
    await _notificationService.cancelNotification(matchId * 10 + 1);
    await _notificationService.cancelNotification(matchId * 10 + 2);
    await _notificationService.cancelNotification(matchId * 10 + 3);
  }

  bool isNotificationSet(int matchId) {
    return _settingsMap.containsKey(matchId) && _settingsMap[matchId]!.isActive;
  }
}
