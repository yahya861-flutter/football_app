import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:football_app/services/database_service.dart';
import 'package:football_app/services/notification_service.dart';
import 'package:intl/intl.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final service = AutoNotificationService();
      await service.sync();
      return Future.value(true);
    } catch (e) {
      debugPrint("❌ [AUTO_NOTIF] Background Task Error: $e");
      return Future.value(false);
    }
  });
}

class AutoNotificationService {
  static final AutoNotificationService _instance = AutoNotificationService._internal();
  factory AutoNotificationService() => _instance;
  AutoNotificationService._internal();

  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';
  final String _baseUrl = 'https://api.sportmonks.com/v3/football';
  final String _taskName = 'com.football.app.notif_sync';

  Future<void> init() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    // Register periodic task (every 15 minutes - minimum allowed by Android)
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    
    debugPrint("🔔 [AUTO_NOTIF] Service Initialized & Background Task Registered.");
  }

  Future<void> syncImmediately() async {
    if (kIsWeb) return;
    await Workmanager().registerOneOffTask(
      "one_off_${DateTime.now().millisecondsSinceEpoch}",
      _taskName,
    );
  }

  Future<void> sync() async {
    if (kIsWeb) return;
    debugPrint("🔄 [AUTO_NOTIF] Starting Sync...");
    
    // 1. Load favorites from Database
    final dbService = DatabaseService();
    final favorites = await dbService.getFavorites();
    if (favorites.isEmpty) {
      debugPrint("ℹ️ [AUTO_NOTIF] No favorites to sync.");
      return;
    }

    // 2. Separate Team and League IDs
    final List<int> teamIds = [];
    final List<int> leagueIds = [];
    for (var fav in favorites) {
      if (fav['notifications_enabled'] == 1) {
        if (fav['type'] == 'team') teamIds.add(fav['id']);
        if (fav['type'] == 'league') leagueIds.add(fav['id']);
      }
    }

    if (teamIds.isEmpty && leagueIds.isEmpty) return;

    // 3. Sync Match Reminders (Upcoming matches)
    await _syncUpcomingMatches(teamIds, leagueIds);

    // 4. Sync Live Events (Goals, Cards)
    await _syncLiveEvents(teamIds, leagueIds);

    debugPrint("✅ [AUTO_NOTIF] Sync Completed.");
  }

  Future<void> _syncUpcomingMatches(List<int> teamIds, List<int> leagueIds) async {
    // Only schedule for the next 48 hours
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 2));
    final startDate = DateFormat('yyyy-MM-dd').format(now);
    final endDate = DateFormat('yyyy-MM-dd').format(tomorrow);

    try {
      // Fetch fixtures for today/tomorrow
      final url = '$_baseUrl/fixtures/between/$startDate/$endDate?api_token=$_apiKey&include=participants;league';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List? ?? [];
        final notifService = NotificationService();
        
        for (var fixture in data) {
          final int fixtureId = fixture['id'];
          final int leagueId = fixture['league_id'];
          final participants = fixture['participants'] as List? ?? [];
          final bool isFavoriteTeam = participants.any((p) => teamIds.contains(p['id']));
          final bool isFavoriteLeague = leagueIds.contains(leagueId);

          if (isFavoriteTeam || isFavoriteLeague) {
            final startTime = DateTime.fromMillisecondsSinceEpoch(fixture['starting_at_timestamp'] * 1000);
            if (startTime.isAfter(now)) {
              final homeTeam = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => null);
              final awayTeam = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => null);
              final String matchTitle = "${homeTeam?['name'] ?? 'Home'} vs ${awayTeam?['name'] ?? 'Away'}";
              
              // Schedule Notification (Match Starting Soon)
              await notifService.scheduleNotification(
                id: fixtureId,
                title: "Match Starting Soon!",
                body: "$matchTitle is starting at ${DateFormat('HH:mm').format(startTime)}",
                scheduledDate: startTime.subtract(const Duration(minutes: 5)),
              );
              debugPrint("⏰ [Upcoming] Scheduled notification for $matchTitle at $startTime");
            }
          }
        }
      }
    } catch (e) {
      debugPrint("❌ [Upcoming] Sync Error: $e");
    }
  }

  Future<void> _syncLiveEvents(List<int> teamIds, List<int> leagueIds) async {
    try {
      // Fetch currently in-play matches
      final url = '$_baseUrl/livescores/inplay?api_token=$_apiKey&include=participants;scores;events.type';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List? ?? [];
        final prefs = await SharedPreferences.getInstance();
        final notifService = NotificationService();

        for (var fixture in data) {
          final int fixtureId = fixture['id'];
          final int leagueId = fixture['league_id'];
          final participants = fixture['participants'] as List? ?? [];
          final bool isFavoriteTeam = participants.any((p) => teamIds.contains(p['id']));
          final bool isFavoriteLeague = leagueIds.contains(leagueId);

          if (isFavoriteTeam || isFavoriteLeague) {
            final String homeName = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => {'name': 'Home'})['name'];
            final String awayName = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => {'name': 'Away'})['name'];
            
            // Get Current Scores
            final scores = fixture['scores'] as List? ?? [];
            final homeScore = _getScore(scores, participants, 'home');
            final awayScore = _getScore(scores, participants, 'away');

            // Detect Score Change (Goal)
            final String lastScoreKey = "last_score_$fixtureId";
            final String currentScore = "$homeScore-$awayScore";
            final String? lastScore = prefs.getString(lastScoreKey);

            if (lastScore != null && lastScore != currentScore) {
              await notifService.showNotification(
                id: fixtureId + 1000, // Offset to avoid ID collision
                title: "GOAL!!!",
                body: "$homeName $homeScore - $awayScore $awayName",
              );
              debugPrint("⚽ [Live] Goal detected in $homeName vs $awayName ($currentScore)");
            }
            await prefs.setString(lastScoreKey, currentScore);

            // Detect Events (Cards, substitutions, etc.)
            final events = fixture['events'] as List? ?? [];
            final String lastEventKey = "last_event_count_$fixtureId";
            final int? lastEventCount = prefs.getInt(lastEventKey);
            
            // Handle Match Status Changes (Half-Time, Full-Time)
            final String status = fixture['state']?['short_name']?.toString().toUpperCase() ?? '';
            final String lastStatusKey = "last_status_$fixtureId";
            final String? lastStatus = prefs.getString(lastStatusKey);

            if (lastStatus != null && lastStatus != status) {
              if (status == 'HT') {
                await notifService.showNotification(
                  id: fixtureId + 3000,
                  title: "Half-Time",
                  body: "It's Half-Time in $homeName vs $awayName ($currentScore)",
                );
                debugPrint("⏰ [Live] Half-Time detected: $homeName vs $awayName");
              } else if (status == 'FT') {
                await notifService.showNotification(
                  id: fixtureId + 4000,
                  title: "Full-Time",
                  body: "Full-Time! Final Score: $homeName $homeScore - $awayScore $awayName",
                );
                debugPrint("🏁 [Live] Full-Time detected: $homeName vs $awayName");
              }
            }
            await prefs.setString(lastStatusKey, status);

            if (lastEventCount != null && events.length > lastEventCount) {
              // New event(s) detected. Notify for important ones (Cards, etc.)
              for (int i = lastEventCount; i < events.length; i++) {
                final event = events[i];
                final String type = event['type']?['name']?.toString().toUpperCase() ?? '';
                final int minute = event['minute'] ?? 0;
                
                if (type.contains('CARD') || type.contains('PENALTY') || type.contains('SUBSTITUTION') || type.contains('VAR') || type.contains('GOAL')) {
                  String title = "$type!";
                  if (type.contains('SUBSTITUTION')) title = "Substitution";
                  if (type.contains('VAR')) title = "VAR Decision";
                  
                  await notifService.showNotification(
                    id: fixtureId + 2000 + i,
                    title: title,
                    body: "$type at $minute' in $homeName vs $awayName",
                  );
                  debugPrint("🚩 [Live] Event detected: $type at $minute'");
                }
              }
            }
            await prefs.setInt(lastEventKey, events.length);
          }
        }
      }
    } catch (e) {
      debugPrint("❌ [Live] Sync Error: $e");
    }
  }

  int _getScore(List scores, List participants, String location) {
    try {
      final team = participants.firstWhere((p) => p['meta']?['location'] == location, orElse: () => null);
      if (team == null) return 0;
      final scoreObj = scores.firstWhere((s) => s['participant_id'] == team['id'] && (s['description'] == 'CURRENT' || s['description'] == 'FT'), orElse: () => null);
      return scoreObj?['score']?['goals'] ?? scoreObj?['goals'] ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
