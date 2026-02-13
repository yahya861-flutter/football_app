import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import 'package:football_app/l10n/app_localizations.dart';
import '../providers/follow_provider.dart';
import '../providers/league_provider.dart';
import '../widgets/notifications_activated_dialog.dart';
import 'league_details_screen.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeagueProvider>().fetchLeagues();
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
    _searchController.dispose();
    super.dispose();
  }

  bool _isLeaguesFavoriteExpanded = true;
  bool _isLeaguesTopExpanded = true;
  bool _isLeaguesSuggestionsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? Colors.black : Colors.white;
    const Color accentColor = Color(0xFFFF8700);
    final Color cardColor = isDark ? const Color(0xFF121212) : Colors.white;
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: primaryColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? primaryColor : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
            ),
            child: TabBar(
              indicatorColor: accentColor,
              indicatorWeight: 3,
              labelColor: isDark ? Colors.white : Colors.black,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelColor: isDark ? Colors.white38 : Colors.black45,
              tabs: [
                Tab(text: l10n.leagues),
                Tab(text: l10n.favorite),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildLeaguesTab(accentColor, cardColor, l10n),
            _buildFavoriteLeaguesTab(accentColor, cardColor, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguesTab(Color accentColor, Color cardColor, AppLocalizations l10n) {
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

        // 2. Grouping
        Map<String, Map<String, dynamic>> leaguesByCountryMap = {};
        for (var league in filteredLeagues) {
          final country = league['country'];
          final countryName = country?['name'] ?? 'International';
          final flagUrl = country?['image_path'];
          
          if (!leaguesByCountryMap.containsKey(countryName)) {
            leaguesByCountryMap[countryName] = {
              'flag': flagUrl,
              'leagues': <dynamic>[],
            };
          }
          leaguesByCountryMap[countryName]!['leagues'].add(league);
        }
        final countryEntries = leaguesByCountryMap.entries.toList();

        // 3. Build flattened list
        final List<Widget> items = [];
        
        // Search
        items.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          child: _buildSearchBar(cardColor, l10n),
        ));

        // Top Leagues
        items.add(Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildSectionHeader(
            icon: Icons.thumb_up, iconColor: isDark ? Colors.tealAccent : Colors.teal, title: l10n.topLeagues, count: topLeagues.length,
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
            icon: Icons.lightbulb_outline, iconColor: isDark ? Colors.tealAccent : Colors.teal, title: l10n.suggestions, count: 5,
            isExpanded: _isLeaguesSuggestionsExpanded,
            onToggle: () => setState(() => _isLeaguesSuggestionsExpanded = !_isLeaguesSuggestionsExpanded),
          ),
        ));
        if (_isLeaguesSuggestionsExpanded) {
          items.add(_buildSuggestionsRow(accentColor, cardColor, leagueProvider.leagues, textColor));
        }

        items.add(Padding(
          padding: const EdgeInsets.only(top: 32, bottom: 16),
          child: Text(l10n.allLeagues, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ));

        // Country Groups
        items.addAll(countryEntries.map((entry) => _buildCountryExpandable(entry.key, entry.value['leagues'], entry.value['flag'], accentColor, textColor, subTextColor, isDark)));

        // Loading Indicator
        if (leagueProvider.hasMore) {
          items.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: accentColor, strokeWidth: 2),
                  const SizedBox(height: 8),
                  Text("${l10n.loadingMoreLeagues} (${leagueProvider.leagues.length})...", style: TextStyle(color: subTextColor, fontSize: 12)),
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
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white.withOpacity(0.34) : Colors.black38;

    final String name = league['name'] ?? 'League';
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeagueDetailsScreen(leagueId: league['id']),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: league['image_path'] != null 
                ? Image.network(league['image_path'], width: 24, height: 24, errorBuilder: (_, __, ___) => Icon(Icons.emoji_events, color: accentColor, size: 20))
                : Icon(Icons.emoji_events, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name, 
                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Consumer<FollowProvider>(
              builder: (context, follow, child) {
                final isFollowed = follow.isLeagueFollowed(league['id']);
                final isNotifEnabled = follow.isNotificationEnabled(league['id']);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFollowed) ...[
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => const NotificationsActivatedDialog(),
                          );
                        },
                        child: Icon(
                          Icons.notifications_active_rounded, 
                          color: accentColor, 
                          size: 22
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    IconButton(
                      icon: Icon(isFollowed ? Icons.star_rounded : Icons.star_outline_rounded, 
                           color: isFollowed ? accentColor : subTextColor, size: 24),
                      onPressed: () => follow.toggleFollowLeague(league['id'], leagueData: league),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

// Expandable content
// Expandable content is now handled by _buildSectionHeader and manual list management for better performance.
// suggestion area
  Widget _buildSuggestionsRow(Color accentColor, Color cardColor, List<dynamic> leagues, Color textColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color subTextColor = isDark ? Colors.white.withOpacity(0.34) : Colors.black38;
    // Pick 5 leagues for suggestions
    final suggestions = leagues.take(5).toList();
    
    return Consumer<FollowProvider>(
      builder: (context, followProvider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: suggestions.map((l) {
              final isFollowed = followProvider.isLeagueFollowed(l['id'] ?? 0);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeagueDetailsScreen(leagueId: l['id'] ?? 0),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.only(left: 14, right: 6, top: 6, bottom: 6),
                  decoration: BoxDecoration(
                    color: isDark ? accentColor.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      if (l['image_path'] != null)
                        Image.network(l['image_path'], width: 22, height: 22, errorBuilder: (_, __, ___) => Icon(Icons.emoji_events, color: accentColor, size: 20))
                      else
                        Icon(Icons.emoji_events, color: accentColor, size: 20),
                      const SizedBox(width: 10),
                      Text(l['name'] ?? 'League', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          isFollowed ? Icons.star_rounded : Icons.star_outline_rounded, 
                          color: isFollowed ? accentColor : subTextColor, 
                          size: 20
                        ),
                        onPressed: () => followProvider.toggleFollowLeague(l['id'] ?? 0, leagueData: l),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }
    );
  }

  Widget _buildCountryExpandable(String countryName, List<dynamic> leagues, String? flagUrl, Color accentColor, Color textColor, Color subTextColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05), width: 1) : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: flagUrl != null
                  ? Image.network(
                      flagUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.public_rounded, color: Colors.blue, size: 20),
                    )
                  : const Icon(Icons.public_rounded, color: Colors.blue, size: 20),
            ),
          ),
          title: Text(
            countryName, 
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            "${leagues.length} Leagues",
            style: TextStyle(color: subTextColor, fontSize: 13),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  leagues.length.toString(), 
                  style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, color: subTextColor, size: 18),
              ],
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: leagues.map((l) => _buildLeagueItem(l, accentColor)).toList(),
              ),

            )],
        ),
      ),
    );
  }


  bool _isFavoriteExpanded = true;
  bool _isAllTeamsExpanded = true;

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title, 
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(), 
                style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: subTextColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color cardColor, AppLocalizations l10n) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white.withOpacity(0.34) : Colors.black45;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05), width: 1) : null,
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: textColor, fontSize: 14),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: l10n.searchLeagues,
          hintStyle: TextStyle(color: subTextColor, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: subTextColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFavoriteLeaguesTab(Color accentColor, Color cardColor, AppLocalizations l10n) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Consumer<FollowProvider>(
      builder: (context, followProvider, child) {
        final followedLeagues = context.watch<LeagueProvider>().leagues.where((l) => followProvider.isLeagueFollowed(l['id'])).toList();

        if (followedLeagues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline_rounded, size: 64, color: subTextColor),
                const SizedBox(height: 16),
                Text(l10n.noFavoriteLeagues, style: TextStyle(color: textColor, fontSize: 16)),
                const SizedBox(height: 8),
                Text(l10n.starLeaguePrompt, style: TextStyle(color: subTextColor, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: followedLeagues.length,
          itemBuilder: (context, index) {
            return _buildLeagueItem(followedLeagues[index], accentColor);
          },
        );
      },
    );
  }
}
