import 'package:flutter/material.dart';

/// This screen serves as a placeholder for the Teams tab.
/// It is designed to show detailed information about different football clubs.
class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFD4FF00); // Professional Lime accent

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large group icon representing teams or clubs
          Icon(
            Icons.groups,
            size: 80,
            color: accentColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          // Heading text for the Teams section
          const Text(
            "Teams Content",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            "Manage and view your favorite teams here.",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
