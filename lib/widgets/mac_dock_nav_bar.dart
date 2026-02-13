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
    // Calculate the total width to ensure the background matches the Row
    final double totalIconWidth = widget.items.length * (_baseSize + 16.0);
    final double totalDockWidth = totalIconWidth + 20.0;

    return MouseRegion(
      onHover: (event) {
        setState(() {
          _hoveredIndex = event.localPosition.dx;
        });
      },
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. The Dock Shelf Background (Fixed height, does not grow)
          Container(
            width: totalDockWidth,
            height: _baseSize + 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withOpacity(0.4),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          
          // 2. The Icons Row (Floating above the shelf, allowed to overflow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
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
    final bool isLive = index == 2; // Index 2 is always "Live"
    
    // Calculate scaling factor based on PIXEL distance from mouse
    double scale = 1.0;
    const double pixelRange = 150.0;
    
    if (_hoveredIndex != null) {
      final double iconCenterX = 10.0 + (index * (_baseSize + 16)) + (_baseSize / 2);
      final double distance = (_hoveredIndex! - iconCenterX).abs();
      
      if (distance < pixelRange) {
        final double t = 1.0 - (distance / pixelRange);
        scale = 1.0 + (_maxScale - 1.0) * (t * t); 
      }
    }

    // Colors
    const Color accentColor = Color(0xFFFF8700);

    return GestureDetector(
      onTap: () => widget.onItemSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()
                ..scale(scale)
                ..translate(0.0, - (scale - 1.0) * 25 - (isLive ? 5 : 0)), // Live item always floats slightly
              width: _baseSize,
              height: _baseSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
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
                      onEnd: () {
                        setState(() {
                          _livePulseKey++;
                        });
                      },
                    ),
                  
                  // Icon
                  Icon(
                    item.icon,
                    size: isLive ? 24 : 28,
                    color: isLive 
                        ? Colors.white 
                        : (isSelected ? accentColor : Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2), // Reduced Gap
            // Active Indicator (Dot)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 4,
              height: 4,
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
            const SizedBox(height: 2),
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
