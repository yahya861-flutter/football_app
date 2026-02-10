import 'package:flutter/material.dart';
import 'package:football_app/providers/fixture_provider.dart';
import 'package:football_app/providers/league_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FixtureProvider>().fetchFixturesByDateRange(widget.leagueId);
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

    final timestamp = widget.fixture['starting_at_timestamp'];
    String time = "N/A";
    String date = "N/A";
    if (timestamp != null) {
      final localDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
      time = DateFormat('HH:mm').format(localDate);
      date = DateFormat('yyyy-MM-dd').format(localDate);
    }

    return DefaultTabController(
      length: 7,
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
                          Text(
                            time,
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
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
                    Tab(text: "Fixtures"),
                    Tab(text: "Comments"),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(widget.fixture),
            _buildPlaceholderTab("H2H"),
            _buildPlaceholderTab("Stats"),
            _buildPlaceholderTab("Lineup"),
            _buildTableTab(context),
            _buildFixturesTabContent(accentColor),
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

  Widget _buildInfoTab(dynamic fixture) {
    final venueName = fixture['venue']?['name'] ?? 'Unknown Venue';
    final timestamp = fixture['starting_at_timestamp'];
    String formattedKickOff = "N/A";
    if (timestamp != null) {
      final localDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
      formattedKickOff = "${DateFormat('yyyy-MM-dd').format(localDate)} at ${DateFormat('HH:mm:ss').format(localDate)}";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Poll Section
          _buildExpansionCard(
            icon: Icons.poll,
            title: "Poll",
            content: const SizedBox(height: 10),
          ),
          const SizedBox(height: 12),
          // Top Stats Section
          _buildExpansionCard(
            icon: Icons.bar_chart,
            title: "Top Stats",
            initiallyExpanded: true,
            content: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(Icons.emoji_events_outlined, "Competition", "Premier League"),
                  _buildInfoRow(Icons.access_time, "Kick off Time", formattedKickOff),
                  _buildInfoRow(Icons.stadium_outlined, "Venue:", venueName, showMap: true),
                ],
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
              ],
            ),
          ),
          if (showMap)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFF00C853).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.location_on, color: Color(0xFF00C853), size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildTableTab(BuildContext context) {
    return Consumer<LeagueProvider>(
      builder: (context, leagueProvider, child) {
        if (leagueProvider.standings.isEmpty) {
          return const Center(child: Text("No table data", style: TextStyle(color: Colors.white38)));
        }
        return Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: leagueProvider.standings.length,
                itemBuilder: (context, index) {
                  return _buildTableStandingRow(context, leagueProvider.standings[index]);
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
          Image.network(img, width: 20, height: 20)
        else
          const Icon(Icons.shield, size: 20, color: Colors.white24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.speaker_notes_off_outlined, size: 64, color: Colors.white10),
          SizedBox(height: 16),
          Text(
            "No comments available at that moments",
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Text("$title Content Surface", style: const TextStyle(color: Colors.white38)),
    );
  }
}

