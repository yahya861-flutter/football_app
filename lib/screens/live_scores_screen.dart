import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:football_app/providers/live_score_provider.dart';

/// This screen displays real-time live scores fetched from the SportMonks API.
/// It uses a Consumer to listen for updates from the LiveScoreProvider.
class LiveScoresScreen extends StatelessWidget {
  const LiveScoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LiveScoreProvider>(
      builder: (context, provider, child) {
        // Show a loading spinner while the API request is in progress
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
        }

        // Display an error message if something went wrong during fetching
        if (provider.errorMessage != null) {
          return Center(
            child: Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        // Show a placeholder message if there are no live scores available
        if (provider.liveScores.isEmpty) {
          return const Center(
            child: Text(
              "No live matches at the moment",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        // Build a list of match cards for each live score item
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.liveScores.length,
          itemBuilder: (context, index) {
            final match = provider.liveScores[index];
            return _buildMatchCard(match);
          },
        );
      },
    );
  }

  /// Builds a detailed card for a single match, following the SportMonks v3 response structure.
  Widget _buildMatchCard(dynamic match) {
    // Parse the match name which typically comes as "Team A vs Team B"
    final name = match['name'] ?? 'Unknown Match';
    List<String> teams = name.split(' vs ');
    String teamA = teams.isNotEmpty ? teams[0] : 'Team A';
    String teamB = teams.length > 1 ? teams[1] : 'Team B';
    
    // Result info contains scores or live status; default to 'Scheduled' if null
    final result = match['result_info'] ?? 'Scheduled';
    final startTime = match['starting_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44), // Consistent dark theme card color
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Team A Section
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.white70, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      teamA,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Match Status / Result Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      result == 'Scheduled' ? 'VS' : result,
                      style: const TextStyle(
                        color: Color(0xFFD4FF00), // Lime accent color for scores
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (result == 'Scheduled' && startTime.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          startTime.split(' ')[0], // Show the match date
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
              // Team B Section
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.white70, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      teamB,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Indicate if the match is currently LIVE
          if (result != 'Scheduled')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 8),
                    const SizedBox(width: 4),
                    Text(
                      "LIVE",
                      style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
