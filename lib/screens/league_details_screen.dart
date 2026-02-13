import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:football_app/providers/league_provider.dart';
import 'package:football_app/providers/match_provider.dart';
import 'package:football_app/providers/fixture_provider.dart';
import 'package:football_app/providers/follow_provider.dart';
import 'package:football_app/screens/match_details_screen.dart';
import 'package:football_app/screens/team_details_screen.dart';
import 'package:football_app/providers/notification_provider.dart';
import 'package:football_app/widgets/match_notification_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:football_app/l10n/app_localizations.dart';

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
    // Start all fetches concurrently on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final leagueProvider = context.read<LeagueProvider>();
      final fixtureProvider = context.read<FixtureProvider>();
      final matchProvider = context.read<MatchProvider>();

      // 1. Fetch fixtures immediately (don't wait for league details)
      fixtureProvider.fetchFixturesByDateRange(widget.leagueId);
      fixtureProvider.fetchResultsByLeague(widget.leagueId);

      // 2. Fetch league metadata and follow-up data (standings)
      leagueProvider.fetchLeagueById(widget.leagueId).then((_) {
        if (!mounted) return;
        final seasonId = leagueProvider.currentSeasonId;
        if (seasonId != null) {
          leagueProvider.fetchStandings(seasonId);
          leagueProvider.fetchTopScorers(seasonId);
        }
      });

      // 3. Catch-all background fetches
      leagueProvider.fetchLiveLeagues();
      matchProvider.fetchInPlayMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white60 : Colors.black54;
    final Color backgroundColor = isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor;
    final Color headerColor = isDark ? const Color(0xFF121212) : Theme.of(context).primaryColor;
    const Color accentColor = Color(0xFFFF8700); // Premium Lime accent

    return DefaultTabController(
      length: 2, // Fixtures and Table
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: headerColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Consumer<FollowProvider>(
                    builder: (context, followProvider, _) {
                      final isFollowed = followProvider.isLeagueFollowed(widget.leagueId);
                      return IconButton(
                        icon: Icon(
                          isFollowed ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isFollowed ? accentColor : subTextColor,
                        ),
                        onPressed: () => followProvider.toggleFollowLeague(widget.leagueId, leagueData: context.read<LeagueProvider>().selectedLeague),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 90, bottom: 60),
                    child: Selector<LeagueProvider, Map<String, dynamic>?>(
                      selector: (_, p) => p.selectedLeague,
                      builder: (context, league, _) {
                        final name = league?['name'] ?? 'Loading...';
                        final imagePath = league?['image_path'] ?? '';
                        final country = league?['country']?['name'] ?? '...';

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                              ),
                              child: Hero(
                                tag: 'league-logo-${widget.leagueId}',
                                child: imagePath.isNotEmpty
                                    ? Image.network(imagePath, fit: BoxFit.contain)
                                    : Icon(Icons.emoji_events, size: 36, color: subTextColor),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.public_rounded, size: 14, color: subTextColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        country,
                                        style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    decoration: BoxDecoration(
                      color: headerColor,
                      border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: accentColor,
                      labelColor: accentColor,
                      unselectedLabelColor: subTextColor,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                      tabs: [
                        Tab(text: AppLocalizations.of(context)!.fixtures),
                        Tab(text: AppLocalizations.of(context)!.tableTab),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // FIXTURES TAB
              _buildFixturesTabContent(accentColor),

              // TABLE TAB
              Consumer<LeagueProvider>(
                builder: (context, lp, _) =>
                    _buildTableTabContent(lp, accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the "Fixtures" tab content with grouping by date
  Widget _buildFixturesTabContent(Color accentColor) {
    return Consumer<FixtureProvider>(
      builder: (context, fixtureProvider, child) {
        if (fixtureProvider.isLoading && fixtureProvider.fixtures.isEmpty) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        if (fixtureProvider.fixtures.isEmpty) {
          return _buildPlaceholderTab(
            AppLocalizations.of(context)!.noFixturesFound,
            Icons.calendar_month,
            accentColor,
          );
        }

        // Group fixtures by local date using timestamps
        Map<String, List<dynamic>> groupedFixtures = {};
        for (var fixture in fixtureProvider.fixtures) {
          final timestamp = fixture['starting_at_timestamp'];
          if (timestamp != null) {
            try {
              // Convert UTC timestamp to local DateTime
              final localDate = DateTime.fromMillisecondsSinceEpoch(
                timestamp * 1000,
              ).toLocal();
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: accentColor,
          collapsedIconColor: isDark ? Colors.white54 : Colors.black54,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.green, size: 20),
          ),
          title: Text(
            date,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.01) : Colors.grey[50],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: Column(
                children: fixtures.map((f) => _buildRedesignedFixtureItem(f, accentColor)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Redesigned fixture item to match screenshot
  Widget _buildRedesignedFixtureItem(dynamic fixture, Color accentColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    final timestamp = fixture['starting_at_timestamp'];
    String time = AppLocalizations.of(context)!.notAvailable;
    if (timestamp != null) {
      try {
        final localDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
        time = DateFormat('HH:mm').format(localDate);
      } catch (e) { time = AppLocalizations.of(context)!.notAvailable; }
    }

    final participants = fixture['participants'] as List? ?? [];
    dynamic homeTeam, awayTeam;
    if (participants.isNotEmpty) {
      homeTeam = participants.firstWhere((p) => p['meta']?['location'] == 'home', orElse: () => participants[0]);
      if (participants.length > 1) {
        awayTeam = participants.firstWhere((p) => p['meta']?['location'] == 'away', orElse: () => participants[1]);
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => MatchDetailsScreen(fixture: fixture, leagueId: widget.leagueId)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: (() {
                final state = fixture['state'];
                final String period = state?['short_name'] ?? state?['name'] ?? AppLocalizations.of(context)!.scheduledShort;
                final bool isLive = state != null && state['id'] != null && [2, 3, 6, 9, 10, 11, 12, 13, 14, 15, 22].contains(state['id']);

                return Text(
                  (period == AppLocalizations.of(context)!.scheduledShort || period == AppLocalizations.of(context)!.notStartedShort) ? time : period,
                  style: TextStyle(
                    color: isLive ? const Color(0xFFFF8700) : textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center
                );
              })(),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  _buildTeamRow(homeTeam?['name'] ?? AppLocalizations.of(context)!.home, homeTeam?['image_path'] ?? ''),
                  const SizedBox(height: 12),
                  _buildTeamRow(awayTeam?['name'] ?? AppLocalizations.of(context)!.away, awayTeam?['image_path'] ?? ''),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, _) {
                final matchId = fixture['id'] ?? 0;
                final bool isActive = notificationProvider.isNotificationSet(matchId);
                final String homeName = fixture['participants']?[0]?['name'] ?? AppLocalizations.of(context)!.home;
                final String awayName = fixture['participants']?[1]?['name'] ?? AppLocalizations.of(context)!.away;
                final timestamp = fixture['starting_at_timestamp'];
                final startTime = timestamp != null 
                    ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
                    : DateTime.now();

                final state = fixture['state'];
                final String period = state?['short_name'] ?? state?['name'] ?? AppLocalizations.of(context)!.scheduledShort;
                final isUpcoming = period == AppLocalizations.of(context)!.scheduledShort || period == AppLocalizations.of(context)!.notStartedShort;

                return GestureDetector(
                  onTap: !isUpcoming 
                    ? null 
                    : () {
                        if (isActive) {
                          notificationProvider.toggleAllOff(matchId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.notificationsRemoved),
                              backgroundColor: Colors.grey[800],
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => MatchNotificationDialog(
                              matchId: matchId,
                              matchTitle: "$homeName vs $awayName",
                              startTime: startTime,
                            ),
                          );
                        }
                      },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: !isUpcoming 
                        ? Colors.white.withOpacity(0.02)
                        : (isActive ? const Color(0xFF48C9B0).withOpacity(0.1) : Colors.white.withOpacity(0.05)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive ? Icons.notifications_active : Icons.notifications_none_rounded,
                      color: !isUpcoming 
                        ? Colors.white10 
                        : (isActive ? const Color(0xFF48C9B0) : (isDark ? Colors.white60 : Colors.black54)),
                      size: 28,
                    ),
                  ),
                );
              },
            ),
      ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(String name, String img) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      children: [
        if (img.isNotEmpty)
          Image.network(img, width: 22, height: 22, errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, size: 22, color: Colors.grey))
        else
          const Icon(Icons.shield_rounded, size: 22, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
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
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (leagueProvider.standings.isEmpty) {
      return _buildPlaceholderTab(AppLocalizations.of(context)!.tableTab, Icons.table_chart_rounded, accentColor);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 750,
        child: Column(
          children: [
            _buildTableHeader(),
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
      ),
    );
  }

  /// Builds the header row for the standings table
  Widget _buildTableHeader() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.01) : Colors.grey[50],
        border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text("#", style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 180,
            child: Text(AppLocalizations.of(context)!.team, style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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

  /// Helper for header columns
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

  /// Builds a single row for the league table
  Widget _buildTableStandingRow(dynamic standing, Color accentColor) {
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => TeamDetailsScreen(teamId: team['id'], teamName: teamName, teamLogo: teamImg)));
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
              child: Text(position.toString(), style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 180,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
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
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(pts, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, {double width = 32}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black54;
    return SizedBox(
      width: width,
      child: Text(value, style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
    );
  }

  /// Helper to build a clean placeholder for empty tabs
  Widget _buildPlaceholderTab(String title, IconData icon, Color accentColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white12 : Colors.black12;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Icon(icon, size: 100, color: subTextColor),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Content coming soon", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
