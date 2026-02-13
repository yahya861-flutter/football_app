import 'package:flutter/material.dart';

class NotificationsActivatedDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final List<NotificationEvent>? events;
  final IconData? mainIcon;
  final Color? iconColor;

  const NotificationsActivatedDialog({
    super.key,
    this.title,
    this.message,
    this.events,
    this.mainIcon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final Color accentColor = const Color(0xFF48C9B0);

    final String displayTitle = title ?? "Notifications On";
    final IconData displayIcon = mainIcon ?? Icons.notifications_active_rounded;
    final Color displayIconColor = iconColor ?? accentColor;

    final List<NotificationEvent> displayEvents = events ?? [
      NotificationEvent("Goals", Icons.sports_soccer, Colors.orange),
      NotificationEvent("Cards", Icons.square, Colors.red),
      NotificationEvent("Live", Icons.timer_outlined, Colors.blue),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: displayIconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(displayIcon, color: displayIconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayTitle,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (message != null) ...[
              Text(
                message!,
                textAlign: TextAlign.start,
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayEvents.map((e) => _buildCompactChip(e, isDark)).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: displayIconColor.withOpacity(0.1),
                  foregroundColor: displayIconColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactChip(NotificationEvent event, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(event.icon, size: 12, color: event.color),
          const SizedBox(width: 6),
          Text(
            event.label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class NotificationEvent {
  final String label;
  final IconData icon;
  final Color color;

  NotificationEvent(this.label, this.icon, this.color);
}
