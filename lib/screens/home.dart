 import 'dart:async';
 import 'dart:io';
 import 'package:flutter/foundation.dart';
 import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart';
 import 'package:football_app/widgets/mac_dock_nav_bar.dart';
import 'package:football_app/screens/premium_screen.dart';
import 'package:football_app/screens/settings_screen.dart';
import 'package:football_app/screens/team_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:football_app/screens/live_scores_screen.dart';
import 'package:football_app/screens/leagues_screen.dart';
import 'package:football_app/screens/shorts_screen.dart';
import 'package:football_app/screens/highlights_screen.dart';
import 'package:football_app/screens/teams_screen.dart';
import '../providers/fixture_provider.dart';
import '../providers/inplay_provider.dart';
import '../providers/league_provider.dart';
import '../providers/team_list_provider.dart';
import 'live_matches_screen.dart';
import 'search_screen.dart';

/// The Home screen acts as the main shell for the application.
/// It manages the bottom navigation bar and switches between specialized screens.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  
  // Current index of the selected tab
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    // Fetch initial data from providers once the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeagueProvider>().fetchLeagues();
      context.read<InPlayProvider>().fetchInPlayMatches();
      context.read<FixtureProvider>().fetchTodayFixtures();
      context.read<FixtureProvider>().fetchAllFixturesByDateRange();
      context.read<TeamListProvider>().fetchTeams();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // List of titles for each tab, used in the AppBar
  final List<String> _titles = [
    "Matches",
    "Leagues",
    "Live",
    "Teams",
    "Settings"
  ];

  // List of actual screen widgets ordered by the bottom navigation items
  final List<Widget> _screens = const [
    LiveScoresScreen(),
    LeaguesScreen(),
    LiveMatchesScreen(isTab: true),
    TeamsScreen(),
    SettingsScreen(isTab: true),
  ];

  @override
  Widget build(BuildContext context) {
    // Theme aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).appBarTheme.backgroundColor;
    const Color accentColor = Color(0xFFFF8700); // Lime/Neon Yellow
    final textPrimary = Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
      backgroundColor: primaryColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: _selectedIndex != 0
          ? IconButton(
               icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
              onPressed: () => setState(() => _selectedIndex = 0),
            )
          : null,
        title: _selectedIndex == 0 // Show PRO header ONLY on Matches tab
                ? Row(
                    children: [
                      Text(
                        "LiveScore",
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "PRO",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    _titles[_selectedIndex],
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                  ),
         actions: _selectedIndex == 0 // Show Search and Refresh ONLY on Matches tab
                 ? [
                     RotationTransition(
                       turns: Tween(begin: 0.0, end: 1.0).animate(_rotationController),
                       child: IconButton(
                         icon: Icon(Icons.refresh, color: textPrimary),
                         onPressed: _handleRefresh,
                       ),
                     ),
                     IconButton(
                       icon: Icon(Icons.search, color: textPrimary),
                       onPressed: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (context) => const SearchScreen()),
                         );
                       },
                     ),
                   ]
                 : [], // No tools for other screens
       ),
       // Display the screen corresponding to the current selection
       body: Stack(
         children: [
           _screens[_selectedIndex],
           if (!kIsWeb && Platform.isMacOS)
             Positioned(
               bottom: 20,
               left: 0,
               right: 0,
               child: Center(
                 child: MacDockNavBar(
                   selectedIndex: _selectedIndex,
                   onItemSelected: (index) => setState(() => _selectedIndex = index),
                   items: [
                     MacDockItem(icon: Icons.sports_soccer, label: "Matches"),
                     MacDockItem(icon: Icons.emoji_events, label: "Leagues"),
                     MacDockItem(icon: Icons.live_tv, label: "Live"),
                     MacDockItem(icon: Icons.groups_rounded, label: "Teams"),
                     MacDockItem(icon: Icons.settings, label: "Settings"),
                   ],
                 ),
               ),
             ),
         ],
       ),
       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
       bottomNavigationBar: (!kIsWeb && Platform.isMacOS) 
         ? null 
         : Container(
             decoration: BoxDecoration(
               border: Border(
                 top: BorderSide(
                   color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent,
                   width: 0.8,
                 ),
               ),
             ),
             child: BottomAppBar(
               color: isDark ? const Color(0xFF121212) : Colors.grey[200]!,
               elevation: isDark ? 0 : 10,
               padding: EdgeInsets.zero,
               child: SizedBox(
                 height: 60,
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                     _buildBottomNavItem(0, Icons.sports_soccer, "Matches", accentColor),
                     _buildBottomNavItem(1, Icons.emoji_events, "Leagues", accentColor),
                     _buildLiveNavItem(2, accentColor), // Integrated Live Button
                     _buildBottomNavItem(3, Icons.groups_rounded, "Teams", accentColor),
                     _buildBottomNavItem(4, Icons.settings, "Settings", accentColor),
                   ],
                 ),
               ),
             ),
           ),
    ),
  );
}

  Widget _buildLiveNavItem(int index, Color accentColor) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8700), Color(0xFFFF4500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8700).withOpacity(0.5 + (_pulseController.value * 0.2)),
                  blurRadius: 15 + (_pulseController.value * 5),
                  spreadRadius: 2 + (_pulseController.value * 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.live_tv, 
              color: Colors.white, 
              size: 24
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label, Color accentColor) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? accentColor : Colors.grey;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  void _handleRefresh() {
    _rotationController.forward(from: 0.0);
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
  }

  Widget _buildSearchResultsTab(Color accentColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Consumer<TeamListProvider>(
      builder: (context, provider, _) {
        final TextEditingController _searchController = TextEditingController();

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8700)));
        }

        if (provider.teams.isEmpty && _searchController.text.isNotEmpty) {
          return Center(
            child: Text("No teams found", style: TextStyle(color: subTextColor)),
          );
        }

        if (_searchController.text.isEmpty) {
          return Center(
            child: Text("Start typing to search teams", style: TextStyle(color: subTextColor)),
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
              title: Text(team['name'] ?? 'Unknown', style: TextStyle(color: textColor)),
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
