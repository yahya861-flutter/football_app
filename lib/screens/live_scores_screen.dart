import 'package:flutter/material.dart';
import 'package:football_app/providers/fixture_provider.dart';
import 'package:football_app/screens/match_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:football_app/providers/inplay_provider.dart';
import 'package:football_app/screens/live_matches_screen.dart';

class LiveScoresScreen extends StatefulWidget {
  const LiveScoresScreen({super.key});

  @override
  State<LiveScoresScreen> createState() => _LiveScoresScreenState();
}

class _LiveScoresScreenState extends State<LiveScoresScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark 
              ? const ColorScheme.dark(
                  primary: Color(0xFFD4FF00),
                  onPrimary: Colors.black,
                  surface: Color(0xFF1E1E2C),
                  onSurface: Colors.white,
                )
              : const ColorScheme.light(
                  primary: Color(0xFF1E1E2C),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      context.read<FixtureProvider>().fetchFixturesByDate(_selectedDate);
    }
  }

  void _adjustDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    context.read<FixtureProvider>().fetchFixturesByDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.grey[200]!;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;
    const Color accentColor = Color(0xFFD4FF00);

    return Column(
      children: [
        _buildFilterHeader(),
        Expanded(
          child: _buildMatchesForDateList(),
        ),
      ],
    );
  }

  Widget _buildFilterHeader() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.grey[200]!;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dateStr = isToday ? "Today" : DateFormat('EEE d MMM yyyy').format(_selectedDate);

    return Consumer<InPlayProvider>(
      builder: (context, inPlay, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Live Button
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  LiveMatchesScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Live",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "(${inPlay.inPlayMatches.length})",
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Date Navigator
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: textColor),
                    onPressed: () => _adjustDate(-1),
                  ),
                  Column(
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        DateFormat('d MMM yyyy').format(_selectedDate),
                        style: TextStyle(color: subTextColor, fontSize: 10),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: textColor),
                    onPressed: () => _adjustDate(1),
                  ),
                ],
              ),
              const Spacer(),
              // Calendar Icon
              IconButton(
                icon: Icon(Icons.calendar_month_outlined, color: subTextColor),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchesForDateList() {
    return Consumer<FixtureProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.todayFixtures.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
        }

        if (provider.todayFixtures.isEmpty) {
          return _buildEmptyState("No matches found for this date", () => provider.fetchFixturesByDate(_selectedDate));
        }

        return _buildGroupedMatchList(provider.todayFixtures);
      },
    );
  }

  Widget _buildEmptyState(String message, VoidCallback onRefresh) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, color: isDark ? Colors.white10 : Colors.black12, size: 64),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: subTextColor)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRefresh,
            style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.black12),
            child: Text("Refresh", style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedMatchList(List<dynamic> matchesList) {
    // Group by league
    Map<String, List<dynamic>> groupedMatches = {};
    for (var match in matchesList) {
      final leagueName = match['league']?['name'] ?? 'Other';
      groupedMatches.putIfAbsent(leagueName, () => []).add(match);
    }

    final leagues = groupedMatches.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: leagues.length,
      itemBuilder: (context, index) {
        final leagueName = leagues[index];
        final matches = groupedMatches[leagueName]!;
        final leagueLogo = matches.first['league']?['image_path'];
        
        return _buildModernLeagueGroup(leagueName, leagueLogo, matches);
      },
    );
  }

  Widget _buildModernLeagueGroup(String name, String? logo, List<dynamic> matches) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.grey[200]!;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: logo != null 
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(logo, width: 24, height: 24, errorBuilder: (_, __, ___) => Icon(Icons.emoji_events, color: subTextColor, size: 24)),
              )
            : Icon(Icons.emoji_events, color: subTextColor, size: 24),
          title: Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, shape: BoxShape.circle),
                child: Text("${matches.length}", style: TextStyle(color: textColor, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, color: subTextColor),
            ],
          ),
          children: matches.map((m) => _buildModernMatchRow(m)).toList(),
        ),
      ),
    );
  }

  Widget _buildModernMatchRow(dynamic match) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

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
    final stateId = state?['id'];
    bool isLive = stateId != null && [2, 3, 6, 9, 10, 11, 12, 13, 14, 15, 22].contains(stateId);
    
    final timestamp = match['starting_at_timestamp'];
    String time = "N/A";
    if (timestamp != null) {
      time = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal());
    }

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5)),
        ),
        child: Row(
          children: [
            // Status Box
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D44) : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                period == "Sch" || period == "NS" ? time : period,
                style: TextStyle(
                  color: isLive ? const Color(0xFFD4FF00) : subTextColor, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 24),
            // Teams and Scores
            Expanded(
              child: Column(
                children: [
                  _buildModernTeamRow(homeTeam?['name'] ?? 'Home', homeTeam?['image_path'] ?? '', homeScore),
                  const SizedBox(height: 12),
                  _buildModernTeamRow(awayTeam?['name'] ?? 'Away', awayTeam?['image_path'] ?? '', awayScore),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Alarm Button
            Column(
              children: [
                Icon(Icons.notifications_none, color: subTextColor, size: 20),
                const SizedBox(height: 2),
                Text("Alarm", style: TextStyle(color: subTextColor, fontSize: 8)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTeamRow(String name, String img, String score) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Row(
      children: [
        if (img.isNotEmpty)
          Image.network(img, width: 22, height: 22, errorBuilder: (_, __, ___) => Icon(Icons.shield, size: 22, color: subTextColor))
        else
          Icon(Icons.shield, size: 22, color: subTextColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          score,
          style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
