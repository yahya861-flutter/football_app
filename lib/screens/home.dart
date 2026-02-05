import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:football_app/screens/live_scores_screen.dart';
import 'package:football_app/screens/leagues_screen.dart';
import 'package:football_app/screens/competitions_screen.dart';
import 'package:football_app/screens/teams_screen.dart';
import 'package:football_app/screens/settings_screen.dart';
import '../providers/league_provider.dart';
import '../providers/live_score_provider.dart';

/// The Home screen acts as the main shell for the application.
/// It manages the bottom navigation bar and switches between specialized screens.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Current index of the selected tab
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch initial data from providers once the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveScoreProvider>().fetchLiveScores();
      context.read<LeagueProvider>().fetchLeagues();
    });
  }

  // List of titles for each tab, used in the AppBar
  final List<String> _titles = [
    "Live Scores",
    "Leagues",
    "Competitions",
    "Teams",
    "Settings"
  ];

  // List of actual screen widgets ordered by the bottom navigation items
  final List<Widget> _screens = const [
    LiveScoresScreen(),
    LeaguesScreen(),
    CompetitionsScreen(),
    TeamsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Custom color palette for the Sports App theme
    const Color primaryColor = Color(0xFF1E1E2C);
    const Color accentColor = Color(0xFFD4FF00); // Lime/Neon Yellow
    const Color secondaryColor = Color(0xFF2D2D44);
    const Color textPrimary = Colors.white;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      // Display the screen corresponding to the current selection
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: secondaryColor,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white38,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // Shows all labels even with 5 items
        onTap: (index) {
          // Update selected index to switch screens
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: "Live"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Leagues"),
          BottomNavigationBarItem(icon: Icon(Icons.reorder), label: "Comp."),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Teams"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
