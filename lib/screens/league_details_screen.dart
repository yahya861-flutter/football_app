import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:football_app/providers/league_provider.dart';
import 'package:football_app/providers/match_provider.dart';
import 'package:provider/provider.dart';
/// This screen shows detailed information for a single football league.
/// It also fetches and displays live (in-play) matches specifically for this league.
class LeagueDetailsScreen extends StatefulWidget {
  final int leagueId;

  const LeagueDetailsScreen({super.key, required this.leagueId});

  @override
  State<LeagueDetailsScreen> createState() => _LeagueDetailsScreenState();
}

class _LeagueDetailsScreenState extends State<LeagueDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch league details and current in-play matches on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final leagueProvider = context.read<LeagueProvider>();
      await leagueProvider.fetchLeagueById(widget.leagueId);
      
      // Fetch standings once we have the season ID
      final seasonId = leagueProvider.currentSeasonId;
      if (seasonId != null) {
        leagueProvider.fetchStandings(seasonId);
      }
      
      context.read<MatchProvider>().fetchInPlayMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E1E2C);
    const Color accentColor = Color(0xFFD4FF00); // Premium Lime accent

    return DefaultTabController(
      length: 4, // Home, Table, Results, Fixtures
      child: Scaffold(
        backgroundColor: primaryColor,
        body: Consumer2<LeagueProvider, MatchProvider>(
          builder: (context, leagueProvider, matchProvider, child) {
            // Loading state for initial data fetch
            if (leagueProvider.isLoading && leagueProvider.selectedLeague == null) {
              return const Center(child: CircularProgressIndicator(color: accentColor));
            }

            final league = leagueProvider.selectedLeague;
            if (league == null) {
              return const Center(
                child: Text("No details found", style: TextStyle(color: Colors.white70)),
              );
            }

            final name = league['name'] ?? 'Unknown';
            final imagePath = league['image_path'] ?? '';
            final shortCode = league['short_code'] ?? 'N/A';

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 320, // Increased to fix overflow with the new spacing
                    pinned: true,
                    backgroundColor: primaryColor,
                    elevation: 0,
                    // The standard back button
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Flexible space contains the Logo and Name (Header)
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 80), // Increased gap from the toolbar area
                          // League Logo in a circular container
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D44),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white10),
                            ),
                            child: imagePath.isNotEmpty
                                ? Image.network(imagePath, height: 90, width: 90, fit: BoxFit.contain)
                                : const Icon(Icons.emoji_events, size: 60, color: Colors.white24),
                          ),
                          const SizedBox(height: 16),
                          // League Name
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Short Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              shortCode,
                              style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 20), // Added gap from the bottom (tabs)
                        ],
                      ),
                    ),
                    // TabBar is sticky at the bottom of the header
                    bottom: const TabBar(
                      isScrollable: false, // Fixed tabs that stretch to fill width
                      indicatorColor: accentColor,
                      labelColor: accentColor,
                      unselectedLabelColor: Colors.white38,
                      indicatorWeight: 3,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      tabs: [
                        Tab(text: "Home"),
                        Tab(text: "Table"),
                        Tab(text: "Results"),
                        Tab(text: "Fixtures"),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                // Disable swiping (view-pager type) so it's tappable only
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // HOME TAB - Refactored to only show details, teams and scores
                  _buildHomeTabContent(league, leagueProvider, matchProvider, accentColor),
                  
                  // PLACEHOLDERS
                  _buildPlaceholderTab("League Table", Icons.table_chart, accentColor),
                  _buildPlaceholderTab("Recent Results", Icons.history, accentColor),
                  _buildPlaceholderTab("Upcoming Fixtures", Icons.calendar_month, accentColor),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the content for the "Home" tab (Info, Teams, and Live Scores)
  Widget _buildHomeTabContent(dynamic league, LeagueProvider leagueProvider, MatchProvider matchProvider, Color accentColor) {
    final type = league['type'] ?? 'N/A';
    final subType = league['sub_type'] ?? 'N/A';

    final filteredMatches = matchProvider.inPlayMatches.where((match) => 
      match['league_id'] == widget.leagueId
    ).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("League Info", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoRow("Type", type.toString().toUpperCase()),
          _buildInfoRow("Sub-Type", subType.toString().replaceAll('_', ' ').toUpperCase()),
          _buildInfoRow("Category", (league['category'] ?? 'N/A').toString()),
          _buildInfoRow("Has Jerseys", (league['has_jerseys'] == true ? "YES" : "NO")),

          const SizedBox(height: 40),
          // STANDINGS SECTION
          const Text("Standings", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (leagueProvider.standings.isEmpty && !leagueProvider.isLoading)
            const Text("No standings found for this season", style: TextStyle(color: Colors.white38))
          else if (leagueProvider.isLoading && leagueProvider.standings.isEmpty)
             const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)))
          else
            Column(
              children: leagueProvider.standings.map((standing) => _buildStandingRow(standing, accentColor)).toList(),
            ),

          const SizedBox(height: 40),
          Text("Live Score", style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (matchProvider.isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)))
          else if (filteredMatches.isEmpty)
             const Padding(
               padding: EdgeInsets.only(top: 10),
               child: Text("No in-play matches for this league", style: TextStyle(color: Colors.white38)),
             )
          else
            ...filteredMatches.map((match) => _buildLiveMatchCard(match)).toList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Builds a small item for a team (Logo + Name)
  Widget _buildTeamItem(dynamic team) {
    final name = team['name'] ?? 'Unknown';
    final imagePath = team['image_path'] ?? '';

    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D44),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: imagePath.isNotEmpty
                ? Image.network(imagePath, fit: BoxFit.contain)
                : const Icon(Icons.shield, color: Colors.white24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Builds a clean row for a team standing
  Widget _buildStandingRow(dynamic standing, Color accentColor) {
    final team = standing['participant'] ?? {};
    final position = standing['position'] ?? '-';
    final points = standing['points'] ?? 0;
    
    final teamName = team['name'] ?? 'Unknown';
    final teamLogo = team['image_path'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // RANK
          SizedBox(
            width: 30,
            child: Text(
              position.toString(),
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          // LOGO
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: teamLogo.isNotEmpty
                ? Image.network(teamLogo, fit: BoxFit.contain)
                : const Icon(Icons.shield, size: 16, color: Colors.white24),
          ),
          const SizedBox(width: 12),
          // NAME
          Expanded(
            child: Text(
              teamName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // POINTS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "$points PTS",
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to build a clean placeholder for empty tabs
  Widget _buildPlaceholderTab(String title, IconData icon, Color accentColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Icon(icon, size: 80, color: Colors.white10),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Content coming soon", style: TextStyle(color: Colors.white38, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  /// Builds a small card for a live match
  Widget _buildLiveMatchCard(dynamic match) {
    final matchName = match['name'] ?? 'Unknown Match';
    final result = match['result_info'] ?? 'Live';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(matchName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(result, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  /// Helper row for key-value info
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Builds the "Top Scorers" tab content
  Widget _buildTopScorersTab(List<dynamic> topScorers, bool isLoading, Color accentColor) {
    if (isLoading && topScorers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
    }

    if (topScorers.isEmpty) {
      return _buildPlaceholderTab("Top Scorers", Icons.emoji_events, accentColor);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topScorers.length,
      itemBuilder: (context, index) {
        final scorer = topScorers[index];
        return _buildTopScorerCard(scorer, accentColor);
      },
    );
  }

  /// Builds a premium card for a top scorer
  Widget _buildTopScorerCard(dynamic scorer, Color accentColor) {
    final player = scorer['player'] ?? {};
    final team = scorer['participant'] ?? {};
    final goals = scorer['total'] ?? 0;
    final position = scorer['position'] ?? '-';
    
    final playerName = player['display_name'] ?? player['common_name'] ?? 'Unknown Player';
    final playerImage = player['image_path'] ?? '';
    final teamName = team['name'] ?? 'Unknown Team';
    final teamLogo = team['image_path'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Position Rank
          SizedBox(
            width: 30,
            child: Text(
              position.toString(),
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 8),
          // Player Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white10,
              image: playerImage.isNotEmpty
                  ? DecorationImage(image: NetworkImage(playerImage), fit: BoxFit.cover)
                  : null,
            ),
            child: playerImage.isEmpty ? const Icon(Icons.person, color: Colors.white24) : null,
          ),
          const SizedBox(width: 12),
          // Player & Team Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (teamLogo.isNotEmpty)
                      Image.network(teamLogo, width: 16, height: 16)
                    else
                      const Icon(Icons.shield, size: 16, color: Colors.white24),
                    const SizedBox(width: 6),
                    Text(
                      teamName,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Goal Count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                goals.toString(),
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const Text(
                "GOALS",
                style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
