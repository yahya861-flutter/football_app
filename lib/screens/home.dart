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
import 'team_details_screen.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
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
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Search teams...",
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.white38, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      context.read<TeamListProvider>().searchTeams(value);
                    }
                  },
                ),
              )
            : _selectedIndex == 0
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
        actions: _isSearching
            ? [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _handleRefresh,
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
                IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
              ],
      ),
      // Display the screen corresponding to the current selection
      body: _isSearching ? _buildSearchResultsTab(accentColor) : _screens[_selectedIndex],
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
