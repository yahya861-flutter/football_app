import 'package:flutter/material.dart';
import 'package:football_app/l10n/app_localizations.dart';

class ShortsScreen extends StatelessWidget {
  const ShortsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, size: 80, color: Color(0xFFFF8700)),
            const SizedBox(height: 24),
            Text(l10n.shortsComingSoon, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(l10n.comingSoonSubtitle, style: const TextStyle(color: Colors.white60, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
