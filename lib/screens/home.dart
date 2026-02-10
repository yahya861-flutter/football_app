import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:football_app/screens/live_scores_screen.dart';
import 'package:football_app/screens/leagues_screen.dart';
import 'package:football_app/screens/shorts_screen.dart';
import 'package:football_app/screens/highlights_screen.dart';
import 'package:football_app/screens/news_screen.dart';
import '../providers/fixture_provider.dart';
import '../providers/inplay_provider.dart';
import '../providers/league_provider.dart';

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
      context.read<LeagueProvider>().fetchLeagues();
      context.read<InPlayProvider>().fetchInPlayMatches();
      context.read<FixtureProvider>().fetchTodayFixtures();
      context.read<FixtureProvider>().fetchAllFixturesByDateRange();
    });
  }

  // List of titles for each tab, used in the AppBar
  final List<String> _titles = [
    "Matches",
    "Leagues",
    "Shorts",
    "Highlights",
    "News"
  ];

  // List of actual screen widgets ordered by the bottom navigation items
  final List<Widget> _screens = const [
    LiveScoresScreen(),
    LeaguesScreen(),
    ShortsScreen(),
    HighlightsScreen(),
    NewsScreen(),
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
        title: _selectedIndex == 0
            ? Row(
                children: [
                  const Text(
                    "LiveScore",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "PRO",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              )
            : Text(
                _titles[_selectedIndex],
                style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
              ),
        actions: _selectedIndex == 0
            ? [
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () {}),
                IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
                IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
              ]
            : null,
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
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: "Matches"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Leagues"),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Shorts"),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: "Highlights"),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: "News"),
        ],
      ),
    );
  }
}
