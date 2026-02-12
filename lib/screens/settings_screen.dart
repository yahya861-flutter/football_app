import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'feedback_screen.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatelessWidget {
  final bool isTab;
  const SettingsScreen({super.key, this.isTab = false});

  final String _youtubeUrl = 'https://www.youtube.com/';

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showReviewDialog(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enjoying the App?",
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Tap a star to rate us on the Store!",
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 32,
                )),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Later", style: TextStyle(color: textColor.withOpacity(0.5))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _launchUrl(_youtubeUrl);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFA5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Rate"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    
    // Theme aware colors
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color sectionColor = isDark ? Colors.white38 : Colors.black38;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PREMIUM BANNER
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PremiumScreen()),
            ),
            child: _buildPremiumBanner(),
          ),
          const SizedBox(height: 32),
          
          // GENERAL SECTION
          Text("General", style: TextStyle(color: sectionColor, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildToggleTile(
            icon: Icons.dark_mode,
            title: "Dark Mode",
            value: isDark,
            onChanged: (val) => themeProvider.toggleTheme(),
            textColor: textColor,
          ),
          const SizedBox(height: 32),

          // OTHERS SECTION
          Text("Others", style: TextStyle(color: sectionColor, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildActionTile(
            icon: Icons.share, 
            title: "Share", 
            textColor: textColor,
            onTap: () => Share.share("Check out this amazing Football App! $_youtubeUrl"),
          ),
          _buildActionTile(
            icon: Icons.star_border, 
            title: "Rate Us", 
            textColor: textColor,
            onTap: () => _showReviewDialog(context),
          ),
          _buildActionTile(
            icon: Icons.feedback_outlined, 
            title: "Feedback", 
            textColor: textColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FeedbackScreen()),
            ),
          ),
          _buildActionTile(
            icon: Icons.verified_user_outlined, 
            title: "Privacy Policy", 
            textColor: textColor,
            onTap: () => _launchUrl(_youtubeUrl),
          ),
          /*const SizedBox(height: 16),
          _buildActionTile(
            icon: Icons.notifications,
            title: "Test Notification",
            textColor: textColor,
            iconColor: const Color(0xFF48C9B0),
            iconSize: 28,
            onTap: () {
              context.read<NotificationProvider>().showTestNotification();
            },
          ),
          _buildActionTile(
            icon: Icons.alarm,
            title: "Test Scheduled Alarm (10s)",
            textColor: textColor,
            iconColor: const Color(0xFF48C9B0),
            iconSize: 28,
            onTap: () {
              context.read<NotificationProvider>().scheduleTestAlarm();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Loud Alarm scheduled for 10 seconds..."),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          _buildActionTile(
            icon: Icons.notifications_active,
            title: "Test Scheduled Notification (10s)",
            textColor: textColor,
            iconColor: const Color(0xFF48C9B0),
            iconSize: 28,
            onTap: () {
              context.read<NotificationProvider>().scheduleTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Standard Notification scheduled for 10 seconds..."),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),*/
        ],
      ),
    );

    if (isTab) {
      return Scaffold(
        backgroundColor: Colors.transparent, // Let Home handle background
        body: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: false,
      ),
      body: content,
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF001F33), Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Unlock the World of Premium",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Elevate your football experience,\nBecome a VIP Member Today.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white10,
                child: Icon(Icons.workspace_premium, color: Color(0xFFFF8700), size: 30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00BFA5)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF00BFA5),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color textColor,
    Color? iconColor,
    double? iconSize,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? const Color(0xFF00BFA5), size: iconSize),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
