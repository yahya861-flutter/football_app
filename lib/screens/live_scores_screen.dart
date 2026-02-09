import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:football_app/providers/live_score_provider.dart';
import 'package:football_app/providers/inplay_provider.dart';
import 'package:intl/intl.dart';

class LiveScoresScreen extends StatefulWidget {
  const LiveScoresScreen({super.key});

  @override
  State<LiveScoresScreen> createState() => _LiveScoresScreenState();
}

class _LiveScoresScreenState extends State<LiveScoresScreen> {
  bool _isLiveOnly = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InPlayProvider>().fetchInPlayMatches();
      context.read<LiveScoreProvider>().fetchLiveScores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopFilterBar(),
        Expanded(
          child: _isLiveOnly ? _buildInPlayList() : _buildAllLiveScoresList(),
        ),
      ],
    );
  }

  Widget _buildTopFilterBar() {
    return Consumer<InPlayProvider>(
      builder: (context, inPlay, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isLiveOnly = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isLiveOnly ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isLiveOnly ? Colors.white : Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Live",
                        style: TextStyle(
                          color: _isLiveOnly ? Colors.red : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "(${inPlay.inPlayMatches.length})",
                        style: TextStyle(
                          color: _isLiveOnly ? Colors.red : Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _isLiveOnly = false),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        const Text("Today", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          DateFormat('d MMM yyyy').format(DateTime.now()),
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInPlayList() {
    return Consumer<InPlayProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.inPlayMatches.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
        }

        if (provider.inPlayMatches.isEmpty) {
          return const Center(child: Text("No live matches at the moment", style: TextStyle(color: Colors.white70)));
        }

        // Group by league
        Map<String, List<dynamic>> groupedMatches = {};
        for (var match in provider.inPlayMatches) {
          final leagueName = match['league']?['name'] ?? 'Other';
          if (!groupedMatches.containsKey(leagueName)) {
            groupedMatches[leagueName] = [];
          }
          groupedMatches[leagueName]!.add(match);
        }

        final leagues = groupedMatches.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: leagues.length,
          itemBuilder: (context, index) {
            final leagueName = leagues[index];
            final matches = groupedMatches[leagueName]!;
            final leagueLogo = matches.first['league']?['image_path'];
            
            return _buildLeagueGroup(leagueName, leagueLogo, matches);
          },
        );
      },
    );
  }

  Widget _buildAllLiveScoresList() {
    return Consumer<LiveScoreProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.liveScores.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
        }

        if (provider.liveScores.isEmpty) {
          return const Center(child: Text("No matches today", style: TextStyle(color: Colors.white70)));
        }

        // Group by league
        Map<String, List<dynamic>> groupedMatches = {};
        for (var match in provider.liveScores) {
          final leagueName = match['league']?['name'] ?? 'Other';
          if (!groupedMatches.containsKey(leagueName)) {
            groupedMatches[leagueName] = [];
          }
          groupedMatches[leagueName]!.add(match);
        }

        final leagues = groupedMatches.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: leagues.length,
          itemBuilder: (context, index) {
            final leagueName = leagues[index];
            final matches = groupedMatches[leagueName]!;
            final leagueLogo = matches.first['league']?['image_path'];
            
            return _buildLeagueGroup(leagueName, leagueLogo, matches);
          },
        );
      },
    );
  }

  Widget _buildLeagueGroup(String name, String? logo, List<dynamic> matches) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: logo != null 
            ? Image.network(logo, width: 30, height: 30)
            : const Icon(Icons.emoji_events, color: Colors.white24, size: 24),
          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  matches.length.toString(),
                  style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
            ],
          ),
          children: matches.map((m) => _buildMatchRow(m)).toList(),
        ),
      ),
    );
  }

  Widget _buildMatchRow(dynamic match) {
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

    String homeScore = "0";
    String awayScore = "0";
    if (scores.isNotEmpty) {
      final hScoreObj = scores.firstWhere((s) => s['participant_id'] == homeTeam?['id'] && s['description'] == 'CURRENT', orElse: () => null);
      final aScoreObj = scores.firstWhere((s) => s['participant_id'] == awayTeam?['id'] && s['description'] == 'CURRENT', orElse: () => null);
      if (hScoreObj != null) homeScore = hScoreObj['score']?['goals']?.toString() ?? "0";
      if (aScoreObj != null) awayScore = aScoreObj['score']?['goals']?.toString() ?? "0";
    }

    // State handle
    final state = match['state'];
    String period = state?['short_name'] ?? state?['name'] ?? "NS";
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          // Status Box (FT / Minute)
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D44),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              period,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 16),
          // Teams and Scores
          Expanded(
            child: Column(
              children: [
                _buildTeamRow(homeTeam?['name'] ?? 'Home', homeTeam?['image_path'] ?? '', homeScore),
                const SizedBox(height: 12),
                _buildTeamRow(awayTeam?['name'] ?? 'Away', awayTeam?['image_path'] ?? '', awayScore),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Vertical Line
          Container(width: 1, height: 40, color: Colors.white10),
          const SizedBox(width: 16),
          // Alarm Icon
          const Column(
            children: [
              Icon(Icons.alarm, color: Colors.white60, size: 24),
              SizedBox(height: 4),
              Text("Alarm", style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow(String name, String img, String score) {
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
        Text(
          score,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  }

