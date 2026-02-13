import 'package:flutter/material.dart';
import 'package:football_app/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class MatchNotificationDialog extends StatefulWidget {
  final int matchId;
  final String matchTitle;
  final DateTime startTime;

  const MatchNotificationDialog({
    super.key,
    required this.matchId,
    required this.matchTitle,
    required this.startTime,
  });

  @override
  State<MatchNotificationDialog> createState() => _MatchNotificationDialogState();
}

class _MatchNotificationDialogState extends State<MatchNotificationDialog> {
  bool _notifyBeforeMatch = false;
  int _hours = 0;
  int _minutes = 0;
  bool _notifyAtStart = false;
  bool _notifyAtFullTime = false;

  final Color _mintColor = const Color(0xFF48C9B0);

  @override
  void initState() {
    super.initState();
    
    // Load existing settings
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final settings = provider.getSettings(widget.matchId);
    _notifyBeforeMatch = settings.notifyBeforeMatch;
    _hours = settings.beforeMatchMinutes ~/ 60;
    _minutes = settings.beforeMatchMinutes % 60;
    _notifyAtStart = settings.notifyAtStart;
    _notifyAtFullTime = settings.notifyAtFullTime;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
              child: Text(
                "Match Notifications",
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTriggerRow(
                      "Before match reminder",
                      _notifyBeforeMatch,
                      (val) => setState(() => _notifyBeforeMatch = val!),
                      textColor,
                    ),
                    if (_notifyBeforeMatch) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeBox("Hours", _hours, (val) => setState(() => _hours = val), isDark, textColor, subTextColor),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          _buildTimeBox("Minutes", _minutes, (val) => setState(() => _minutes = val), isDark, textColor, subTextColor),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildTriggerRow(
                      "At the start of match",
                      _notifyAtStart,
                      (val) => setState(() => _notifyAtStart = val!),
                      textColor,
                    ),
                    const SizedBox(height: 24),
                    _buildTriggerRow(
                      "Full Time Result",
                      _notifyAtFullTime,
                      (val) => setState(() => _notifyAtFullTime = val!),
                      textColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Get notified automatically for these match events.",
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mintColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTriggerRow(String label, bool value, Function(bool?) onChanged, Color textColor, {bool enabled = true}) {
    final Color activeText = enabled ? textColor : (textColor.withOpacity(0.4));
    final Color activeSide = enabled ? textColor.withOpacity(0.3) : (textColor.withOpacity(0.15));

    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: _mintColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide(color: activeSide, width: 1.5),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: activeText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBox(String label, int value, Function(int) onUpdate, bool isDark, Color textColor, Color subTextColor) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onUpdate,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: label == "Hours" ? 24 : 60,
              builder: (context, index) {
                return Center(
                  child: Text(
                    index.toString(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: subTextColor, fontSize: 10)),
      ],
    );
  }

  void _handleSave() {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final settings = MatchNotificationSettings(
      matchId: widget.matchId,
      notifyBeforeMatch: _notifyBeforeMatch,
      beforeMatchMinutes: (_hours * 60) + _minutes,
      notifyAtStart: _notifyAtStart,
      notifyAtFullTime: _notifyAtFullTime,
    );

    provider.updateSettings(widget.matchId, settings, widget.startTime, widget.matchTitle);
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(settings.isActive 
          ? "Notifications set for ${widget.matchTitle}" 
          : "Notifications removed for ${widget.matchTitle}"),
        backgroundColor: settings.isActive ? _mintColor : Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context);
  }
}
