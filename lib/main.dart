import 'package:football_app/providers/live_score_provider.dart';
import 'package:football_app/providers/league_provider.dart';
import 'package:flutter/material.dart';
import 'package:football_app/screens/home.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LiveScoreProvider()),
        ChangeNotifierProvider(create: (_) => LeagueProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

