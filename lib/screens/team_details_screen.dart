import 'package:flutter/material.dart';
import 'package:football_app/providers/squad_provider.dart';
import 'package:football_app/providers/team_provider.dart';
import 'package:football_app/screens/player_details_screen.dart';
import 'package:football_app/screens/match_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/transfer_provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final teamProvider = context.read<TeamProvider>();
      await teamProvider.fetchTeamDetails(widget.teamId);
      final seasons = teamProvider.selectedTeam?['seasons'] as List? ?? [];
      if (seasons.isNotEmpty) {
        setState(() {
          _selectedSeasonId = seasons.last['id'];
        });
        teamProvider.fetchTeamStats(widget.teamId, _selectedSeasonId!);
      }
      teamProvider.fetchTeamFixtures(widget.teamId);
      context.read<SquadProvider>().fetchSquad(widget.teamId);
      teamProvider.fetchTeamTransfers(widget.teamId);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFD4FF00);
    
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: const Color(0xFF121212),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.star_border, color: Colors.white60),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 48),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D44).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: widget.teamLogo.isNotEmpty
                              ? Image.network(widget.teamLogo, fit: BoxFit.contain)
                              : const Icon(Icons.shield, size: 40, color: Colors.white24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.teamName,
                                style: const TextStyle(
                                  color: Colors.white,
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
                                  style: const TextStyle(
                                    color: Colors.white60,
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
                      labelColor: accentColor,
                      unselectedLabelColor: Colors.white38,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                      tabs: const [
                        Tab(text: "Stats"),
                        Tab(text: "Fixtures"),
                        Tab(text: "Squad"),
                        Tab(text: "Transfers"),
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
              Consumer<TransferProvider>(
                builder: (context, provider, _) => _buildTransfersTab(provider, accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab(TeamProvider provider, List seasons, Color accentColor) {
    final currentSeason = seasons.firstWhere((s) => s['id'] == _selectedSeasonId, orElse: () => seasons.isNotEmpty ? seasons.last : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Season Selector
          if (seasons.isNotEmpty)
            GestureDetector(
              onTap: () => _showSeasonSelector(context, seasons, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF26BC94),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      currentSeason?['name'] ?? "Select Season",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 60),
          // Illustration and Empty State (Matching user screenshot)
          Center(
            child: Column(
              children: [
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
                  "Stats not found",
                  style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSeasonSelector(BuildContext context, List seasons, TeamProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return ListView.builder(
          itemCount: seasons.length,
          itemBuilder: (context, index) {
            final season = seasons[seasons.length - 1 - index];
            return ListTile(
              title: Text(season['name'], style: const TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _selectedSeasonId = season['id'];
                });
                provider.fetchTeamStats(widget.teamId, _selectedSeasonId!);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFixturesTab(TeamProvider provider, Color accentColor) {
    if (provider.isLoading && provider.teamFixtures.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }
    if (provider.teamFixtures.isEmpty) {
      return const Center(child: Text("No fixtures found", style: TextStyle(color: Colors.white38)));
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
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
    String stateLabel = _getMatchState(stateId);
    String displayTime = stateLabel == "NS" ? timeStr : stateLabel;

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
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: Row(
          children: [
            // Match Time Box
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF262626),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                displayTime,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 16),
            // Vertical Line
            Container(width: 1, height: 40, color: Colors.white10),
            const SizedBox(width: 16),
            // Teams
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamMiniRow(homeTeam?['name'] ?? 'Home', homeTeam?['image_path'] ?? '', homeScore),
                  const SizedBox(height: 12),
                  _buildTeamMiniRow(awayTeam?['name'] ?? 'Away', awayTeam?['image_path'] ?? '', awayScore),
                ],
              ),
            ),
            // Alarm Icon
            Column(
              children: [
                const Icon(Icons.alarm, color: Colors.white60, size: 28),
                const SizedBox(height: 4),
                const Text("Alarm", style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMiniRow(String name, String img, [String score = ""]) {
    return Row(
      children: [
        if (img.isNotEmpty)
          Image.network(img, width: 24, height: 24)
        else
          const Icon(Icons.shield, size: 24, color: Colors.white24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name, 
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (score.isNotEmpty)
          Text(
            score,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
      ],
    );
  }


  Widget _buildSquadTab(SquadProvider provider, Color accentColor) {
    if (provider.isLoading && provider.squad.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }
    if (provider.squad.isEmpty) {
      return const Center(child: Text("Squad list upcoming", style: TextStyle(color: Colors.white38)));
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
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (player['image_path'] != null)
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(player['image_path']),
                  )
                else
                  const CircleAvatar(
                    radius: 25,
                    child: Icon(Icons.person, color: Colors.grey),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['display_name'] ?? player['name'] ?? 'Player',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (squadItem['jersey_number'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Jersey: #${squadItem['jersey_number']}",
                            style: const TextStyle(color: Colors.white38, fontSize: 13),
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

  Widget _buildTransfersTab(TransferProvider provider, Color accentColor) {
    if (provider.transfers.isEmpty) {
      return const Center(child: Text("No recent transfers", style: TextStyle(color: Colors.white38)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.transfers.length,
      itemBuilder: (context, index) {
        final transfer = provider.transfers[index];
        final player = transfer['player'] ?? {};
        final fromTeam = transfer['fromTeam'] ?? {};
        final toTeam = transfer['toTeam'] ?? {};
        final date = transfer['date'] ?? 'N/A';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player['display_name'] ?? 'Unknown Player', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("$date: ${fromTeam['name'] ?? 'N/A'} -> ${toTeam['name'] ?? 'N/A'}", style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
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
    case 4: return "BRK";
    case 5: return "FT";
    case 6: return "ET";
    case 7: return "AET";
    case 8: return "FTP";
    case 9: return "PEN";
    default: return "";
  }
}
