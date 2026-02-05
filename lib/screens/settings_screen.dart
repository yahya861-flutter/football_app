import 'package:flutter/material.dart';

/// This screen handles application settings and user profiles.
/// It is a placeholder where future preferences will be managed.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFD4FF00); // High-visibility Lime accent

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gear icon typically used for settings
          Icon(
            Icons.settings,
            size: 80,
            color: accentColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          // Main label for the Settings tab
          const Text(
            "Settings Content",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            "Customize your experience and manage account.",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
