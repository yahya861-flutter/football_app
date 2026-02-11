import 'dart:async';
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
import '../providers/team_list_provider.dart';
import 'live_matches_screen.dart';
import 'team_details_screen.dart';
import 'settings_screen.dart';

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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Fetch initial data from providers once the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeagueProvider>().fetchLeagues();
      context.read<InPlayProvider>().fetchInPlayMatches();
      context.read<FixtureProvider>().fetchTodayFixtures();
      context.read<FixtureProvider>().fetchAllFixturesByDateRange();
      context.read<TeamListProvider>().fetchTeams();
    });
  }

  // List of titles for each tab, used in the AppBar
  final List<String> _titles = [
    "Matches",
    "Leagues",
    "Live",
    "News",
    "Settings"
  ];

  // List of actual screen widgets ordered by the bottom navigation items
  final List<Widget> _screens = const [
    LiveScoresScreen(),
    LeaguesScreen(),
    LiveMatchesScreen(isTab: true),
    NewsScreen(),
    SettingsScreen(isTab: true),
  ];

  @override
  Widget build(BuildContext context) {
    // Theme aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).appBarTheme.backgroundColor;
    const Color accentColor = Color(0xFFFF8700); // Lime/Neon Yellow
    final secondaryColor = isDark ? const Color(0xFF2D2D44) : Colors.grey[200]!;
    final textPrimary = Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white;

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
          });
        }
      },
      child: Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search teams...",
                    hintStyle: TextStyle(color: textPrimary.withOpacity(0.4), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: textPrimary.withOpacity(0.4), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      if (value.isNotEmpty) {
                        context.read<TeamListProvider>().searchTeams(value);
                      }
                    });
                  },
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      context.read<TeamListProvider>().searchTeams(value);
                    }
                  },
                ),
              )
            : _selectedIndex == 0 // Show PRO header ONLY on Matches tab
                ? Row(
                    children: [
                      Text(
                        "LiveScore",
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
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
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                  ),
        actions: _isSearching
            ? [
                IconButton(
                  icon: Icon(Icons.close, color: textPrimary),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                  },
                ),
              ]
            : _selectedIndex == 0 // Show Search and Refresh ONLY on Matches tab
                ? [
                    IconButton(
                      icon: Icon(Icons.refresh, color: textPrimary),
                      onPressed: _handleRefresh,
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: textPrimary),
                      onPressed: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                    ),
                  ]
                : [], // No tools for other screens
      ),
      // Display the screen corresponding to the current selection
      body: _isSearching ? _buildSearchResultsTab(accentColor) : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: secondaryColor,
        selectedItemColor: accentColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
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
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: "Live"),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: "News"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    ),
  );
}

  void _handleRefresh() {
    switch (_selectedIndex) {
      case 0: // Matches
        context.read<InPlayProvider>().fetchInPlayMatches();
        context.read<FixtureProvider>().fetchTodayFixtures();
        break;
      case 1: // Leagues
        context.read<LeagueProvider>().fetchLeagues();
        context.read<TeamListProvider>().fetchTeams(forceRefresh: true);
        break;
      case 2: // Live
        context.read<InPlayProvider>().fetchInPlayMatches();
        break;
      default:
        // Other tabs refresh if needed
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Refreshing data..."), duration: Duration(seconds: 1)),
    );
  }

  Widget _buildSearchResultsTab(Color accentColor) {
    return Consumer<TeamListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
        }

        if (provider.teams.isEmpty && _searchController.text.isNotEmpty) {
          return const Center(
            child: Text("No teams found", style: TextStyle(color: Colors.white38)),
          );
        }

        if (_searchController.text.isEmpty) {
          return const Center(
            child: Text("Start typing to search teams", style: TextStyle(color: Colors.white38)),
          );
        }

        return ListView.builder(
          itemCount: provider.teams.length,
          itemBuilder: (context, index) {
            final team = provider.teams[index];
            return ListTile(
              leading: team['image_path'] != null
                  ? Image.network(team['image_path'], width: 30, height: 30)
                  : Icon(Icons.shield, color: accentColor, size: 30),
              title: Text(team['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamDetailsScreen(
                      teamId: team['id'],
                      teamName: team['name'],
                      teamLogo: team['image_path'] ?? '',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
