import 'package:flutter/material.dart';
import 'package:football_app/providers/fixture_provider.dart';
import 'package:football_app/providers/league_provider.dart';
import 'package:football_app/providers/h2h_provider.dart';
import 'package:football_app/providers/stats_provider.dart';
import 'package:football_app/providers/prediction_provider.dart';
import 'package:football_app/providers/commentary_provider.dart';
import 'package:football_app/screens/team_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:football_app/l10n/app_localizations.dart';

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
        context.read<PredictionProvider>().fetchPredictionDetails(fixtureId);
        // Fetch Live Standings for the league
        context.read<LeagueProvider>().fetchLiveStandings(widget.leagueId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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

    final homeName = homeTeam?['name'] ?? l10n.home;
    final awayName = awayTeam?['name'] ?? l10n.away;
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
    final Color backgroundColor = isDark ? Colors.black : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF121212) : Colors.white;
    
    return DefaultTabController(
      length: 5,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
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
                  color: backgroundColor,
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
                                        isLive ? "${l10n.liveLabel} - $stateName" : stateName,
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
                                      "${l10n.ht}: $htScoreStr",
                                      style: TextStyle(color: subTextColor, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                          
                          // Away Team
                          Expanded(child: _buildHeaderTeam(awayName, awayImg, awayTeam?['id'] ?? 0, false, isDark, textColor)),
                          SizedBox(height: 5,)
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // TabBar
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: accentColor,
                      labelColor: accentColor,
                      unselectedLabelColor: subTextColor,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: [
                        Tab(text: l10n.infoTab),
                        Tab(text: l10n.h2hTab),
                        Tab(text: l10n.statsTab),
                        Tab(text: l10n.tableTab),
                        Tab(text: l10n.commentsTab),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildInfoTab(widget.fixture, htScoreStr),
              _buildH2HTab(accentColor),
              _buildStatsTab(accentColor),
              _buildTableTab(context),
              _buildCommentsTab(),
            ],
          ),
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
    final l10n = AppLocalizations.of(context)!;
    final venueNameRaw = fixture['venue']?['name']?.toString() ?? '';
    final cityNameRaw = fixture['venue']?['city']?.toString() ?? '';
    
    String venueDisplay = "N/A";
    if (venueNameRaw.isNotEmpty && !venueNameRaw.toLowerCase().contains('unknown')) {
      venueDisplay = venueNameRaw;
      if (cityNameRaw.isNotEmpty && !cityNameRaw.toLowerCase().contains('unknown') && cityNameRaw != venueNameRaw) {
        venueDisplay += ", $cityNameRaw";
      }
    } else if (cityNameRaw.isNotEmpty && !cityNameRaw.toLowerCase().contains('unknown')) {
      venueDisplay = cityNameRaw;
    }

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
    final Color accentColor = const Color(0xFFFF8700);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: General Information
          _buildExpansionCard(
            icon: Icons.info_outline,
            title: l10n.matchInformation,
            initiallyExpanded: true,
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildInfoRow(Icons.emoji_events_outlined, l10n.competition, leagueName),
                  _buildInfoRow(Icons.notifications_none_rounded, l10n.kickOff, formattedKickOff),
                  if (htScore.isNotEmpty)
                    _buildInfoRow(Icons.notifications_active, l10n.halfTimeResult, htScore),
                  _buildInfoRow(Icons.location_on_outlined, l10n.venue, venueDisplay, showMap: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Prediction Section
          Consumer<PredictionProvider>(
            builder: (context, predProvider, child) {
              final WinProbabilities = predProvider.getWinProbabilities();
              final bool hasPredictions = WinProbabilities.values.any((v) => v != "0%");
              
              return _buildExpansionCard(
                icon: Icons.analytics_outlined,
                title: l10n.predictions,
                initiallyExpanded: true,
                content: predProvider.isLoading 
                  ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: Colors.redAccent)))
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: !hasPredictions 
                        ? Center(child: Text(l10n.noPredictionsAvailable, style: TextStyle(color: subTextColor, fontSize: 13)))
                        : Column(
                            children: [
                              Text(l10n.winProbability, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildPollButton(l10n.home, WinProbabilities['home']!),
                                  _buildPollButton(l10n.draw, WinProbabilities['draw']!),
                                  _buildPollButton(l10n.away, WinProbabilities['away']!),
                                ],
                              ),
                            ],
                          ),
                    ),
              );
            },
          ),
          const SizedBox(height: 5),
          // Timeline Section
          Consumer<StatsProvider>(
            builder: (context, statsProvider, child) {
              final participants = fixture['participants'] as List? ?? [];
              final homeTeam = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants.isNotEmpty ? participants[0] : null);
              final homeId = homeTeam?['id'] ?? 0;
              
              return _buildTimelineSection(statsProvider, homeId);
            },
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(StatsProvider statsProvider, int homeId) {
    final l10n = AppLocalizations.of(context)!;
    if (statsProvider.isLoading && statsProvider.events.isEmpty) {
      return const SizedBox();
    }

    if (statsProvider.events.isEmpty) {
      return const SizedBox();
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black38;

    // Split events into 1st Half, HT, and 2nd Half (and ET)
    List<dynamic> firstHalf = [];
    List<dynamic> secondHalf = [];
    
    for (var event in statsProvider.events) {
      final minute = event['minute'] ?? 0;
      if (minute <= 45) {
        firstHalf.add(event);
      } else {
        secondHalf.add(event);
      }
    }

    return _buildExpansionCard(
      icon: Icons.timeline_rounded,
      title: AppLocalizations.of(context)!.matchTimeline,
      initiallyExpanded: true,
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            ...firstHalf.map((e) => _buildTimelineEventItem(e, homeId)),
            
            // HT Separator
            if (firstHalf.isNotEmpty || secondHalf.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    const Expanded(child: Divider(indent: 20, endIndent: 10)),
                    Text(l10n.ht, style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    const Expanded(child: Divider(indent: 10, endIndent: 20)),
                  ],
                ),
              ),
              
            ...secondHalf.map((e) => _buildTimelineEventItem(e, homeId)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineEventItem(dynamic event, int homeId) {
    final participantId = event['participant_id'];
    final bool isHome = participantId == homeId;
    final minute = event['minute'];
    final extraMinute = event['extra_minute'];
    final player = event['player']?['display_name'] ?? event['player']?['name'] ?? 'Player';
    final type = event['type']?['name']?.toString().toLowerCase() ?? '';
    final typeId = event['type_id'];
    
    // Map event type to icon and color
    IconData iconData = Icons.info_outline;
    Color iconColor = Colors.grey;
    String eventLabel = type;

    final l10n = AppLocalizations.of(context)!;
    if (type.contains('goal')) {
      iconData = Icons.sports_soccer;
      iconColor = Colors.green;
      eventLabel = l10n.goal;
      if (type.contains('own')) eventLabel = l10n.ownGoal;
      if (type.contains('penalty')) eventLabel = l10n.penaltyGoal;
    } else if (type.contains('yellow') || typeId == 18) {
      iconData = Icons.rectangle;
      iconColor = Colors.yellow[700]!;
      eventLabel = l10n.yellowCard;
    } else if (type.contains('red') || typeId == 19) {
      iconData = Icons.rectangle;
      iconColor = Colors.red;
      eventLabel = l10n.redCard;
    } else if (type.contains('substitution') || typeId == 20) {
      iconData = Icons.swap_vert_rounded;
      iconColor = Colors.orange;
      eventLabel = l10n.substitution;
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black38;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isHome) ...[
            // Minute
            SizedBox(
              width: 40,
              child: Text(
                "$minute'${extraMinute != null ? '+$extraMinute' : ''}",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 12),
            // Icon
            Icon(iconData, color: iconColor, size: 20),
            const SizedBox(width: 16),
            // Player and Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(player, style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(eventLabel, style: TextStyle(color: subTextColor, fontSize: 12)),
                ],
              ),
            ),
          ] else ...[
            // Player and Label (Away)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(player, style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(eventLabel, style: TextStyle(color: subTextColor, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Icon
            Icon(iconData, color: iconColor, size: 20),
            const SizedBox(width: 12),
            // Minute
            SizedBox(
              width: 40,
              child: Text(
                "$minute'${extraMinute != null ? '+$extraMinute' : ''}",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPressureIndexSection(StatsProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    if (provider.isLoading && provider.pressureData.isEmpty) return const SizedBox();
    if (provider.pressureData.isEmpty) return const SizedBox();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black38;

    final participants = widget.fixture['participants'] as List? ?? [];
    if (participants.length < 2) return const SizedBox();

    final home = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
    final away = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);

    final homeId = home['id'];
    final awayId = away['id'];

    List<FlSpot> homeSpots = [];
    List<FlSpot> awaySpots = [];

    for (var point in provider.pressureData) {
      if (point is! Map) continue;
      final minute = (point['minute'] as num?)?.toDouble() ?? 0.0;
      
      // Only show from minute 60 onwards
      if (minute < 60) continue;

      final participantId = point['participant_id'];
      final dynamic rawPressure = point['pressure'];
      
      double pVal = 0.0;
      if (rawPressure is num) {
        pVal = rawPressure.toDouble();
      } else if (rawPressure is Map) {
        // Handle alternative Map format if it exists
        pVal = (rawPressure[participantId.toString()] as num?)?.toDouble() ?? 
               (rawPressure[homeId.toString()] as num?)?.toDouble() ?? 
               (rawPressure[awayId.toString()] as num?)?.toDouble() ?? 0.0;
      }

      if (participantId == homeId) {
        homeSpots.add(FlSpot(minute, pVal));
      } else if (participantId == awayId) {
        awaySpots.add(FlSpot(minute, pVal));
      }
    }

    // Sort spots by minute for fl_chart
    homeSpots.sort((a, b) => a.x.compareTo(b.x));
    awaySpots.sort((a, b) => a.x.compareTo(b.x));

    return _buildExpansionCard(
      icon: Icons.show_chart_rounded,
      title: AppLocalizations.of(context)!.pressureIndex,
      initiallyExpanded: true,
      content: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
        child: Column(
          children: [
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _buildLegendItem(away['name'] ?? l10n.away, Colors.red)),
                const SizedBox(width: 16),
                Expanded(child: _buildLegendItem(home['name'] ?? l10n.home, const Color(0xFFFF8700))),
              ],
            ),
            const SizedBox(height: 32),
            // Chart
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          if (value % 10 != 0) return const SizedBox();
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(color: subTextColor, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value % 15 != 0 || value == 0) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(color: subTextColor, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: subTextColor.withOpacity(0.2)),
                      bottom: BorderSide(color: subTextColor.withOpacity(0.2)),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: awaySpots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: homeSpots,
                      isCurved: true,
                      color: const Color(0xFFFF8700),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: const LineTouchData(enabled: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.time, style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(width: 12, height: 2, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
    final Color primaryColor = isDark ? Colors.black : Colors.white;
    const Color accentColor = Color(0xFFFF8700);
    final Color cardColor = isDark ? const Color(0xFF121212) : Colors.white;
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon, 
                size: (icon == Icons.notifications_none_rounded || icon == Icons.notifications_active) ? 28 : 20, 
                color: (icon == Icons.notifications_none_rounded || icon == Icons.notifications_active) ? const Color(0xFF48C9B0) : const Color(0xFFFF8700).withOpacity(0.7)
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              value,
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
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
          return Center(child: Text(AppLocalizations.of(context)!.noFixturesFound, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
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
          Expanded(child: _buildToggleItem(AppLocalizations.of(context)!.home)),
          Expanded(child: _buildToggleItem(AppLocalizations.of(context)!.away)),
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
    final l10n = AppLocalizations.of(context)!;
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
        color: isDark ? const Color(0xFF121212) : Colors.white,
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
              _buildSummaryStat(homeWins.toString(), "WINS", home['name'] ?? l10n.home),
              _buildSummaryStat(draws.toString(), "DRAWS", l10n.draw),
              _buildSummaryStat(awayWins.toString(), "WINS", away['name'] ?? l10n.away),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Home Wins
              Expanded(
                flex: homeWins == 0 && draws == 0 && awayWins == 0 ? 1 : homeWins,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF8700), Color(0xFFFFAB40)]),
                    borderRadius: BorderRadius.horizontal(
                      left: const Radius.circular(5),
                      right: Radius.circular(draws == 0 && awayWins == 0 ? 5 : 0),
                    ),
                    boxShadow: [BoxShadow(color: const Color(0xFFFF8700).withOpacity(0.3), blurRadius: 4)],
                  ),
                ),
              ),
              // Draws
              Expanded(
                flex: homeWins == 0 && draws == 0 && awayWins == 0 ? 1 : draws,
                child: Container(
                  height: 10,
                  color: isDark ? Colors.white24 : Colors.grey[300],
                ),
              ),
              // Away Wins
              Expanded(
                flex: homeWins == 0 && draws == 0 && awayWins == 0 ? 1 : awayWins,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF4DB6AC)]),
                    borderRadius: BorderRadius.horizontal(
                      right: const Radius.circular(5),
                      left: Radius.circular(homeWins == 0 && draws == 0 ? 5 : 0),
                    ),
                    boxShadow: [BoxShadow(color: const Color(0xFF26A69A).withOpacity(0.3), blurRadius: 4)],
                  ),
                ),
              ),
            ],
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
        color: isDark ? const Color(0xFF121212) : Colors.grey[100],
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
          return Center(child: Text(AppLocalizations.of(context)!.na, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 750,
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
          SizedBox(
            width: 180,
            child: Text(AppLocalizations.of(context)!.team.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          _buildHeaderColumn(AppLocalizations.of(context)!.played, width: 80, isDark: isDark),
          _buildHeaderColumn(AppLocalizations.of(context)!.win, width: 60, isDark: isDark),
          _buildHeaderColumn(AppLocalizations.of(context)!.drawShort, width: 60, isDark: isDark),
          _buildHeaderColumn(AppLocalizations.of(context)!.loss, width: 60, isDark: isDark),
          _buildHeaderColumn(AppLocalizations.of(context)!.gd, width: 140, isDark: isDark),
          _buildHeaderColumn(AppLocalizations.of(context)!.points, width: 80, isDark: isDark),
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
            _buildStatColumn(mp, width: 80),
            _buildStatColumn(w, width: 60),
            _buildStatColumn(d, width: 60),
            _buildStatColumn(l, width: 60),
            _buildStatColumn(gd, width: 140),
            SizedBox(
              width: 80,
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


  Widget _buildDateGroup(String date, List<dynamic> fixtures, Color accentColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.grey[200],
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

    final hName = home?['name'] ?? AppLocalizations.of(context)!.home;
    final aName = away?['name'] ?? AppLocalizations.of(context)!.away;
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
                color: isDark ? const Color(0xFF121212) : Colors.grey[300],
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
            Icon(Icons.notifications_active, color: isDark ? Colors.white60 : Colors.black54, size: 28),
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
          return Center(child: Text(AppLocalizations.of(context)!.na, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
        }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pressure Index Chart
            _buildPressureIndexSection(provider),
            const SizedBox(height: 24),

            if (provider.stats.isNotEmpty) ...[
              Text(AppLocalizations.of(context)!.matchInformation, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ..._generateStatsRows(provider.stats),
              const SizedBox(height: 32),
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
            Row(
              children: [
                Expanded(
                  flex: (hVal * 100).toInt() == 0 && (aVal * 100).toInt() == 0 ? 1 : (hVal * 100).toInt(),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF8700), Color(0xFFFFAB40)]), 
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(3),
                        right: Radius.circular(total == 0 || aVal == 0 ? 3 : 0),
                      ),
                      boxShadow: [BoxShadow(color: const Color(0xFFFF8700).withOpacity(0.3), blurRadius: 4)],
                    ),
                  ),
                ),
                Expanded(
                  flex: (hVal * 100).toInt() == 0 && (aVal * 100).toInt() == 0 ? 1 : (aVal * 100).toInt(),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF4DB6AC)]), 
                      borderRadius: BorderRadius.horizontal(
                        right: const Radius.circular(3),
                        left: Radius.circular(total == 0 || hVal == 0 ? 3 : 0),
                      ),
                      boxShadow: [BoxShadow(color: const Color(0xFF26A69A).withOpacity(0.3), blurRadius: 4)],
                    ),
                  ),
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
    return Consumer<PredictionProvider>(
      builder: (context, provider, child) {
        final comments = provider.predictionData?['comments'] as List? ?? [];
        
        if (provider.isLoading && comments.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8700)));
        }

        if (provider.errorMessage != null && comments.isEmpty) {
          return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)));
        }

        if (comments.isEmpty) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Center(child: Text("No commentary available", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
        }

        // Sort by minute (descending, latest first)
        final sortedComments = List.from(comments)..sort((a, b) {
          final minA = a['minute'] ?? 0;
          final minB = b['minute'] ?? 0;
          return minB.compareTo(minA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedComments.length,
          itemBuilder: (context, index) {
            final comment = sortedComments[index];
            final minute = comment['minute']?.toString() ?? '';
            final text = comment['comment'] ?? '';
            final isImportant = comment['important'] == true;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
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

