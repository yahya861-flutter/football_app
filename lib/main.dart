import 'package:football_app/providers/commentary_provider.dart';
import 'package:football_app/providers/league_provider.dart';
import 'package:football_app/providers/match_provider.dart';
import 'package:football_app/providers/fixture_provider.dart';
import 'package:football_app/providers/follow_provider.dart';
import 'package:football_app/providers/team_provider.dart';
import 'package:football_app/providers/team_list_provider.dart';
import 'package:football_app/providers/squad_provider.dart';
import 'package:football_app/providers/transfer_provider.dart';
import 'package:football_app/providers/inplay_provider.dart';
import 'package:football_app/providers/h2h_provider.dart';
import 'package:football_app/providers/stats_provider.dart';
import 'package:football_app/providers/lineup_provider.dart';
import 'package:football_app/providers/theme_provider.dart';
import 'package:football_app/providers/notification_provider.dart';
import 'package:football_app/services/notification_service.dart';
import 'package:football_app/services/auto_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:football_app/screens/home.dart';
import 'package:provider/provider.dart';
import 'package:alarm/alarm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Alarm
  await Alarm.init();
  
  // Initialize notification service
  await NotificationService().init();

  // Initialize auto notification service (background sync)
  await AutoNotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LeagueProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => FixtureProvider()),
        ChangeNotifierProvider(create: (_) => FollowProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => TeamListProvider()),
        ChangeNotifierProvider(create: (_) => SquadProvider()),
        ChangeNotifierProvider(create: (_) => TransferProvider()),
        ChangeNotifierProvider(create: (_) => InPlayProvider()),
        ChangeNotifierProvider(create: (_) => H2HProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => LineupProvider()),
        ChangeNotifierProvider(create: (_) => CommentaryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const Home(),
        );
      },
    );
  }
}
