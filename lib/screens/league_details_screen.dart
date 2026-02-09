import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:football_app/providers/league_provider.dart';
import 'package:football_app/providers/match_provider.dart';
import 'package:football_app/providers/fixture_provider.dart';
import 'package:football_app/providers/follow_provider.dart';
import 'package:intl/intl.dart';
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
        leagueProvider.fetchTopScorers(seasonId);
      }
      
      await leagueProvider.fetchLiveLeagues();
      
      if (mounted) {
        final fixtureProvider = context.read<FixtureProvider>();
        fixtureProvider.fetchFixturesByDateRange(widget.leagueId);
        fixtureProvider.fetchResultsByLeague(widget.leagueId);
      }
      
      context.read<MatchProvider>().fetchInPlayMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E1E2C);
    const Color accentColor = Color(0xFFD4FF00); // Premium Lime accent

    return DefaultTabController(
      length: 2, // Fixtures and Table
      child: Scaffold(
        backgroundColor: const Color(0xFF121212), // Darker background as per screenshot
        body: Consumer3<LeagueProvider, MatchProvider, FollowProvider>(
          builder: (context, leagueProvider, matchProvider, followProvider, child) {
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
            final country = league['country']?['name'] ?? 'International';
            final isFollowed = followProvider.isLeagueFollowed(widget.leagueId);

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 160,
                    pinned: true,
                    backgroundColor: const Color(0xFF121212),
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          isFollowed ? Icons.star : Icons.star_border,
                          color: isFollowed ? accentColor : Colors.white60,
                        ),
                        onPressed: () => followProvider.toggleFollowLeague(widget.leagueId),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 48),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // League Logo in a rounded container - Smaller
                            Container(
                              width: 60,
                              height: 60,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D44).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: imagePath.isNotEmpty
                                  ? Image.network(imagePath, fit: BoxFit.contain)
                                  : const Icon(Icons.emoji_events, size: 30, color: Colors.white24),
                            ),
                            const SizedBox(width: 16),
                            // Name and Country
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    country,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
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
                            Tab(text: "Fixtures"),
                            Tab(text: "Table"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  // FIXTURES TAB
                  _buildFixturesTabContent(accentColor),
                  
                  // TABLE TAB
                  _buildTableTabContent(leagueProvider, accentColor),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the "Fixtures" tab content with grouping by date
  Widget _buildFixturesTabContent(Color accentColor) {
    return Consumer<FixtureProvider>(
      builder: (context, fixtureProvider, child) {
        if (fixtureProvider.isLoading && fixtureProvider.fixtures.isEmpty) {
          return  Center(child: CircularProgressIndicator(color: accentColor));
        }

        if (fixtureProvider.fixtures.isEmpty) {
          return _buildPlaceholderTab("No Fixtures Found", Icons.calendar_month, accentColor);
        }

        // Group fixtures by local date using timestamps
        Map<String, List<dynamic>> groupedFixtures = {};
        for (var fixture in fixtureProvider.fixtures) {
          final timestamp = fixture['starting_at_timestamp'];
          if (timestamp != null) {
            try {
              // Convert UTC timestamp to local DateTime
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
            
            // Format header date nicely: e.g. "Monday, Feb 9"
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

  /// Builds a group of fixtures for a specific date
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
            ...fixtures.map((f) => _buildRedesignedFixtureItem(f, accentColor)).toList(),
          ],
        ),
      ),
    );
  }

  /// Redesigned fixture item to match screenshot
  Widget _buildRedesignedFixtureItem(dynamic fixture, Color accentColor) {
    final timestamp = fixture['starting_at_timestamp'];
    String time = "N/A";
    if (timestamp != null) {
      try {
        final localDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
        time = DateFormat('h:mm a').format(localDate);
      } catch (e) {
        time = "N/A";
      }
    }

    final participants = fixture['participants'] as List? ?? [];
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          // Match Time
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              time,
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
                _buildTeamRow(homeName, homeImg),
                const SizedBox(height: 12),
                _buildTeamRow(awayName, awayImg),
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
    );
  }

  Widget _buildTeamRow(String name, String img) {
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
      ],
    );
  }

  /// Builds the content for the "Table" tab (League Standings)
  Widget _buildTableTabContent(LeagueProvider leagueProvider, Color accentColor) {
    if (leagueProvider.isLoading && leagueProvider.standings.isEmpty) {
      return  Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (leagueProvider.standings.isEmpty) {
      return _buildPlaceholderTab("League Table", Icons.table_chart, accentColor);
    }

    return Container(
      color: const Color(0xFF121212),
      child: Column(
        children: [
          // Table Header
          _buildTableHeader(),
          // Standings List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: leagueProvider.standings.length,
              itemBuilder: (context, index) {
                return _buildTableStandingRow(leagueProvider.standings[index], accentColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header row for the standings table
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
          _buildHeaderColumn("MP"),
          _buildHeaderColumn("W"),
          _buildHeaderColumn("D"),
          _buildHeaderColumn("L"),
          _buildHeaderColumn("GD"),
          _buildHeaderColumn("PTS", isLast: true),
        ],
      ),
    );
  }

  /// Helper for header columns
  Widget _buildHeaderColumn(String label, {bool isLast = false}) {
    return SizedBox(
      width: 35,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Builds a single row for the league table
  Widget _buildTableStandingRow(dynamic standing, Color accentColor) {
    final team = standing['participant'] ?? {};
    final position = standing['position'] ?? '-';
    final points = standing['points'] ?? 0;
    final teamName = team['name'] ?? 'Unknown';

    // Extracting stats
    final details = standing['details'] as List? ?? [];
    String mp = "0", w = "0", d = "0", l = "0", gd = "0";

    for (var detail in details) {
      final type = detail['type']?['name']?.toString().toLowerCase() ?? '';
      final value = detail['value']?.toString() ?? '0';
      if (type.contains('played')) mp = value;
      else if (type.contains('won')) w = value;
      else if (type.contains('draw')) d = value;
      else if (type.contains('lost')) l = value;
      else if (type.contains('goals-difference')) gd = value;
    }

    if (mp == "0" && standing['overall'] != null) {
      final overall = standing['overall'];
      mp = overall['played']?.toString() ?? "0";
      w = overall['won']?.toString() ?? "0";
      d = overall['draw']?.toString() ?? "0";
      l = overall['lost']?.toString() ?? "0";
      gd = overall['goals_diff']?.toString() ?? "0";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          // RANK
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: Text(
              position.toString(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          // TEAM NAME
          Expanded(
            child: Text(
              teamName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // STATS
          _buildStatColumn(mp),
          _buildStatColumn(w),
          _buildStatColumn(d),
          _buildStatColumn(l),
          _buildStatColumn(gd),
          // POINTS
          Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              shape: BoxShape.circle,
            ),
            child: Text(
              points.toString(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper for stat columns in the table row
  Widget _buildStatColumn(String value) {
    return SizedBox(
      width: 35,
      child: Text(
        value,
        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w400),
        textAlign: TextAlign.center,
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
}
