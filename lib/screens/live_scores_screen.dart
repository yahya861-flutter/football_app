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
                  primary: Color(0xFFFF8700),
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
    const Color accentColor = Color(0xFFFF8700);

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
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dateStr = isToday ? "Today" : DateFormat('EEE d MMM').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C).withOpacity(0.5) : Colors.grey[50],
        border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor.withOpacity(0.7), size: 20),
            onPressed: () {
              // This is a tab, so "back" usually means returning to the default view or index 0 handled by Home
              // But we can also use it to reset the date to Today here
              if (DateFormat('yyyy-MM-dd').format(_selectedDate) != DateFormat('yyyy-MM-dd').format(DateTime.now())) {
                setState(() {
                  _selectedDate = DateTime.now();
                });
                context.read<FixtureProvider>().fetchFixturesByDate(_selectedDate);
              }
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.chevron_left, color: textColor.withOpacity(0.7), size: 28),
            onPressed: () => _adjustDate(-1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 10, color: subTextColor),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedDate),
                        style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: textColor.withOpacity(0.7), size: 28),
            onPressed: () => _adjustDate(1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesForDateList() {
    return Consumer<FixtureProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.todayFixtures.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(
              0xFFFF8700)));
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
    final Color cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white54 : Colors.black54;
    const Color accentColor = Color(0xFFFF8700);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: logo != null 
              ? Image.network(logo, width: 22, height: 22, errorBuilder: (_, __, ___) => Icon(Icons.emoji_events, color: accentColor, size: 20))
              : Icon(Icons.emoji_events, color: accentColor, size: 20),
          ),
          title: Text(
            name, 
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3)
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${matches.length}", 
                  style: const TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, color: accentColor, size: 16),
              ],
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: matches.asMap().entries.map((entry) {
                  final int idx = entry.key;
                  final dynamic m = entry.value;
                  return _buildModernMatchRow(m, isLast: idx == matches.length - 1);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMatchRow(dynamic match, {bool isLast = false}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white : Colors.black38;

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), width: 1),
          ),
        ),
        child: Row(
          children: [
            // Status Box
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                period == "Sch" || period == "NS" ? time : period,
                style: TextStyle(
                  color: isLive ? const Color(0xFFFF8700) : subTextColor,
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 20),
            // Teams and Scores
            Expanded(
              child: Column(
                children: [
                  _buildModernTeamRow(homeTeam?['name'] ?? 'Home', homeTeam?['image_path'] ?? '', homeScore),
                  const SizedBox(height: 14),
                  _buildModernTeamRow(awayTeam?['name'] ?? 'Away', awayTeam?['image_path'] ?? '', awayScore),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8700).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded, color: Color(0xFFFF8700), size: 18),
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
