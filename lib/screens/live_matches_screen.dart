import 'package:football_app/providers/notification_provider.dart';
import 'package:football_app/widgets/match_notification_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:football_app/providers/inplay_provider.dart';
import 'package:football_app/screens/match_details_screen.dart';

import 'package:football_app/l10n/app_localizations.dart';

class LiveMatchesScreen extends StatelessWidget {
  final bool isTab;
  const LiveMatchesScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;
    final Color primaryColor = isDark ? Colors.black : Theme.of(context).primaryColor;
    const Color accentColor = Color(0xFFFF8700);
    final l10n = AppLocalizations.of(context)!;


    final content = Consumer<InPlayProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.inPlayMatches.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: accentColor)),
          );
        }

        if (provider.inPlayMatches.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(AppLocalizations.of(context)!.noLiveMatches, style: TextStyle(color: subTextColor)),
            ),
          );
        }
        return _buildGroupedMatchList(context, provider.inPlayMatches);
      },
    );

    if (isTab) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.liveMatches,
                style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          content,
          const SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for dock
        ],
      );
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
          l10n.liveMatches,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: () {
              context.read<InPlayProvider>().fetchInPlayMatches();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.refreshingLiveMatches), duration: const Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.liveMatches, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                  if (context.watch<InPlayProvider>().isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(l10n.refreshingLiveMatches, style: TextStyle(color: subTextColor, fontSize: 13)),
                    ),
                ],
              ),
            ),
          ),
          content,
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, VoidCallback onRefresh) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;
    final l10n = AppLocalizations.of(context)!;

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
            child: Text(l10n.refresh, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedMatchList(BuildContext context, List<dynamic> matchesList) {
    Map<String, List<dynamic>> groupedMatches = {};
    final l10n = AppLocalizations.of(context)!;
    for (var match in matchesList) {
      final leagueName = match['league']?['name'] ?? l10n.other;
      groupedMatches.putIfAbsent(leagueName, () => []).add(match);
    }

    final leagues = groupedMatches.keys.toList();

    return SliverPadding(
      padding: const EdgeInsets.only(top: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final leagueName = leagues[index];
            final matches = groupedMatches[leagueName]!;
            final leagueLogo = matches.first['league']?['image_path'];
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildModernLeagueGroup(context, leagueName, leagueLogo, matches),
            );
          },
          childCount: leagues.length,
        ),
      ),
    );
  }

  Widget _buildModernLeagueGroup(BuildContext context, String name, String? logo, List<dynamic> matches) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
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
                  return _buildModernMatchRow(context, m, isLast: idx == matches.length - 1);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMatchRow(BuildContext context, dynamic match, {bool isLast = false}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color subTextColor = isDark ? Colors.white : Colors.black38;
    final l10n = AppLocalizations.of(context)!;

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
    
    // Extract and format start time
    final timestamp = match['starting_at_timestamp'];
    String matchTime = "";
    if (timestamp != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
      matchTime = DateFormat('HH:mm').format(date);
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
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (period == "Sch" || period == "NS") ? matchTime : period,
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
            Expanded(
              child: Column(
                children: [
                   _buildModernTeamRow(context, homeTeam?['name'] ?? l10n.home, homeTeam?['image_path'] ?? '', homeScore),
                  const SizedBox(height: 14),
                  _buildModernTeamRow(context, awayTeam?['name'] ?? l10n.away, awayTeam?['image_path'] ?? '', awayScore),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, _) {
                final matchId = match['id'] ?? 0;
                final bool isActive = notificationProvider.isNotificationSet(matchId);
                final String homeName = homeTeam?['name'] ?? l10n.home;
                final String awayName = awayTeam?['name'] ?? l10n.away;
                final timestamp = match['starting_at_timestamp'];
                final startTime = timestamp != null 
                    ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
                    : DateTime.now();

                final isUpcoming = period == "Sch" || period == "NS";

                return GestureDetector(
                  onTap: !isUpcoming 
                    ? null 
                    : () {
                        if (isActive) {
                          notificationProvider.toggleAllOff(matchId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.notificationsRemoved),
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
                        : (isActive ? const Color(0xFF48C9B0).withOpacity(0.1) : const Color(0xFFFF8700).withOpacity(0.1)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive ? Icons.notifications_active : Icons.notifications_none_rounded,
                      color: !isUpcoming 
                        ? subTextColor.withOpacity(0.1) 
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
        const SizedBox(width: 8),
        Text(
          score,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
