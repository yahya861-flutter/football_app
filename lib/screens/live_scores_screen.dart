import 'package:flutter/material.dart';
import 'package:football_app/providers/fixture_provider.dart';
import 'package:football_app/screens/match_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:football_app/providers/inplay_provider.dart';

class LiveScoresScreen extends StatefulWidget {
  const LiveScoresScreen({super.key});

  @override
  State<LiveScoresScreen> createState() => _LiveScoresScreenState();
}

class _LiveScoresScreenState extends State<LiveScoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InPlayProvider>().fetchInPlayMatches();
      context.read<FixtureProvider>().fetchTodayFixtures();
      context.read<FixtureProvider>().fetchAllFixturesByDateRange();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFD4FF00);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Sub Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: TabBar(
              isScrollable: true,
              indicatorColor: accentColor,
              labelColor: accentColor,
              unselectedLabelColor: Colors.white38,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              tabs: const [
                Tab(text: "Live"),
                Tab(text: "Today"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // LIVE TAB
                Column(
                  children: [
                    _buildLiveHeader(),
                    Expanded(child: _buildInPlayList()),
                  ],
                ),
                // TODAY TAB (Consolidated Today + Upcoming)
                _buildConsolidatedMatchesTab(accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveHeader() {
    return Consumer<InPlayProvider>(
      builder: (context, inPlay, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Live",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "(${inPlay.inPlayMatches.length})",
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                onPressed: () => inPlay.fetchInPlayMatches(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInPlayList() {
    return Consumer<InPlayProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.inPlayMatches.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
        }

        if (provider.inPlayMatches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_soccer, color: Colors.white10, size: 64),
                const SizedBox(height: 16),
                const Text("No live matches at the moment", style: TextStyle(color: Colors.white38)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => provider.fetchInPlayMatches(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                  child: const Text("Refresh", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        // Group by league
        Map<String, List<dynamic>> groupedMatches = {};
        for (var match in provider.inPlayMatches) {
          final leagueName = match['league']?['name'] ?? 'Other';
          if (!groupedMatches.containsKey(leagueName)) {
            groupedMatches[leagueName] = [];
          }
          groupedMatches[leagueName]!.add(match);
        }

        final leagues = groupedMatches.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: leagues.length,
          itemBuilder: (context, index) {
            final leagueName = leagues[index];
            final matches = groupedMatches[leagueName]!;
            final leagueLogo = matches.first['league']?['image_path'];
            
            return _buildLeagueGroup(leagueName, leagueLogo, matches);
          },
        );
      },
    );
  }

  Widget _buildLeagueGroup(String name, String? logo, List<dynamic> matches) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: logo != null 
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(logo, width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, color: Colors.white24, size: 24)),
              )
            : const Icon(Icons.emoji_events, color: Colors.white24, size: 24),
          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
          children: matches.map((m) => _buildMatchRow(m)).toList(),
        ),
      ),
    );
  }

  Widget _buildMatchRow(dynamic match) {
    final participants = match['participants'] as List? ?? [];
    final scores = match['scores'] as List? ?? [];
    
    dynamic homeTeam;
    dynamic awayTeam;
    if (participants.isNotEmpty) {
      homeTeam = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
      if (participants.length > 1) {
        awayTeam = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
      }
    }

    String homeScore = "0";
    String awayScore = "0";
    if (scores.isNotEmpty) {
      final hScoreObj = scores.firstWhere((s) => s['participant_id'] == homeTeam?['id'] && s['description'] == 'CURRENT', orElse: () => null);
      final aScoreObj = scores.firstWhere((s) => s['participant_id'] == awayTeam?['id'] && s['description'] == 'CURRENT', orElse: () => null);
      if (hScoreObj != null) homeScore = hScoreObj['score']?['goals']?.toString() ?? "0";
      if (aScoreObj != null) awayScore = aScoreObj['score']?['goals']?.toString() ?? "0";
    }

    // State handle
    final state = match['state'];
    String period = state?['short_name'] ?? state?['name'] ?? "Live";
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsScreen(
              fixture: match,
              leagueId: match['league_id'] ?? 0,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: Row(
          children: [
            // Status Box
            Container(
              width: 45,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D44),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                period,
                style: const TextStyle(color: Color(0xFFD4FF00), fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 16),
            // Teams and Scores
            Expanded(
              child: Column(
                children: [
                  _buildTeamRow(homeTeam?['name'] ?? 'Home', homeTeam?['image_path'] ?? '', homeScore),
                  const SizedBox(height: 10),
                  _buildTeamRow(awayTeam?['name'] ?? 'Away', awayTeam?['image_path'] ?? '', awayScore),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Alarm Icon
            const Icon(Icons.notifications_none, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(String name, String img, String score) {
    return Row(
      children: [
        if (img.isNotEmpty)
          Image.network(img, width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 20, color: Colors.white24))
        else
          const Icon(Icons.shield, size: 20, color: Colors.white24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          score,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  // --- CONSOLIDATED MATCHES TAB HELPERS ---

  Widget _buildConsolidatedMatchesTab(Color accentColor) {
    return Consumer<FixtureProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.todayFixtures.isEmpty && provider.fixtures.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
        }

        final combinedFixtures = [...provider.todayFixtures, ...provider.fixtures];
        
        // Remove duplicates if any (though endpoints shouldn't overlap much)
        final seenIds = <int>{};
        final uniqueFixtures = combinedFixtures.where((f) => seenIds.add(f['id'])).toList();

        if (uniqueFixtures.isEmpty) {
          return const Center(child: Text("No matches found", style: TextStyle(color: Colors.white38)));
        }

        // Group by league
        Map<String, List<dynamic>> groupedByLeague = {};
        for (var f in uniqueFixtures) {
          final leagueName = f['league']?['name'] ?? 'Other';
          groupedByLeague.putIfAbsent(leagueName, () => []).add(f);
        }

        final leagues = groupedByLeague.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: leagues.length,
          itemBuilder: (context, index) {
            final leagueName = leagues[index];
            final fixtures = groupedByLeague[leagueName]!;
            final leagueLogo = fixtures.first['league']?['image_path'];
            
            return _buildConsolidatedLeagueGroup(leagueName, leagueLogo, fixtures, accentColor);
          },
        );
      },
    );
  }

  Widget _buildConsolidatedLeagueGroup(String name, String? logo, List<dynamic> matches, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: logo != null 
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(logo, width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, color: Colors.white24, size: 24)),
              )
            : const Icon(Icons.emoji_events, color: Colors.white24, size: 24),
          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
          children: matches.map((m) => _buildConsolidatedMatchRow(m)).toList(),
        ),
      ),
    );
  }

  Widget _buildConsolidatedMatchRow(dynamic match) {
    final participants = match['participants'] as List? ?? [];
    final scores = match['scores'] as List? ?? [];
    final timestamp = match['starting_at_timestamp'];

    String time = "N/A";
    String date = "";
    if (timestamp != null) {
      final localDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
      time = DateFormat('HH:mm').format(localDateTime);
      // Only show date if it's not today
      final now = DateTime.now();
      if (localDateTime.day != now.day || localDateTime.month != now.month || localDateTime.year != now.year) {
        date = DateFormat('MMM d').format(localDateTime);
      }
    }
    
    dynamic homeTeam;
    dynamic awayTeam;
    if (participants.isNotEmpty) {
      homeTeam = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
      if (participants.length > 1) {
        awayTeam = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
      }
    }

    String homeScore = "-";
    String awayScore = "-";
    
    if (scores.isNotEmpty) {
      final hScoreObj = scores.firstWhere((s) => s['participant_id'] == homeTeam?['id'] && (s['description'] == 'CURRENT' || s['description'] == 'FT'), orElse: () => null);
      final aScoreObj = scores.firstWhere((s) => s['participant_id'] == awayTeam?['id'] && (s['description'] == 'CURRENT' || s['description'] == 'FT'), orElse: () => null);
      if (hScoreObj != null) homeScore = hScoreObj['score']?['goals']?.toString() ?? "0";
      if (aScoreObj != null) awayScore = aScoreObj['score']?['goals']?.toString() ?? "0";
    }

    final state = match['state'];
    String period = state?['short_name'] ?? state?['name'] ?? "Sch";
    
    // Check if it's currently live based on Sportmonks state IDs
    // Commonly: 2=LIVE, 3=HT, 6=PEN_LIVE, 22=ET_HT, etc.
    final stateId = state?['id'];
    bool isLive = stateId != null && [2, 3, 6, 9, 10, 11, 12, 13, 14, 15, 22].contains(stateId);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsScreen(
              fixture: match,
              leagueId: match['league_id'] ?? 0,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: Row(
          children: [
            // Status Box
            Container(
              width: 55,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D44),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Text(
                    period == "Sch" || period == "NS" ? time : period,
                    style: TextStyle(
                      color: isLive ? const Color(0xFFD4FF00) : Colors.white70, 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (date.isNotEmpty)
                    Text(
                      date,
                      style: const TextStyle(color: Colors.white38, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Teams and Scores
            Expanded(
              child: Column(
                children: [
                  _buildTeamRow(homeTeam?['name'] ?? 'Home', homeTeam?['image_path'] ?? '', homeScore),
                  const SizedBox(height: 10),
                  _buildTeamRow(awayTeam?['name'] ?? 'Away', awayTeam?['image_path'] ?? '', awayScore),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.notifications_none, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

