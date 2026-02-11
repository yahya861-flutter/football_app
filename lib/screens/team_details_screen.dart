
import 'package:flutter/material.dart';
import 'package:football_app/providers/squad_provider.dart';
import 'package:football_app/providers/team_provider.dart';
import 'package:football_app/screens/player_details_screen.dart';
import 'package:football_app/screens/match_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/follow_provider.dart';

class TeamDetailsScreen extends StatefulWidget {
  final int teamId;
  final String teamName;
  final String teamLogo;

  const TeamDetailsScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
  });

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  int? _selectedSeasonId;
  String? _selectedSeasonName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final teamProvider = context.read<TeamProvider>();
      await teamProvider.fetchTeamDetails(widget.teamId);
      final seasons = teamProvider.selectedTeam?['seasons'] as List? ?? [];
      
      if (seasons.isNotEmpty) {
        // Find most recent season (last in list usually)
        final mostRecent = seasons.last;
        setState(() {
          _selectedSeasonId = mostRecent['id'];
          _selectedSeasonName = mostRecent['name'];
        });
        teamProvider.fetchTeamStats(widget.teamId, _selectedSeasonId!.toString());
      }
      
      teamProvider.fetchTeamFixtures(widget.teamId);
      context.read<SquadProvider>().fetchSquad(widget.teamId);
    });
  }


  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFF8700);
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white60 : Colors.black54;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Theme.of(context).scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF1E1E2C) : Theme.of(context).primaryColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Consumer<FollowProvider>(
                    builder: (context, followProvider, child) {
                      final isFollowed = followProvider.isTeamFollowed(widget.teamId);
                      return IconButton(
                        icon: Icon(
                          isFollowed ? Icons.star : Icons.star_border, 
                          color: isFollowed ? accentColor : subTextColor,
                        ),
                        onPressed: () => followProvider.toggleFollowTeam(widget.teamId, teamData: context.read<TeamProvider>().selectedTeam),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 80, bottom: 48),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2D2D44).withOpacity(0.5) : Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                          ),
                          child: widget.teamLogo.isNotEmpty
                              ? Image.network(widget.teamLogo, fit: BoxFit.contain)
                              : Icon(Icons.shield, size: 40, color: subTextColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.teamName,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Selector<TeamProvider, String>(
                                selector: (_, p) => p.selectedTeam?['country']?['name'] ?? 'Loading...',
                                builder: (_, country, __) => Text(
                                  country,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      isScrollable: true,
                      indicatorColor: accentColor,
                      labelColor: isDark ? accentColor : textColor,
                      unselectedLabelColor: subTextColor,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                      tabs: const [
                        Tab(text: "Stats"),
                        Tab(text: "Fixtures"),
                        Tab(text: "Squad"),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              Consumer<TeamProvider>(
                builder: (context, provider, _) {
                  final seasons = provider.selectedTeam?['seasons'] as List? ?? [];
                  return _buildStatsTab(provider, seasons, accentColor);
                },
              ),
              Consumer<TeamProvider>(
                builder: (context, provider, _) => _buildFixturesTab(provider, accentColor),
              ),
              Consumer<SquadProvider>(
                builder: (context, provider, _) => _buildSquadTab(provider, accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab(TeamProvider provider, List seasons, Color accentColor) {
    final statsEntries = provider.teamStats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Competition/Season Selector (Teal style from reference)
          if (seasons.isNotEmpty)
            InkWell(
              onTap: () => _showCompetitionSelector(context, seasons, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF26BC94),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedSeasonName ?? "Select Competition",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFFF8700)))
          else if (statsEntries.isEmpty)
            _buildEmptyStats()
          else
            ..._buildStatsContent(statsEntries, accentColor),
            
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyStats() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Opacity(
            opacity: 0.3,
            child: Image.network(
              "https://cdni.iconscout.com/illustration/premium/thumb/no-data-found-8867280-7265556.png",
              height: 200,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.bar_chart, size: 100, color: Colors.white10),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Stats not found for this season",
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatsContent(List<dynamic> statsEntries, Color accentColor) {
    if (statsEntries.isEmpty) return [ _buildEmptyStats() ];

    // Group stats by league/season
    return statsEntries.map((entry) {
      final season = entry['season'] ?? {};
      final league = season['league'] ?? {};
      final leagueName = league['name'] ?? 'Competition';
      final seasonName = season['name'] ?? '';
      
      // Combined title like "Premier League 2023/2024"
      final fullTitle = seasonName.isNotEmpty && !leagueName.contains(seasonName)
          ? "$leagueName $seasonName"
          : leagueName;
          
      final details = entry['details'] as List? ?? [];
      
      if (details.isEmpty) return const SizedBox.shrink();

      return _buildStatCategory(fullTitle, details, accentColor);
    }).toList();
  }

  Widget _buildStatCategory(String title, List<dynamic> details, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: isDark ? Colors.white : Colors.black,
          collapsedIconColor: isDark ? Colors.white : Colors.black,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const Icon(Icons.bar_chart, color: Color(0xFF26BC94), size: 24),
          title: Text(
            title,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          children: [
            const Divider(color: Colors.white10, height: 1),
            ...details.map((d) {
              String name = d['type']?['name'] ?? 'Stat';
              if (name.contains('Count')) name = name.replaceAll('Count', '').trim();
              
              dynamic rawValue = d['value'];
              String displayValue = "0";

              if (rawValue is Map) {
                displayValue = (rawValue['count'] ?? rawValue['average'] ?? rawValue['total'] ?? rawValue['all']?['count'] ?? '0').toString();
              } else {
                displayValue = rawValue?.toString() ?? "0";
              }
              
              return _buildStatRow(name, displayValue);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label, 
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value, 
            style: TextStyle(color: textColor, fontWeight: FontWeight.w400, fontSize: 16),
          ),
        ],
      ),
    );
  }


  void _showCompetitionSelector(BuildContext context, List seasons, TeamProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // Reverse to show newest first
        final reversedSeasons = seasons.reversed.toList();
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text("Select Competition", style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: reversedSeasons.length,
                  itemBuilder: (context, index) {
                    final season = reversedSeasons[index];
                    final name = season['name'] ?? 'Competition';
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: _selectedSeasonId == season['id'] ? const Color(0xFF26BC94) : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: _selectedSeasonId == season['id'] ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedSeasonId = season['id'];
                          _selectedSeasonName = name;
                        });
                        provider.fetchTeamStats(widget.teamId, season['id'].toString());
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFixturesTab(TeamProvider provider, Color accentColor) {
    return Column(
      children: [
       
        Expanded(
          child: _buildFixturesList(provider, accentColor),
        ),
      ],
    );
  }

  Widget _buildFixturesList(TeamProvider provider, Color accentColor) {
    if (provider.isLoading && provider.teamFixtures.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }
    if (provider.teamFixtures.isEmpty) {
      return const Center(child: Text("No fixtures found for selected period", style: TextStyle(color: Colors.white38)));
    }

    // Group fixtures by local date using timestamps
    Map<String, List<dynamic>> grouped = {};
    for (var fixture in provider.teamFixtures) {
      final timestamp = fixture['starting_at_timestamp'];
      if (timestamp != null) {
        final localDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
        final dateKey = "${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}";
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(fixture);
      }
    }

    final dates = grouped.keys.toList()..sort();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final dateKey = dates[index];
        final fixtures = grouped[dateKey]!;
        
        String displayDate = dateKey;
        try {
          final parsedLocal = DateTime.parse(dateKey);
          displayDate = DateFormat('yyyy-MM-dd').format(parsedLocal);
        } catch (_) {}

        return _buildDateGroup(displayDate, fixtures, accentColor);
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
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
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
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
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
    final participants = fixture['participants'] as List? ?? [];
    final scores = fixture['scores'] as List? ?? [];
    
    dynamic homeTeam;
    dynamic awayTeam;
    if (participants.isNotEmpty) {
      homeTeam = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
      if (participants.length > 1) {
        awayTeam = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
      }
    }

    String homeScore = "";
    String awayScore = "";
    
    if (scores.isNotEmpty) {
      final homeId = homeTeam?['id'];
      final awayId = awayTeam?['id'];
      
      final hScoreObj = scores.firstWhere((s) => s['participant_id'] == homeId && s['description'] == 'CURRENT', orElse: () => null);
      final aScoreObj = scores.firstWhere((s) => s['participant_id'] == awayId && s['description'] == 'CURRENT', orElse: () => null);
      
      if (hScoreObj != null) homeScore = hScoreObj['score']?['goals']?.toString() ?? "0";
      if (aScoreObj != null) awayScore = aScoreObj['score']?['goals']?.toString() ?? "0";
    }

    final timestamp = fixture['starting_at_timestamp'];
    String timeStr = "--:--";
    if (timestamp != null) {
      final localDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
      timeStr = DateFormat('h:mm a').format(localDate).toLowerCase();
    }
    
    final stateId = fixture['state_id'];
    
    // Comprehensive state lists for Sportmonks v3
    // Finished: 5: FT, 7: AET, 8: FT_P (Finished after Penalties), 9: PEN_FT (Finished after Penalties), 25: Abandoned, 26: Postponed
    final bool isFinished = [5, 7, 8, 9, 25, 26].contains(stateId);
    
    // Live: 2: 1st, 3: HT, 4: 2nd, 6: ET, 12: Live, 17: Delayed, 18: Interrupted, 19: Penalties, 21: Extra Time HT
    final bool isLive = [2, 3, 4, 6, 12, 17, 18, 19, 21].contains(stateId);
    
    // Not Started: Everything else (NS, TBA, etc.)
    final bool isNotStarted = !isFinished && !isLive;
    
    final stateLabel = _getMatchState(stateId);
    
    // Format for NS: "10 Feb\n04:15 PM"
    String nsDateTime = "";
    if (isNotStarted && timestamp != null) {
      final localDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
      nsDateTime = "${DateFormat('d MMM').format(localDate)}\n${DateFormat('h:mm a').format(localDate).toLowerCase()}";
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black38;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsScreen(
              fixture: fixture, 
              leagueId: fixture['league_id'] ?? 0,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5)),
        ),
        child: Row(
          children: [
            // Status / Time Box
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: isLive ? Colors.redAccent.withOpacity(0.1) : (isDark ? const Color(0xFF262626) : Colors.grey[300]),
                borderRadius: BorderRadius.circular(6),
                border: isLive ? Border.all(color: Colors.redAccent.withOpacity(0.3)) : null,
              ),
              child: isLive 
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "LIVE",
                        style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stateLabel,
                        style: const TextStyle(color: Colors.white70, fontSize: 9),
                      ),
                    ],
                  )
                : Text(
                    isFinished ? "FT" : nsDateTime,
                    style: TextStyle(
                      color: isFinished ? (isDark ? Colors.white38 : Colors.black38) : (isDark ? Colors.white70 : Colors.black87), 
                      fontSize: isFinished ? 12 : 10, 
                      fontWeight: FontWeight.w500
                    ),
                    textAlign: TextAlign.center,
                  ),
            ),
            const SizedBox(width: 16),
            // Vertical Line
            Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black12),
            const SizedBox(width: 16),
            // Teams
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamMiniRow(
                    homeTeam?['name'] ?? 'Home', 
                    homeTeam?['image_path'] ?? '', 
                    isNotStarted ? "" : homeScore
                  ),
                  const SizedBox(height: 12),
                  _buildTeamMiniRow(
                    awayTeam?['name'] ?? 'Away', 
                    awayTeam?['image_path'] ?? '', 
                    isNotStarted ? "" : awayScore
                  ),
                ],
              ),
            ),
            // Alarm Icon (Only for NS)
            if (isNotStarted)
              Column(
                children: [
                  Icon(Icons.alarm, color: isDark ? Colors.white60 : Colors.black54, size: 28),
                  const SizedBox(height: 4),
                  Text("Alarm", style: TextStyle(color: subTextColor, fontSize: 10)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMiniRow(String name, String img, [String score = ""]) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Row(
      children: [
        if (img.isNotEmpty)
          Image.network(img, width: 24, height: 24)
        else
          Icon(Icons.shield, size: 24, color: isDark ? Colors.white24 : Colors.black26),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name, 
            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (score.isNotEmpty)
          Text(
            score,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
      ],
    );
  }


  Widget _buildSquadTab(SquadProvider provider, Color accentColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isLoading && provider.squad.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }
    if (provider.squad.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(child: Text("Squad list upcoming", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.squad.length,
      itemBuilder: (context, index) {
        final squadItem = provider.squad[index];
        final player = squadItem['player'] ?? {};
        
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerDetailsScreen(
                  squadItem: squadItem,
                  teamName: widget.teamName,
                  teamLogo: widget.teamLogo,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Row(
              children: [
                if (player['image_path'] != null)
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(player['image_path']),
                  )
                else
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    child: Icon(Icons.person, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['display_name'] ?? player['name'] ?? 'Player',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (squadItem['jersey_number'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Jersey: #${squadItem['jersey_number']}",
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


String _getMatchState(dynamic stateId) {
  switch (stateId) {
    case 1: return "NS";
    case 2: return "1st";
    case 3: return "HT";
    case 4: return "2nd";
    case 5: return "FT";
    case 6: return "ET";
    case 7: return "AET";
    case 8: return "FTP";
    case 9: return "PEN FT";
    case 12: return "LIVE";
    case 13: return "TBA";
    case 17: return "DEL";
    case 18: return "INT";
    case 19: return "PEN";
    case 21: return "ET HT";
    case 25: return "ABD";
    case 26: return "PST";
    default: return "";
  }
}
