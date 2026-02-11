import 'package:flutter/material.dart';

/// This screen serves as a placeholder for the Competitions tab.
/// In a future update, it will display a list of tournaments and cup competitions.
class CompetitionsScreen extends StatelessWidget {
  const CompetitionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFF8700); // Lime/Neon Yellow accent

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large icon representing competitions or tournaments
          Icon(
            Icons.reorder,
            size: 80,
            color: accentColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          // Friendly text indicating the current section
          const Text(
            "Competitions Content",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tournament data will be available soon.",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
