import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:football_app/providers/league_provider.dart';

/// This screen shows detailed information for a single football league.
/// It triggers a fetch call on initialization to get the latest data for the given league ID.
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
    // Fetch individual league details when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeagueProvider>().fetchLeagueById(widget.leagueId);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E1E2C);
    const Color accentColor = Color(0xFFD4FF00); // Premium Lime accent

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text("League Details", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Return to the previous screen
        ),
      ),
      body: Consumer<LeagueProvider>(
        builder: (context, provider, child) {
          // Show loading spinner while fetching specific league details
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: accentColor));
          }

          // Show error message if the fetch fails
          if (provider.errorMessage != null) {
            return Center(
              child: Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final league = provider.selectedLeague;
          // Security check if league data is null
          if (league == null) {
            return const Center(
              child: Text("No details found for this league", style: TextStyle(color: Colors.white70)),
            );
          }

          // Extract basic info with defaults
          final name = league['name'] ?? 'Unknown League';
          final imagePath = league['image_path'] ?? '';
          final type = league['type'] ?? 'N/A';
          final subType = league['sub_type'] ?? 'N/A';
          final shortCode = league['short_code'] ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Display the league logo in a large, clean format
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D44),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: imagePath.isNotEmpty
                      ? Image.network(imagePath, height: 120, width: 120, fit: BoxFit.contain)
                      : const Icon(Icons.emoji_events, size: 80, color: Colors.white24),
                ),
                const SizedBox(height: 24),
                // League Name
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Short Code Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    shortCode,
                    style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
                // Detailed Info Grid or List
                _buildInfoRow("Type", type.toString().toUpperCase()),
                _buildInfoRow("Sub-Type", subType.toString().replaceAll('_', ' ').toUpperCase()),
                _buildInfoRow("Category", (league['category'] ?? 'N/A').toString()),
                _buildInfoRow("Has Jerseys", (league['has_jerseys'] == true ? "YES" : "NO")),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Helper method to create a clean, consistent row of key-value information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
