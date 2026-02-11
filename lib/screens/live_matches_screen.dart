import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:football_app/providers/inplay_provider.dart';
import 'package:football_app/screens/match_details_screen.dart';

class LiveMatchesScreen extends StatelessWidget {
  final bool isTab;
  const LiveMatchesScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;
    final Color primaryColor = isDark ? const Color(0xFF1E1E2C) : Theme.of(context).primaryColor;
    const Color accentColor = Color(0xFFFF8700);

    final content = Consumer<InPlayProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.inPlayMatches.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: accentColor));
        }

        if (provider.inPlayMatches.isEmpty) {
          return _buildEmptyState(context, "No live matches at the moment", provider.fetchInPlayMatches);
        }

        return _buildGroupedMatchList(context, provider.inPlayMatches);
      },
    );

    if (isTab) {
      return content;
    }

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Live Matches",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: () {
              context.read<InPlayProvider>().fetchInPlayMatches();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Refreshing live matches..."), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, VoidCallback onRefresh) {
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

  Widget _buildGroupedMatchList(BuildContext context, List<dynamic> matchesList) {
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
        
        return _buildModernLeagueGroup(context, leagueName, leagueLogo, matches);
      },
    );
  }

  Widget _buildModernLeagueGroup(BuildContext context, String name, String? logo, List<dynamic> matches) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;
    final Color cardColor = isDark ? const Color(0xFF2D2D44) : Colors.grey[200]!;

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
          children: matches.map((m) => _buildModernMatchRow(context, m)).toList(),
        ),
      ),
    );
  }

  Widget _buildModernMatchRow(BuildContext context, dynamic match) {
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
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isLive ? const Color(0xFFFF8700) : subTextColor,
                  fontSize: 10, 
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                   _buildModernTeamRow(context, homeTeam?['name'] ?? 'Home', homeTeam?['image_path'] ?? '', homeScore),
                  const SizedBox(height: 14),
                  _buildModernTeamRow(context, awayTeam?['name'] ?? 'Away', awayTeam?['image_path'] ?? '', awayScore),
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

  Widget _buildModernTeamRow(BuildContext context, String name, String img, String score) {
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
        Text(
          score,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
