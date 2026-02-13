import 'package:alarm/alarm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:football_app/providers/commentary_provider.dart';
import 'package:football_app/providers/prediction_provider.dart';
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
import 'package:football_app/providers/language_provider.dart';
import 'package:football_app/screens/home.dart';
import 'package:football_app/screens/language_screen.dart';
import 'package:football_app/services/auto_notification_service.dart';
import 'package:football_app/services/notification_service.dart';
import 'package:provider/provider.dart';

import 'package:football_app/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    // Initialize Alarm
    await Alarm.init();
    
    // Initialize notification service
    await NotificationService().init();

    // Initialize auto notification service (background sync)
    await AutoNotificationService().init();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
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
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
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
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: languageProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
            Locale('fr'),
            Locale('de'),
            Locale('it'),
            Locale('pt'),
            Locale('ar'),
            Locale('zh'),
            Locale('hi'),
            Locale('ja'),
            Locale('sw'),
            Locale('am'),
            Locale('yo'),
            Locale('qu'),
          ],
          home: languageProvider.isFirstTime 
              ? const LanguageScreen(isFirstTime: true) 
              : const Home(),
        );
      },
    );
  }
}

/// Fallback delegate for languages not natively supported by MaterialLocalizations (like yo, qu)
class FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['yo', 'qu'].contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return await GlobalMaterialLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

/// Fallback delegate for languages not natively supported by CupertinoLocalizations (like yo, qu)
class FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['yo', 'qu'].contains(locale.languageCode);

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return await GlobalCupertinoLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}
