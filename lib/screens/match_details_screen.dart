import 'package:flutter/material.dart';
import 'package:football_app/providers/fixture_provider.dart';
import 'package:football_app/providers/league_provider.dart';
import 'package:football_app/providers/h2h_provider.dart';
import 'package:football_app/providers/stats_provider.dart';
import 'package:football_app/providers/lineup_provider.dart';
import 'package:football_app/providers/commentary_provider.dart';
import 'package:football_app/screens/team_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MatchDetailsScreen extends StatefulWidget {
  final dynamic fixture;
  final int leagueId;

  const MatchDetailsScreen({
    super.key,
    required this.fixture,
    required this.leagueId,
  });

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  String _h2hView = "Overall"; // "Overall" or "Last 5"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FixtureProvider>().fetchFixturesByDateRange(widget.leagueId);
      
      final participants = widget.fixture['participants'] as List? ?? [];
      int? team1Id;
      int? team2Id;

      debugPrint('MatchDetails participants: ${participants.length}');

      if (participants.isNotEmpty) {
        final home = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
        team1Id = home['id'];
        if (participants.length > 1) {
          final away = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
          team2Id = away['id'];
        }
      }

      debugPrint('MatchDetails team1: $team1Id, team2: $team2Id');

      if (team1Id != null && team2Id != null) {
        context.read<H2HProvider>().fetchH2HMatches(team1Id, team2Id);
      }

      final fixtureId = widget.fixture['id'];
      if (fixtureId != null) {
        context.read<StatsProvider>().fetchStats(fixtureId);
        context.read<StatsProvider>().fetchEvents(fixtureId);
        context.read<LineupProvider>().fetchLineupsAndBench(fixtureId);
        context.read<CommentaryProvider>().fetchComments(fixtureId);
        // Fetch Live Standings for the league
        context.read<LeagueProvider>().fetchLiveStandings(widget.leagueId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFF8700);
    final participants = widget.fixture['participants'] as List? ?? [];
    
    dynamic homeTeam;
    dynamic awayTeam;
    if (participants.isNotEmpty) {
      homeTeam = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
      if (participants.length > 1) {
        awayTeam = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
      }
    }

    final homeName = homeTeam?['name'] ?? 'Home';
    final awayName = awayTeam?['name'] ?? 'Away';
    final homeImg = homeTeam?['image_path'] ?? '';
    final awayImg = awayTeam?['image_path'] ?? '';

    final scores = widget.fixture['scores'] as List? ?? [];
    String homeScoreStr = "0";
    String awayScoreStr = "0";
    String htScoreStr = "";
    
    if (homeTeam != null && awayTeam != null) {
      // Find current and half-time scores
      for (var score in scores) {
        final type = score['description']?.toString().toUpperCase() ?? '';
        final goals = score['score']?['goals'] ?? score['goals'];
        
        if (type == 'CURRENT' || type == 'FT' || type.isEmpty) {
          if (score['participant_id'] == homeTeam['id']) {
            if (goals != null) homeScoreStr = goals.toString();
          }
          if (score['participant_id'] == awayTeam['id']) {
            if (goals != null) awayScoreStr = goals.toString();
          }
        }
        
        if (type == 'HT' || type == '1ST_HALF') {
          final hScore = scores.firstWhere((s) => s['participant_id'] == homeTeam['id'] && (s['description'] == 'HT' || s['description'] == '1ST_HALF'), orElse: () => null);
          final aScore = scores.firstWhere((s) => s['participant_id'] == awayTeam['id'] && (s['description'] == 'HT' || s['description'] == '1ST_HALF'), orElse: () => null);
          
          if (hScore != null && aScore != null) {
            final hG = hScore['score']?['goals'] ?? hScore['goals'] ?? 0;
            final aG = aScore['score']?['goals'] ?? aScore['goals'] ?? 0;
            htScoreStr = "$hG - $aG";
          }
        }
      }
    }

    final stateCode = widget.fixture['state']?['state'] ?? 'NS';
    final stateName = widget.fixture['state']?['name'] ?? '';
    final isLive = ['INPLAY', 'INPLAY_1ST_HALF', 'INPLAY_2ND_HALF', 'HT', 'INPLAY_ET'].contains(stateCode);
    final isFinished = ['FT', 'AET', 'FT_PEN'].contains(stateCode);
    final isUpcoming = stateCode == 'NS' || stateCode == 'TBA';

    final timestamp = widget.fixture['starting_at_timestamp'];
    String matchTime = "N/A";
    String matchDate = "N/A";
    if (timestamp != null) {
      final localDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
      matchTime = DateFormat('HH:mm').format(localDate);
      matchDate = DateFormat('yyyy-MM-dd').format(localDate);
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white54 : Colors.black54;
    final Color headerColor = isDark ? const Color(0xFF131321) : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.grey[50]!;
    
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF131321) : Colors.white,
        appBar: AppBar(
          backgroundColor: headerColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(240),
            child: Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: headerColor,
                border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
              ),
              child: Column(
                children: [
                  // Team Logos and Score/Time
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Home Team
                        Expanded(child: _buildHeaderTeam(homeName, homeImg, homeTeam?['id'] ?? 0, true, isDark, textColor)),
                        
                        // Match Info Center
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              if (isUpcoming) ...[
                                Text(
                                  matchTime,
                                  style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    matchDate,
                                    style: const TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  "$homeScoreStr - $awayScoreStr",
                                  style: TextStyle(color: textColor, fontSize: 38, fontWeight: FontWeight.bold, letterSpacing: -1),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLive)
                                      _buildLiveIndicator(),
                                    Text(
                                      isLive ? "LIVE - $stateName" : stateName,
                                      style: TextStyle(
                                        color: isLive ? Colors.redAccent : subTextColor,
                                        fontSize: 12,
                                        fontWeight: isLive ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (htScoreStr.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "HT: $htScoreStr",
                                    style: TextStyle(color: subTextColor, fontSize: 11),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        
                        // Away Team
                        Expanded(child: _buildHeaderTeam(awayName, awayImg, awayTeam?['id'] ?? 0, false, isDark, textColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // TabBar
                  TabBar(
                    isScrollable: true,
                    indicatorColor: accentColor,
                    labelColor: accentColor,
                    unselectedLabelColor: subTextColor,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    tabs: const [
                      Tab(text: "INFO"),
                      Tab(text: "H2H"),
                      Tab(text: "STATS"),
                      Tab(text: "LINEUP"),
                      Tab(text: "TABLE"),
                      Tab(text: "COMMENTS"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(widget.fixture, htScoreStr),
            _buildH2HTab(accentColor),
            _buildStatsTab(accentColor),
            _buildLineupTab(accentColor),
            _buildTableTab(context),
            _buildCommentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      width: 8, height: 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: const BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.redAccent, blurRadius: 4, spreadRadius: 1),
        ],
      ),
    );
  }

  Widget _buildHeaderTeam(String name, String img, int id, bool isHome, bool isDark, Color textColor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailsScreen(
              teamId: id,
              teamName: name,
              teamLogo: img,
            ),
          ),
        );
      },
      child: Column(
        children: [
          _buildTeamLogo(img, isDark),
          const SizedBox(height: 14),
          Text(
            name,
            style: TextStyle(
              color: textColor, 
              fontSize: 13, 
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String img, bool isDark) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
      ),
      child: Hero(
        tag: 'team-logo-$img',
        child: img.isNotEmpty
          ? Image.network(img, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, size: 32, color: Colors.grey))
          : const Icon(Icons.shield_rounded, size: 32, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoTab(dynamic fixture, String htScore) {
    final venueName = fixture['venue']?['name'] ?? 'Unknown Venue';
    final city = fixture['venue']?['city'] ?? 'Unknown City';
    final timestamp = fixture['starting_at_timestamp'];
    String formattedKickOff = "N/A";
    if (timestamp != null) {
      final localDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
      formattedKickOff = DateFormat('EEEE, d MMM yyyy, HH:mm').format(localDate);
    }

    final leagueName = fixture['league']?['name'] ?? 'Competition';

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black38;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: General Information
          _buildExpansionCard(
            icon: Icons.info_outline,
            title: "Match Information",
            initiallyExpanded: true,
            content: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(Icons.emoji_events_outlined, "Competition", leagueName),
                  _buildInfoRow(Icons.access_time, "Kick off", formattedKickOff),
                  if (htScore.isNotEmpty)
                    _buildInfoRow(Icons.timer_outlined, "Half Time Result", htScore),
                  _buildInfoRow(Icons.location_on_outlined, "Venue", "$venueName, $city", showMap: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Poll Section
          _buildExpansionCard(
            icon: Icons.poll_outlined,
            title: "Match Poll",
            content: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text("Who will win?", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPollButton("Home", "45%"),
                      _buildPollButton("Draw", "15%"),
                      _buildPollButton("Away", "40%"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollButton(String label, String percent) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ),
          child: Text(
            percent, 
            style: const TextStyle(color: Color(0xFFFF8700), fontWeight: FontWeight.bold, fontSize: 16)
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label, 
          style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }

  Widget _buildExpansionCard({required IconData icon, required String title, required Widget content, bool initiallyExpanded = false}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
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
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.green, size: 22),
          ),
          title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
          trailing: Icon(Icons.expand_more_rounded, color: subTextColor, size: 24),
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.01) : Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool showMap = false}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF26BC94)),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showMap) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on_rounded, color: Color(0xFFFF8700), size: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildH2HTab(Color accentColor) {
    return Consumer<H2HProvider>(
      builder: (context, h2h, _) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        if (h2h.isLoading) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        if (h2h.h2hMatches.isEmpty) {
          return Center(child: Text("No Head-to-Head data available", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildH2HToggle(),
            const SizedBox(height: 16),
            _buildH2HSummary(h2h.h2hMatches),
            const SizedBox(height: 24),
            const Text("Historical Matches", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...h2h.h2hMatches.map((m) => _buildH2HMatchRow(m)),
          ],
        );
      },
    );
  }

  Widget _buildH2HToggle() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleItem("Overall")),
          Expanded(child: _buildToggleItem("Last 5")),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = _h2hView == title;
    return InkWell(
      onTap: () => setState(() => _h2hView = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8700) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(color: const Color(0xFFFF8700).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : (isDark ? Colors.white54 : Colors.black54),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildH2HSummary(List<dynamic> allMatches) {
    final participants = widget.fixture['participants'] as List? ?? [];
    if (participants.length < 2) return const SizedBox();
    
    List<dynamic> matches = _h2hView == "Last 5" ? allMatches.take(5).toList() : allMatches;
    final home = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
    final away = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
    final homeId = home['id'];
    final awayId = away['id'];
    
    int homeWins = 0, awayWins = 0, draws = 0;
    for (var match in matches) {
      final scores = match['scores'] as List? ?? [];
      final hScoreObj = scores.firstWhere((s) => s['participant_id'] == homeId && (s['description'] == 'FT' || s['description'] == 'CURRENT'), orElse: () => null);
      final aScoreObj = scores.firstWhere((s) => s['participant_id'] == awayId && (s['description'] == 'FT' || s['description'] == 'CURRENT'), orElse: () => null);
      if (hScoreObj != null && aScoreObj != null) {
        int h = hScoreObj['score']?['goals'] ?? 0;
        int a = aScoreObj['score']?['goals'] ?? 0;
        if (h > a) homeWins++; else if (a > h) awayWins++; else draws++;
      }
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: Column(
        children: [
          Text("Win Probability", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryStat(homeWins.toString(), "WINS", home['name']),
              _buildSummaryStat(draws.toString(), "DRAWS", "DRW"),
              _buildSummaryStat(awayWins.toString(), "WINS", away['name']),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: matches.isEmpty ? 0 : homeWins / (homeWins + awayWins + draws),
                backgroundColor: Colors.redAccent.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String value, String label, String teamName) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      children: [
        Text(value, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: subTextColor, fontSize: 10)),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(teamName, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildH2HMatchRow(dynamic match) {
    final participants = match['participants'] as List? ?? [];
    final scores = match['scores'] as List? ?? [];
    
    dynamic home;
    dynamic away;
    if (participants.isNotEmpty) {
      home = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
      if (participants.length > 1) {
        away = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
      }
    }

    String hScore = "0", aScore = "0";
    final hScoreObj = scores.firstWhere((s) => s['participant_id'] == home?['id'] && (s['description'] == 'FT' || s['description'] == 'CURRENT'), orElse: () => null);
    final aScoreObj = scores.firstWhere((s) => s['participant_id'] == away?['id'] && (s['description'] == 'FT' || s['description'] == 'CURRENT'), orElse: () => null);
    
    hScore = hScoreObj?['score']?['goals']?.toString() ?? "0";
    aScore = aScoreObj?['score']?['goals']?.toString() ?? "0";

    final timestamp = match['starting_at_timestamp'];
    String date = "N/A";
    if (timestamp != null) {
      date = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal());
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text(date, style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Text(home?['name'] ?? 'Home', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFFF8700).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text("$hScore - $aScore", style: const TextStyle(color: Color(0xFFFF8700), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(away?['name'] ?? 'Away', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.left, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableTab(BuildContext context) {
    return Consumer<LeagueProvider>(
      builder: (context, leagueProvider, child) {
        final standings = leagueProvider.liveStandings.isNotEmpty 
            ? leagueProvider.liveStandings 
            : leagueProvider.standings;

        if (standings.isEmpty) {
          if (leagueProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8700)));
          }
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Center(child: Text("No table data", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 590,
            child: Column(
              children: [
                if (leagueProvider.liveStandings.isNotEmpty)
              /*    Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        const Text("LIVE STANDINGS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ),*/
                _buildTableHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: standings.length,
                    itemBuilder: (context, index) {
                      return _buildTableStandingRow(context, standings[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text("#", style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 14),
          const SizedBox(
            width: 180,
            child: Text("TEAM", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          _buildHeaderColumn("Played", width: 60, isDark: isDark),
          _buildHeaderColumn("Won", width: 50, isDark: isDark),
          _buildHeaderColumn("Drawn", width: 50, isDark: isDark),
          _buildHeaderColumn("Lost", width: 50, isDark: isDark),
          _buildHeaderColumn("GD", width: 50, isDark: isDark),
          _buildHeaderColumn("Points", width: 60, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderColumn(String label, {double width = 32, required bool isDark}) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableStandingRow(BuildContext context, dynamic standing) {
    final team = standing['participant'] ?? {};
    final position = standing['position'] ?? '-';
    final points = standing['points'] ?? 0;
    final teamName = team['name'] ?? 'Unknown';
    final teamImg = team['image_path'] ?? '';

    final details = standing['details'] as List? ?? [];
    String mp = "0", w = "0", d = "0", l = "0", gd = "0", pts = standing['points']?.toString() ?? "0";

    for (var detail in details) {
      final typeId = detail['type_id']?.toString();
      final value = detail['value']?.toString() ?? '0';
      
      if (typeId == '129') {
        mp = value;
      } else if (typeId == '130') {
        w = value;
      } else if (typeId == '131') {
        d = value;
      } else if (typeId == '132') {
        l = value;
      } else if (typeId == '186') {
        gd = value;
      } else if (typeId == '187') {
        pts = value;
      }
    }

    if (mp == "0" && standing['overall'] != null) {
      final overall = standing['overall'];
      mp = overall['played']?.toString() ?? "0";
      w = overall['won']?.toString() ?? "0";
      d = overall['draw']?.toString() ?? "0";
      l = overall['lost']?.toString() ?? "0";
      gd = overall['goals_diff']?.toString() ?? "0";
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailsScreen(
              teamId: team['id'],
              teamName: teamName,
              teamLogo: teamImg,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                position.toString(),
                style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 180,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: teamImg.isNotEmpty
                      ? Image.network(teamImg, width: 22, height: 22, errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, size: 20))
                      : const Icon(Icons.shield_rounded, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      teamName,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatColumn(mp, width: 60),
            _buildStatColumn(w, width: 50),
            _buildStatColumn(d, width: 50),
            _buildStatColumn(l, width: 50),
            _buildStatColumn(gd, width: 50),
            SizedBox(
              width: 60,
              child: Center(
                child: Container(
                  width: 38,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    pts,
                    style: const TextStyle(color: Color(0xFFFF8700), fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, {double width = 32}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: width,
      child: Text(value, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11), textAlign: TextAlign.center),
    );
  }

  Widget _buildFixturesTabContent(Color accentColor) {
    return Consumer<FixtureProvider>(
      builder: (context, fixtureProvider, child) {
        if (fixtureProvider.isLoading && fixtureProvider.fixtures.isEmpty) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        if (fixtureProvider.fixtures.isEmpty) {
          return _buildPlaceholderTab("No Fixtures Found");
        }

        // Group fixtures by local date using timestamps
        Map<String, List<dynamic>> groupedFixtures = {};
        for (var fixture in fixtureProvider.fixtures) {
          final timestamp = fixture['starting_at_timestamp'];
          if (timestamp != null) {
            try {
              final localDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
              final dateKey = DateFormat('yyyy-MM-dd').format(localDate);

              if (!groupedFixtures.containsKey(dateKey)) {
                groupedFixtures[dateKey] = [];
              }
              groupedFixtures[dateKey]!.add(fixture);
            } catch (e) {
              debugPrint("Error parsing timestamp: $e");
            }
          }
        }

        final sortedDates = groupedFixtures.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final dateKey = sortedDates[index];
            final fixtures = groupedFixtures[dateKey]!;

            String displayDate = dateKey;
            try {
              final parsedLocal = DateTime.parse(dateKey);
              displayDate = DateFormat('EEEE, MMM d').format(parsedLocal);
            } catch (_) {}

            return _buildDateGroup(displayDate, fixtures, accentColor);
          },
        );
      },
    );
  }

  Widget _buildDateGroup(String date, List<dynamic> fixtures, Color accentColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: isDark ? Colors.white : Colors.black,
          collapsedIconColor: isDark ? Colors.white : Colors.black,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const Icon(Icons.calendar_month, color: Color(0xFF4CAF50)),
          title: Text(
            date,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          children: [
            const Divider(color: Colors.white10, height: 1),
            ...fixtures.map((f) => _buildFixtureItem(f, accentColor)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFixtureItem(dynamic fixture, Color accentColor) {
    final timestamp = fixture['starting_at_timestamp'];
    String time = "N/A";
    if (timestamp != null) {
      try {
        final localDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
        time = DateFormat('h:mm a').format(localDate);
      } catch (_) {}
    }

    final participants = fixture['participants'] as List? ?? [];
    dynamic home;
    dynamic away;

    if (participants.isNotEmpty) {
      home = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
      if (participants.length > 1) {
        away = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
      }
    }

    final hName = home?['name'] ?? 'Home';
    final aName = away?['name'] ?? 'Away';
    final hImg = home?['image_path'] ?? '';
    final aImg = away?['image_path'] ?? '';

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsScreen(fixture: fixture, leagueId: widget.leagueId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 65,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D44) : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                time,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 10, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _buildMiniTeamRow(hName, hImg),
                  const SizedBox(height: 8),
                  _buildMiniTeamRow(aName, aImg),
                ],
              ),
            ),
            const Icon(Icons.access_time_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTeamRow(String name, String img) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Row(
      children: [
        if (img.isNotEmpty)
          Image.network(img, width: 20, height: 20, errorBuilder: (_, __, ___) => Icon(Icons.shield, size: 20, color: isDark ? Colors.white24 : Colors.black26))
        else
          Icon(Icons.shield, size: 20, color: isDark ? Colors.white24 : Colors.black26),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildStatsTab(Color accentColor) {
    return Consumer<StatsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.stats.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8700)));
        }

        if (provider.errorMessage != null && provider.stats.isEmpty) {
          return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)));
        }

        if (provider.stats.isEmpty && provider.events.isEmpty) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Center(child: Text("No statistics available", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
        }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (provider.stats.isNotEmpty) ...[
              Text("Match Statistics", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ..._generateStatsRows(provider.stats),
              const SizedBox(height: 32),
            ],
            if (provider.events.isNotEmpty) ...[
              Text("Match Timeline", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ...provider.events.map((e) => _buildEventRow(e, accentColor)).toList(),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _generateStatsRows(List<dynamic> stats) {
    Map<String, List<dynamic>> groupedStats = {};
    for (var s in stats) {
      final typeName = s['type']?['name'] ?? 'Unknown';
      groupedStats.putIfAbsent(typeName, () => []).add(s);
    }

    return groupedStats.entries.map((entry) {
      final type = entry.key;
      final teamStats = entry.value;
      final participants = widget.fixture['participants'] as List? ?? [];
      final home = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
      final away = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
      
      final homeStat = teamStats.firstWhere((s) => s['participant_id'] == home['id'], orElse: () => null);
      final awayStat = teamStats.firstWhere((s) => s['participant_id'] == away['id'], orElse: () => null);

      final hValueStr = homeStat?['data']?['value']?.toString() ?? "0";
      final aValueStr = awayStat?['data']?['value']?.toString() ?? "0";
      
      double hVal = double.tryParse(hValueStr.replaceAll('%', '')) ?? 0;
      double aVal = double.tryParse(aValueStr.replaceAll('%', '')) ?? 0;
      double total = hVal + aVal;
      double hPercent = total == 0 ? 0.5 : hVal / total;

      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      final Color textColor = isDark ? Colors.white : Colors.black87;
      final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(hValueStr, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(type, style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                Text(aValueStr, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(height: 6, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200], borderRadius: BorderRadius.circular(3))),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 6,
                      width: constraints.maxWidth * hPercent,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF8700), Color(0xFFFFAB40)]), 
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [BoxShadow(color: const Color(0xFFFF8700).withOpacity(0.3), blurRadius: 4)],
                      ),
                    );
                  }
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildEventRow(dynamic event, Color accentColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black38;

    final type = event['type']?['name']?.toString().toLowerCase() ?? '';
    final minute = event['minute']?.toString() ?? '';
    final player = event['player']?['display_name'] ?? '';
    final teamId = event['participant_id'];

    final participants = widget.fixture['participants'] as List? ?? [];
    bool isHome = false;
    if (participants.isNotEmpty) {
      final home = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
      isHome = teamId == home['id'];
    }

    IconData icon;
    Color iconColor = Colors.white60;

    if (type.contains('goal')) {
      icon = Icons.sports_soccer;
      iconColor = const Color(0xFFFF8700);
    } else if (type.contains('yellow')) {
      icon = Icons.rectangle;
      iconColor = Colors.yellow;
    } else if (type.contains('red')) {
      icon = Icons.rectangle;
      iconColor = Colors.red;
    } else if (type.contains('substitution')) {
      icon = Icons.swap_vert;
      iconColor = Colors.orange;
    } else {
      icon = Icons.info_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (isHome) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(player, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(event['type']?['name'] ?? '', style: TextStyle(color: subTextColor, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ] else const Spacer(),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), shape: BoxShape.circle),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (minute.isNotEmpty) ...[
                  Text(minute, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  const Text("'", style: TextStyle(color: Colors.white60, fontSize: 10)),
                  const SizedBox(width: 4),
                ],
                Icon(icon, color: iconColor, size: 14),
              ],
            ),
          ),

          if (!isHome) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(event['type']?['name'] ?? '', style: TextStyle(color: subTextColor, fontSize: 10)),
                ],
              ),
            ),
          ] else const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLineupTab(Color accentColor) {
    return Consumer<LineupProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.lineups.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8700)));
        }

        if (provider.errorMessage != null && provider.lineups.isEmpty) {
          return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)));
        }

        if (provider.lineups.isEmpty) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Center(child: Text("Lineup not available yet", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
        }

        final participants = widget.fixture['participants'] as List? ?? [];
        int? homeId;
        int? awayId;
        String homeName = "Home";
        String awayName = "Away";
        if (participants.isNotEmpty) {
          final home = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
          homeId = home['id'];
          homeName = home['name'] ?? 'Home';
          if (participants.length > 1) {
            final away = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
            awayId = away['id'];
            awayName = away['name'] ?? 'Away';
          }
        }

        final homeXI = provider.lineups.where((l) => l['participant_id'] == homeId).toList();
        final awayXI = provider.lineups.where((l) => l['participant_id'] == awayId).toList();
        final homeBench = provider.bench.where((b) => b['participant_id'] == homeId).toList();
        final awayBench = provider.bench.where((b) => b['participant_id'] == awayId).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLineupSection("Starting XI", homeName, awayName, homeXI, awayXI, accentColor),
            const SizedBox(height: 32),
            _buildLineupSection("Substitutes", homeName, awayName, homeBench, awayBench, accentColor),
          ],
        );
      },
    );
  }

  Widget _buildLineupSection(String title, String homeName, String awayName, List<dynamic> homePlayers, List<dynamic> awayPlayers, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 16,
                decoration: BoxDecoration(color: const Color(0xFFFF8700), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: homePlayers.map((p) => _buildPlayerRow(p, true)).toList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: awayPlayers.map((p) => _buildPlayerRow(p, false)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(dynamic player, bool isHome) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black38;

    final playerName = player['player']?['display_name'] ?? 'Unknown';
    final number = player['jersey_number']?.toString() ?? '';
    final position = player['position']?['name'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isHome) ...[
            if (number.isNotEmpty)
              Text(number, style: const TextStyle(color: Color(0xFFFF8700), fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playerName, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(position, style: TextStyle(color: subTextColor, fontSize: 10)),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(playerName, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(position, style: TextStyle(color: subTextColor, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (number.isNotEmpty)
              Text(number, style: const TextStyle(color: Color(0xFFFF8700), fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Consumer<CommentaryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.comments.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8700)));
        }

        if (provider.errorMessage != null && provider.comments.isEmpty) {
          return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)));
        }

        if (provider.comments.isEmpty) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Center(child: Text("No commentary available", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.comments.length,
          itemBuilder: (context, index) {
            final comment = provider.comments[index];
            final minute = comment['minute']?.toString() ?? '';
            final text = comment['comment'] ?? '';
            final isImportant = comment['important'] == true;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isImportant ? Border.all(color: const Color(0xFFFF8700).withOpacity(0.5)) : Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12),
                boxShadow: isImportant ? [BoxShadow(color: const Color(0xFFFF8700).withOpacity(0.1), blurRadius: 10)] : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isImportant ? const Color(0xFFFF8700) : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$minute'", 
                      style: TextStyle(color: isImportant ? Colors.black : (isDark ? Colors.white54 : Colors.black54), fontSize: 11, fontWeight: FontWeight.bold), 
                      textAlign: TextAlign.center
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isImportant)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFF8700), size: 14),
                                const SizedBox(width: 4),
                                Text("KEY EVENT", style: TextStyle(color: const Color(0xFFFF8700), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        Text(
                          text,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Text("$title tab implementation coming soon", style: const TextStyle(color: Colors.white38)),
    );
  }
}

