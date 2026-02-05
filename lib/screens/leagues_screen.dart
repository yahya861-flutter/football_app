import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:football_app/providers/league_provider.dart';
import 'package:football_app/screens/league_details_screen.dart';

/// This screen displays a grid of all available football leagues.
/// It retrieves data from the LeagueProvider and handles images using Image.network.
class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LeagueProvider>(
      builder: (context, provider, child) {
        // Display a loading indicator while data is being fetched
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)));
        }

        // Display an error message if the API fetch fails
        if (provider.errorMessage != null) {
          return Center(
            child: Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        // Show a message if no leagues are available in the provider
        if (provider.leagues.isEmpty) {
          return const Center(
            child: Text(
              "No leagues found",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        // Build a grid of league cards, 2 items per row
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columns for a clean grid layout
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8, // Controls the height vs width of cards
          ),
          itemCount: provider.leagues.length,
          itemBuilder: (context, index) {
            final league = provider.leagues[index];
            final leagueId = league['id'] ?? 0;

            return InkWell(
              onTap: () {
                // Navigate to the detailed league page when a card is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeagueDetailsScreen(leagueId: leagueId),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: _buildLeagueCard(league),
            );
          },
        );
      },
    );
  }

  /// Builds an individual league card with its logo and name.
  Widget _buildLeagueCard(dynamic league) {
    // Extract name and logo path, with defaults for safety
    final name = league['name'] ?? 'Unknown League';
    final imagePath = league['image_path'] ?? '';
    final shortName = league['short_code'] ?? 'UEFA';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44), // Consistent dark card background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias, // Ensures child content stays within rounded corners
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section containing the league logo
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.black26, // Darker backdrop for logos
              ),
              child: imagePath.isNotEmpty
                  ? Image.network(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.emoji_events,
                        color: Colors.white24,
                        size: 40,
                      ),
                    )
                  : const Icon(Icons.emoji_events, color: Colors.white24, size: 40),
            ),
          ),
          // Footer section containing the league name and short info
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Prevents overflow for long names
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shortName,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
