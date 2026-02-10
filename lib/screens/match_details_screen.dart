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
    const Color accentColor = Color(0xFFD4FF00);
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

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(200),
            child: Column(
              children: [
                // Team Logos and Score/Time
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Home Team
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeamDetailsScreen(
                                  teamId: homeTeam?['id'] ?? 0,
                                  teamName: homeName,
                                  teamLogo: homeImg,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              _buildTeamLogo(homeImg),
                              const SizedBox(height: 12),
                              Text(
                                homeName,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Match Info Center
                      Column(
                        children: [
                          if (isUpcoming) ...[
                            Text(
                              matchTime,
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              matchDate,
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ] else ...[
                            Text(
                              "$homeScoreStr - $awayScoreStr",
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLive)
                                  Container(
                                    width: 8, height: 8,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  ),
                                Text(
                                  isLive ? "LIVE - $stateName" : stateName,
                                  style: TextStyle(
                                    color: isLive ? Colors.red : Colors.white38,
                                    fontSize: 12,
                                    fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      // Away Team
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeamDetailsScreen(
                                  teamId: awayTeam?['id'] ?? 0,
                                  teamName: awayName,
                                  teamLogo: awayImg,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              _buildTeamLogo(awayImg),
                              const SizedBox(height: 12),
                              Text(
                                awayName,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // TabBar
                TabBar(
                  isScrollable: true,
                  indicatorColor: accentColor,
                  labelColor: accentColor,
                  unselectedLabelColor: Colors.white38,
                  indicatorWeight: 3,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                  tabs: const [
                    Tab(text: "Info"),
                    Tab(text: "H 2 H"),
                    Tab(text: "Stats"),
                    Tab(text: "Lineup"),
                    Tab(text: "Table"),
                    Tab(text: "Comments"),
                  ],
                ),
              ],
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

  Widget _buildTeamLogo(String img) {
    return Container(
      width: 70,
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: img.isNotEmpty
          ? Image.network(img, fit: BoxFit.contain)
          : const Icon(Icons.shield, size: 40, color: Colors.white10),
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
                  const Text("Who will win?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(percent, style: const TextStyle(color: Color(0xFFD4FF00), fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildExpansionCard({required IconData icon, required String title, required Widget content, bool initiallyExpanded = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: const Color(0xFF4CAF50)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
        children: [content],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool showMap = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF26BC94)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showMap) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on, color: Color(0xFF00C853), size: 16),
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
        if (h2h.isLoading) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        if (h2h.h2hMatches.isEmpty) {
          return const Center(child: Text("No Head-to-Head data available", style: TextStyle(color: Colors.white38)));
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
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
    bool isSelected = _h2hView == title;
    return InkWell(
      onTap: () => setState(() => _h2hView = title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D2D44) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD4FF00) : Colors.white38,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildH2HSummary(List<dynamic> allMatches) {
    final participants = widget.fixture['participants'] as List? ?? [];
    if (participants.length < 2) return const SizedBox();
    
    // Select matches based on view
    List<dynamic> matches = _h2hView == "Last 5" 
      ? allMatches.take(5).toList() 
      : allMatches;

    final home = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
    final away = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
    final homeId = home['id'];
    final awayId = away['id'];
    
    int homeWins = 0;
    int awayWins = 0;
    int draws = 0;

    for (var match in matches) {
      final scores = match['scores'] as List? ?? [];
      if (scores.isEmpty) continue;

      // Find FT or CURRENT score for home team
      final hScoreObj = scores.firstWhere(
        (s) => s['participant_id'] == homeId && 
               (s['description']?.toString().toUpperCase() == 'FT' || 
                s['description']?.toString().toUpperCase() == 'CURRENT'), 
        orElse: () => null
      );
      // Find FT or CURRENT score for away team
      final aScoreObj = scores.firstWhere(
        (s) => s['participant_id'] == awayId && 
               (s['description']?.toString().toUpperCase() == 'FT' || 
                s['description']?.toString().toUpperCase() == 'CURRENT'), 
        orElse: () => null
      );
      
      if (hScoreObj != null && aScoreObj != null) {
        int h = hScoreObj['score']?['goals'] ?? 0;
        int a = aScoreObj['score']?['goals'] ?? 0;
        if (h > a) homeWins++;
        else if (a > h) awayWins++;
        else draws++;
      } else if (scores.length >= 2) {
        // Fallback: Just take the goals from any score object for this participant if FT/CURRENT missing
        final hFallback = scores.firstWhere((s) => s['participant_id'] == homeId, orElse: () => null);
        final aFallback = scores.firstWhere((s) => s['participant_id'] == awayId, orElse: () => null);
        if (hFallback != null && aFallback != null) {
           int h = hFallback['score']?['goals'] ?? 0;
           int a = aFallback['score']?['goals'] ?? 0;
           if (h > a) homeWins++;
           else if (a > h) awayWins++;
           else draws++;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text("Head to Head Summary", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat(homeWins.toString(), "Wins", participants[0]['name']),
              _buildSummaryStat(draws.toString(), "Draws", "Draw"),
              _buildSummaryStat(awayWins.toString(), "Wins", participants[1]['name']),
            ],
          ),
          const SizedBox(height: 20),
          // Simple Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: matches.isEmpty ? 0 : homeWins / matches.length,
              backgroundColor: Colors.red.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4FF00)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String value, String label, String teamName) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(teamName, style: const TextStyle(color: Colors.white60, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
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

    String hScore = "0";
    String aScore = "0";
    final hScoreObj = scores.firstWhere(
      (s) => s['participant_id'] == home?['id'] && 
             (s['description']?.toString().toUpperCase() == 'FT' || 
              s['description']?.toString().toUpperCase() == 'CURRENT'), 
      orElse: () => null
    );
    final aScoreObj = scores.firstWhere(
      (s) => s['participant_id'] == away?['id'] && 
             (s['description']?.toString().toUpperCase() == 'FT' || 
              s['description']?.toString().toUpperCase() == 'CURRENT'), 
      orElse: () => null
    );
    
    if (hScoreObj != null) {
      hScore = hScoreObj['score']?['goals']?.toString() ?? "0";
    } else {
      final hFallback = scores.firstWhere((s) => s['participant_id'] == home?['id'], orElse: () => null);
      if (hFallback != null) hScore = hFallback['score']?['goals']?.toString() ?? "0";
    }

    if (aScoreObj != null) {
      aScore = aScoreObj['score']?['goals']?.toString() ?? "0";
    } else {
      final aFallback = scores.firstWhere((s) => s['participant_id'] == away?['id'], orElse: () => null);
      if (aFallback != null) aScore = aFallback['score']?['goals']?.toString() ?? "0";
    }

    final timestamp = match['starting_at_timestamp'];
    String date = "N/A";
    if (timestamp != null) {
      date = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(date, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const Expanded(child: SizedBox()),
          SizedBox(
            width: 80,
            child: Text(home?['name'] ?? 'Home', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
            child: Text("$hScore - $aScore", style: const TextStyle(color: Color(0xFFD4FF00), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(away?['name'] ?? 'Away', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.left, overflow: TextOverflow.ellipsis),
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
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
          }
          return const Center(child: Text("No table data", style: TextStyle(color: Colors.white38)));
        }
        return Column(
          children: [
            if (leagueProvider.liveStandings.isNotEmpty)
              Padding(
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
              ),
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
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const Expanded(child: SizedBox()),
          _buildHeaderColumn("PL"),
          _buildHeaderColumn("GD"),
          _buildHeaderColumn("PTS"),
        ],
      ),
    );
  }

  Widget _buildHeaderColumn(String label) {
    return SizedBox(
      width: 35,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
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
    String mp = "0", gd = "0";

    for (var detail in details) {
      final type = detail['type']?['name']?.toString().toLowerCase() ?? '';
      final value = detail['value']?.toString() ?? '0';
      if (type.contains('played')) mp = value;
      else if (type.contains('goals-difference')) gd = value;
    }

    if (mp == "0" && standing['overall'] != null) {
      final overall = standing['overall'];
      mp = overall['played']?.toString() ?? "0";
      gd = overall['goals_diff']?.toString() ?? "0";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            child: Text(position.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          // TEAM LOGO & NAME (Clickable)
          Expanded(
            child: InkWell(
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
              child: Row(
                children: [
                  if (teamImg.isNotEmpty)
                    Image.network(teamImg, width: 24, height: 24)
                  else
                    const Icon(Icons.shield, size: 24, color: Colors.white24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      teamName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildStatColumn(mp),
          _buildStatColumn(gd),
          Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: Colors.white24), shape: BoxShape.circle),
            child: Text(points.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value) {
    return SizedBox(
      width: 35,
      child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const Icon(Icons.calendar_month, color: Color(0xFF4CAF50)),
          title: Text(
            date,
            style: const TextStyle(
              color: Colors.white,
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
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 65,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D44),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                time,
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
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
            const Icon(Icons.notifications_none, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTeamRow(String name, String img) {
    return Row(
      children: [
        if (img.isNotEmpty)
          Image.network(img, width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 20, color: Colors.white24))
        else
          const Icon(Icons.shield, size: 20, color: Colors.white24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildStatsTab(Color accentColor) {
    return Consumer<StatsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.stats.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
        }

        if (provider.errorMessage != null && provider.stats.isEmpty) {
          return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)));
        }

        if (provider.stats.isEmpty && provider.events.isEmpty) {
          return const Center(child: Text("No statistics available", style: TextStyle(color: Colors.white38)));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (provider.stats.isNotEmpty) ...[
              const Text("Match Statistics", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ..._generateStatsRows(provider.stats),
              const SizedBox(height: 32),
            ],
            if (provider.events.isNotEmpty) ...[
              const Text("Match Timeline", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      int? homeId;
      int? awayId;
      if (participants.isNotEmpty) {
        final home = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
        homeId = home['id'];
        if (participants.length > 1) {
          final away = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
          awayId = away['id'];
        }
      }

      final homeStat = teamStats.firstWhere((s) => s['participant_id'] == homeId, orElse: () => null);
      final awayStat = teamStats.firstWhere((s) => s['participant_id'] == awayId, orElse: () => null);

      final hValueStr = homeStat?['data']?['value']?.toString() ?? "0";
      final aValueStr = awayStat?['data']?['value']?.toString() ?? "0";
      
      double hVal = double.tryParse(hValueStr.replaceAll('%', '')) ?? 0;
      double aVal = double.tryParse(aValueStr.replaceAll('%', '')) ?? 0;
      double total = hVal + aVal;
      double hPercent = total == 0 ? 0.5 : hVal / total;

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(hValueStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(type, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                Text(aValueStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
                FractionallySizedBox(
                  widthFactor: hPercent,
                  child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFD4FF00), borderRadius: BorderRadius.circular(2))),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildEventRow(dynamic event, Color accentColor) {
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
      iconColor = const Color(0xFFD4FF00);
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
                  Text(player, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(event['type']?['name'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ] else const Spacer(),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
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
                  Text(player, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(event['type']?['name'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
        }

        if (provider.errorMessage != null && provider.lineups.isEmpty) {
          return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)));
        }

        if (provider.lineups.isEmpty) {
          return const Center(child: Text("Lineup not available yet", style: TextStyle(color: Colors.white38)));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: homePlayers.map((p) => _buildPlayerRow(p, true)).toList(),
              ),
            ),
            Container(width: 1, height: 400, color: Colors.white10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: awayPlayers.map((p) => _buildPlayerRow(p, false)).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerRow(dynamic player, bool isHome) {
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
              Text(number, style: const TextStyle(color: Color(0xFFD4FF00), fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playerName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(position, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(playerName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(position, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (number.isNotEmpty)
              Text(number, style: const TextStyle(color: Color(0xFFD4FF00), fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Consumer<CommentaryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.comments.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
        }

        if (provider.errorMessage != null && provider.comments.isEmpty) {
          return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)));
        }

        if (provider.comments.isEmpty) {
          return const Center(child: Text("No commentary available", style: TextStyle(color: Colors.white38)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.comments.length,
          itemBuilder: (context, index) {
            final comment = provider.comments[index];
            final minute = comment['minute']?.toString() ?? '';
            final text = comment['comment'] ?? '';
            final isImportant = comment['important'] == true;

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 35,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isImportant ? const Color(0xFFD4FF00) : Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "$minute'", 
                      style: TextStyle(color: isImportant ? Colors.black : Colors.white60, fontSize: 10, fontWeight: FontWeight.bold), 
                      textAlign: TextAlign.center
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: isImportant ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
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

