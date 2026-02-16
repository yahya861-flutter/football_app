import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:football_app/providers/language_provider.dart';
import 'package:football_app/screens/home.dart';
import 'package:football_app/screens/language_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _tickerController;
  int _currentFeatureIndex = 0;
  final List<String> _features = [
    'Live Football Scores',
    'League Standings & Tables',
    'Match Statistics & H2H',
    'Team & Player Details',
    'Match Notifications & Alarms',
  ];

  late final Timer _featureTimer;

  @override
  void initState() {
    super.initState();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _featureTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _currentFeatureIndex = (_currentFeatureIndex + 1) % _features.length;
        });
        _tickerController.forward(from: 0.0);
      }
    });

    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 10));
    if (!mounted) return;

    final languageProvider = context.read<LanguageProvider>();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => languageProvider.isFirstTime
            ? const LanguageScreen(isFirstTime: true)
            : const Home(),
      ),
    );
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _featureTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.black : const Color(0xFF121212);
    const Color accentColor = Color(0xFFFF8700);

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          // Central Default Flutter Icon
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FlutterLogo(size: 100),
                const SizedBox(height: 24),
                Text(
                  "Football Pro",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Section
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Moving Feature Strip (Pati)
                  Container(
                    width: double.infinity,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        final offsetAnimation = Tween<Offset>(
                          begin: const Offset(0.0, -1.0),
                          end: const Offset(0.0, 0.0),
                        ).animate(animation);
                        return ClipRect(
                          child: SlideTransition(
                            position: offsetAnimation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        _features[_currentFeatureIndex],
                        key: ValueKey<int>(_currentFeatureIndex),
                        style: const TextStyle(
                          color: accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Loading Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.white10,
                        color: accentColor,
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
