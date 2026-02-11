import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatelessWidget {
  final bool isTab;
  const SettingsScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    
    // Theme aware colors
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black87;
    final Color sectionColor = isDark ? Colors.white38 : Colors.black38;
    final Color cardColor = isDark ? const Color(0xFF2D2D44) : Colors.grey[200]!;

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
          _buildActionTile(icon: Icons.share, title: "Share", textColor: textColor),
          _buildActionTile(icon: Icons.star_border, title: "Rate Us", textColor: textColor),
          _buildActionTile(icon: Icons.feedback_outlined, title: "Feedback", textColor: textColor),
          _buildActionTile(icon: Icons.verified_user_outlined, title: "Privacy Policy", textColor: textColor),
          const SizedBox(height: 16),
          _buildActionTile(
            icon: Icons.notifications_active,
            title: "Test Notification",
            textColor: textColor,
            onTap: () {
              context.read<NotificationProvider>().showTestNotification();
            },
          ),
          _buildActionTile(
            icon: Icons.timer,
            title: "Test Scheduled Alarm (10s)",
            textColor: textColor,
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
            icon: Icons.notification_important,
            title: "Test Scheduled Notification (10s)",
            textColor: textColor,
            onTap: () {
              context.read<NotificationProvider>().scheduleTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Standard Notification scheduled for 10 seconds..."),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00BFA5)),
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
