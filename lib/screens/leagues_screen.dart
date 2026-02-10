import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:football_app/providers/league_provider.dart';
import 'package:football_app/providers/team_list_provider.dart';
import 'package:football_app/providers/follow_provider.dart';
import 'package:football_app/screens/league_details_screen.dart';
import 'package:football_app/screens/team_details_screen.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _teamSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _teamScrollController = ScrollController();
  String _searchQuery = "";
  String _teamSearchQuery = "";
  Timer? _teamDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeagueProvider>().fetchLeagues();
      context.read<TeamListProvider>().fetchTeams();
    });
    
    _teamScrollController.addListener(() {
      if (_teamScrollController.position.pixels >= _teamScrollController.position.maxScrollExtent - 200) {
        context.read<TeamListProvider>().loadMoreTeams();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<LeagueProvider>().loadMoreLeagues();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _teamScrollController.dispose();
    _searchController.dispose();
    _teamSearchController.dispose();
    _teamDebounce?.cancel();
    super.dispose();
  }

  bool _isLeaguesFollowingExpanded = true;
  bool _isLeaguesTopExpanded = true;
  bool _isLeaguesSuggestionsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).scaffoldBackgroundColor;
    const Color accentColor = Color(0xFFFF8700);
    final Color cardColor = isDark ? const Color(0xFF2D2D44) : Colors.grey[200]!;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Scaffold(
      backgroundColor: primaryColor,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Sub Tabs: Leagues | Teams
            TabBar(
              indicatorColor: accentColor,
              labelColor: isDark ? accentColor : Colors.black,
              unselectedLabelColor: subTextColor,
              tabs: const [
                Tab(text: "Leagues"),
                Tab(text: "Teams"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildLeaguesTab(accentColor, cardColor),
                  _buildTeamsTab(accentColor, cardColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguesTab(Color accentColor, Color cardColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Consumer2<LeagueProvider, FollowProvider>(
      builder: (context, leagueProvider, followProvider, child) {
        if (leagueProvider.isLoading && leagueProvider.leagues.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueGrey));
        }

        // 1. Filtering
        final filteredLeagues = leagueProvider.leagues.where((l) {
          final name = l['name']?.toLowerCase() ?? "";
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        final topLeagues = filteredLeagues.where((l) => l['category'] == 1).toList();
        final followedLeagues = filteredLeagues.where((l) => followProvider.isLeagueFollowed(l['id'])).toList();

        // 2. Grouping
        Map<String, List<dynamic>> leaguesByCountryMap = {};
        for (var league in filteredLeagues) {
          final countryName = league['country']?['name'] ?? 'International';
          if (!leaguesByCountryMap.containsKey(countryName)) {
            leaguesByCountryMap[countryName] = [];
          }
          leaguesByCountryMap[countryName]!.add(league);
        }
        final countryEntries = leaguesByCountryMap.entries.toList();

        // 3. Build flattened list
        final List<Widget> items = [];
        
        // Search
        items.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          child: _buildSearchBar(cardColor),
        ));

        // Following
        items.add(_buildSectionHeader(
          icon: Icons.star, iconColor: isDark ? Colors.tealAccent : Colors.teal, title: "Following", count: followedLeagues.length,
          isExpanded: _isLeaguesFollowingExpanded,
          onToggle: () => setState(() => _isLeaguesFollowingExpanded = !_isLeaguesFollowingExpanded),
        ));
        if (_isLeaguesFollowingExpanded) {
          if (followedLeagues.isEmpty) {
            items.add(Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("You are not following any leagues", style: TextStyle(color: subTextColor)),
            ));
          } else {
            items.addAll(followedLeagues.map((l) => _buildLeagueItem(l, accentColor)));
          }
        }

        // Top Leagues
        items.add(Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildSectionHeader(
            icon: Icons.thumb_up, iconColor: isDark ? Colors.tealAccent : Colors.teal, title: "Top Leagues", count: topLeagues.length,
            isExpanded: _isLeaguesTopExpanded,
            onToggle: () => setState(() => _isLeaguesTopExpanded = !_isLeaguesTopExpanded),
          ),
        ));
        if (_isLeaguesTopExpanded) {
          items.addAll(topLeagues.map((l) => _buildLeagueItem(l, accentColor)));
        }

        // Suggestions
        items.add(Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildSectionHeader(
            icon: Icons.lightbulb_outline, iconColor: isDark ? Colors.tealAccent : Colors.teal, title: "Suggestions", count: 3,
            isExpanded: _isLeaguesSuggestionsExpanded,
            onToggle: () => setState(() => _isLeaguesSuggestionsExpanded = !_isLeaguesSuggestionsExpanded),
          ),
        ));
        if (_isLeaguesSuggestionsExpanded) {
          items.add(_buildSuggestionsRow(accentColor, cardColor, leagueProvider.leagues, textColor));
        }

        items.add(Padding(
          padding: const EdgeInsets.only(top: 32, bottom: 16),
          child: Text("All Leagues", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ));

        // Country Groups
        items.addAll(countryEntries.map((entry) => _buildCountryExpandable(entry.key, entry.value, accentColor, textColor, subTextColor, isDark)));

        // Loading Indicator
        if (leagueProvider.hasMore) {
          items.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: accentColor, strokeWidth: 2),
                  const SizedBox(height: 8),
                  Text("Loading more leagues (${leagueProvider.leagues.length} loaded)...", style: TextStyle(color: subTextColor, fontSize: 12)),
                ],
              ),
            ),
          ));
        }

        items.add(const SizedBox(height: 40));

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }

  Widget _buildLeagueItem(dynamic league, Color accentColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    final String name = league['name'] ?? 'League';
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeagueDetailsScreen(leagueId: league['id']),
          ),
        );
      },
      leading: league['image_path'] != null 
        ? Image.network(league['image_path'], width: 30, height: 30)
        : Icon(Icons.emoji_events, color: accentColor, size: 30),
      title: Text(name, style: TextStyle(color: textColor, fontSize: 14)),
      trailing: Consumer<FollowProvider>(
        builder: (context, follow, child) {
          final isFollowed = follow.isLeagueFollowed(league['id']);
          return IconButton(
            icon: Icon(isFollowed ? Icons.star : Icons.star_border, 
                 color: isFollowed ? accentColor : subTextColor),
            onPressed: () => follow.toggleFollowLeague(league['id']),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(Color cardColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: textColor),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: "Type to search leagues",
          hintStyle: TextStyle(color: subTextColor),
          prefixIcon: Icon(Icons.search, color: subTextColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
// Expandable content
// Expandable content is now handled by _buildSectionHeader and manual list management for better performance.
// suggestion area
  Widget _buildSuggestionsRow(Color accentColor, Color cardColor, List<dynamic> leagues, Color textColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;
    // Pick a few leagues for suggestions
    final suggestions = leagues.take(3).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: suggestions.map((l) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF26BC94).withOpacity(0.2) : Colors.teal[50], // Premium teal style
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Row(
              children: [
                if (l['image_path'] != null)
                  Image.network(l['image_path'], width: 24, height: 24)
                else
                  Icon(Icons.emoji_events, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(l['name'] ?? 'League', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(Icons.star_border, color: subTextColor, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountryExpandable(String countryName, List<dynamic> leagues, Color accentColor, Color textColor, Color subTextColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D44) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white10 : Colors.black12),
            child: const Icon(Icons.public, color: Colors.blue, size: 20),
          ),
          title: Text(countryName, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(leagues.length.toString(), style: TextStyle(color: textColor, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, color: subTextColor),
            ],
          ),
          children: leagues.map((l) => _buildLeagueItem(l, accentColor)).toList(),
        ),
      ),
    );
  }


  bool _isFollowingExpanded = true;
  bool _isAllTeamsExpanded = true;

  Widget _buildTeamsTab(Color accentColor, Color cardColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Consumer2<TeamListProvider, FollowProvider>(
      builder: (context, teamProvider, followProvider, _) {
        if (teamProvider.isLoading && teamProvider.teams.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueGrey));
        }

        // 1. Filtered data
        final filteredTeams = teamProvider.teams.where((t) {
          final name = t['name']?.toLowerCase() ?? "";
          return name.contains(_teamSearchQuery.toLowerCase());
        }).toList();

        final followedTeams = filteredTeams.where((t) => followProvider.isTeamFollowed(t['id'])).toList();

        // 2. Index Calculation Helpers
        const int searchBarIndex = 0;
        const int followingHeaderIndex = 1;
        
        final int followingItemsCount = _isFollowingExpanded 
            ? (followedTeams.isEmpty ? 1 : followedTeams.length) 
            : 0;
        
        final int allHeaderIndex = followingHeaderIndex + 1 + followingItemsCount;
        
        final int allTeamsItemsCount = _isAllTeamsExpanded ? filteredTeams.length : 0;
        
        final int loadingIndicatorIndex = allHeaderIndex + 1 + allTeamsItemsCount;
        
        final int totalItems = loadingIndicatorIndex + (teamProvider.hasMore ? 1 : 0) + 1; // +1 for bottom scroll padding

        return ListView.builder(
          controller: _teamScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // 0: Search Bar
            if (index == searchBarIndex) {
              return Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: _buildTeamSearchBar(cardColor),
              );
            }

            // 1: Following Header
            if (index == followingHeaderIndex) {
              return _buildSectionHeader(
                icon: Icons.star,
                iconColor: isDark ? Colors.tealAccent : Colors.teal,
                title: "Following",
                count: followedTeams.length,
                isExpanded: _isFollowingExpanded,
                onToggle: () => setState(() => _isFollowingExpanded = !_isFollowingExpanded),
              );
            }

            // Following Content
            if (_isFollowingExpanded && index > followingHeaderIndex && index < allHeaderIndex) {
              if (followedTeams.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("You are not following any teams", style: TextStyle(color: subTextColor)),
                );
              }
              final teamIdx = index - (followingHeaderIndex + 1);
              if (teamIdx >= 0 && teamIdx < followedTeams.length) {
                return _buildTeamItem(followedTeams[teamIdx], accentColor, followProvider);
              }
            }

            // All Leagues Header
            if (index == allHeaderIndex) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildSectionHeader(
                  icon: Icons.thumb_up,
                  iconColor: isDark ? Colors.tealAccent : Colors.teal,
                  title: "All Teams",
                  count: teamProvider.teams.length,
                  isExpanded: _isAllTeamsExpanded,
                  onToggle: () => setState(() => _isAllTeamsExpanded = !_isAllTeamsExpanded),
                ),
              );
            }

            // All Leagues Content
            if (_isAllTeamsExpanded && index > allHeaderIndex && index < loadingIndicatorIndex) {
              final teamIdx = index - (allHeaderIndex + 1);
              if (teamIdx >= 0 && teamIdx < filteredTeams.length) {
                return _buildTeamItem(filteredTeams[teamIdx], accentColor, followProvider);
              }
            }

            // Loading Indicator
            if (teamProvider.hasMore && index == loadingIndicatorIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: accentColor, strokeWidth: 2),
                      const SizedBox(height: 8),
                      Text(
                        "Loading more teams (${teamProvider.teams.length} loaded)...",
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Bottom Spacing
            if (index == totalItems - 1) {
              return const SizedBox(height: 40);
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D44) : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(), 
                style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: subTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSearchBar(Color cardColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _teamSearchController,
        style: TextStyle(color: textColor),
        onChanged: (val) {
          setState(() => _teamSearchQuery = val);
          if (_teamDebounce?.isActive ?? false) _teamDebounce!.cancel();
          _teamDebounce = Timer(const Duration(milliseconds: 500), () {
            if (val.isNotEmpty) {
              context.read<TeamListProvider>().searchTeams(val);
            } else {
              context.read<TeamListProvider>().fetchTeams(forceRefresh: true);
            }
          });
        },
        onSubmitted: (val) {
          if (val.isNotEmpty) {
            context.read<TeamListProvider>().searchTeams(val);
          } else {
            context.read<TeamListProvider>().fetchTeams(forceRefresh: true);
          }
        },
        decoration: InputDecoration(
          hintText: "Type to search teams",
          hintStyle: TextStyle(color: subTextColor),
          prefixIcon: Icon(Icons.search, color: subTextColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTeamItem(dynamic team, Color accentColor, FollowProvider followProvider) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    final isFollowed = followProvider.isTeamFollowed(team['id']);
    
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailsScreen(
              teamId: team['id'],
              teamName: team['name'] ?? 'Unknown',
              teamLogo: team['image_path'] ?? '',
            ),
          ),
        );
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: team['image_path'] != null 
          ? Image.network(team['image_path'], width: 35, height: 35, fit: BoxFit.cover)
          : Container(
              width: 35, 
              height: 35, 
              color: isDark ? Colors.white10 : Colors.black12, 
              child: Icon(Icons.shield, color: accentColor, size: 24)
            ),
      ),
      title: Text(team['name'] ?? 'Unknown', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(isFollowed ? Icons.star : Icons.star_border, 
                 color: isFollowed ? accentColor : subTextColor),
            onPressed: () => followProvider.toggleFollowTeam(team['id']),
          ),
          IconButton(
            icon: Icon(isFollowed ? Icons.notifications : Icons.notifications_none, 
                 color: isFollowed ? (isDark ? Colors.tealAccent : Colors.teal) : subTextColor, size: 22),
            onPressed: () {}, // Notification toggle placeholder
          ),
        ],
      ),
    );
  }
}
