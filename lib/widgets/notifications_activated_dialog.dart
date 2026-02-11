import 'package:flutter/material.dart';

class NotificationsActivatedDialog extends StatelessWidget {
  const NotificationsActivatedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white54 : Colors.grey[600]!;
    final Color accentColor = const Color(0xFF48C9B0); // Greenish color from screenshot

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Close Button
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 20, color: textColor),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Title
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Notifications Activated",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.check_circle, color: accentColor, size: 24),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  "Notifications for the following events have been activated",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // Events List
                _buildEventItem("Match Highlights", subTextColor),
                _buildEventItem("Goals", subTextColor),
                _buildEventItem("Yellow Cards", subTextColor),
                _buildEventItem("Red Cards", subTextColor),
                _buildEventItem("Half-Time", subTextColor),
                _buildEventItem("Full-Time", subTextColor),
                _buildEventItem("Substitutions", subTextColor),
                const SizedBox(height: 24),
                // Divider
                Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
                const SizedBox(height: 16),
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text("• ", style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
