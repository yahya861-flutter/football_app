import 'dart:ui';
import 'package:flutter/material.dart';

class MacDockNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<MacDockItem> items;

  const MacDockNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  State<MacDockNavBar> createState() => _MacDockNavBarState();
}

class _MacDockNavBarState extends State<MacDockNavBar> {
  double? _hoveredIndex;
  int _livePulseKey = 0;
  
  // Animation settings
  static const double _baseSize = 48.0;
  static const double _maxScale = 1.5; // Slightly reduced for stability
  static const double _range = 2.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate the total width to ensure the background matches the Row
    // Increased spacing for larger icons
    final double totalIconWidth = widget.items.length * (_baseSize + 20.0);
    final double totalDockWidth = totalIconWidth + 24.0;

    return MouseRegion(
      onHover: (event) {
        setState(() {
          _hoveredIndex = event.localPosition.dx;
        });
      },
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Stack(
        alignment: Alignment.center, // Better vertical centering
        clipBehavior: Clip.none,
        children: [
          // 1. The Dock Shelf Background (Fixed height, does not grow)
          Container(
            width: totalDockWidth,
            height: _baseSize + 32, // More height for premium feel and breathing room
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: isDark 
                  ? Colors.black.withOpacity(0.4) 
                  : Colors.white.withOpacity(0.4),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.15) 
                    : Colors.black.withOpacity(0.1),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(31),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          
          // 2. The Icons Row (Floating above the shelf, allowed to overflow)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 20, bottom: 8), // Adjusted vertical balance
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, // Centered in the row
              children: List.generate(widget.items.length, (index) {
                return _buildDockItem(index);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem(int index) {
    final item = widget.items[index];
    final bool isSelected = widget.selectedIndex == index;
    final bool isLive = index == 2; 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate scaling factor based on PIXEL distance from mouse
    double scale = 1.0;
    const double pixelRange = 160.0;
    
    if (_hoveredIndex != null) {
      // Re-calculate center for pixel logic with new spacing
      final double iconCenterX = 12.0 + (index * (_baseSize + 20)) + (_baseSize / 2);
      final double distance = (_hoveredIndex! - iconCenterX).abs();
      
      if (distance < pixelRange) {
        final double t = 1.0 - (distance / pixelRange);
        scale = 1.0 + (_maxScale - 1.0) * (t * t); 
      }
    }

    // Eye-friendly, high-contrast accent colors
    final Color accentColor = isDark 
        ? const Color(0xFFFF8700) // Soft, radiant amber for dark mode
        : const Color(0xFFE67E22); // Rich, deep orange for light mode
    final Color iconColor = isLive 
        ? Colors.white 
        : (isSelected 
            ? accentColor 
            : (isDark ? Colors.white : Colors.black.withOpacity(0.75)));

    return GestureDetector(
      onTap: () => widget.onItemSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()
                ..scale(scale)
                ..translate(0.0, - (scale - 1.0) * 30 - (isLive ? 5 : 0)),
              width: _baseSize,
              height: _baseSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                   // Subtle glow for selected regular icons
                  if (isSelected && !isLive)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                  // Special background for Live item with pulse
                  if (isLive)
                    TweenAnimationBuilder<double>(
                      key: ValueKey(_livePulseKey),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        final pulseFactor = (value < 0.5 ? value * 2 : (1.0 - value) * 2);
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8700), Color(0xFFFF4500)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.4 + (pulseFactor * 0.3)),
                                blurRadius: 12 + (pulseFactor * 8),
                                spreadRadius: 1 + (pulseFactor * 3),
                              ),
                            ],
                          ),
                        );
                      },
                      onEnd: () => setState(() => _livePulseKey++),
                    ),
                  
                  // Icon (Increased size to 34)
                  Icon(
                    item.icon,
                    size: isLive ? 26 : 34,
                    color: iconColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Active Indicator (Dot)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.8),
                    blurRadius: 4,
                  )
                ] : null,
              ),
            ),
            const SizedBox(height: 6), // Lifted dot further from border
          ],
        ),
      ),
    );
  }
}

class MacDockItem {
  final IconData icon;
  final String label;

  MacDockItem({required this.icon, required this.label});
}
