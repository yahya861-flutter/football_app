import 'package:flutter/material.dart';
import 'package:football_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedOption = 1; // 1 for monthly (most popular), 0 for weekly

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mintColor = const Color(0xFF00FF9D); // Reference color
    final Color darkCardColor = const Color(0xFF121212);
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Top Image Section
          Expanded(
            flex: isSmallScreen ? 2 : 3,
            child: Stack(
              children: [
                Image.asset(
                  'lib/assets/images/footbal.jpg',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 20 + MediaQuery.of(context).padding.top,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  l10n.premium,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 24 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 24),

                // Features
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  decoration: BoxDecoration(
                    color: darkCardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n.premiumSubtitle,
                              style: TextStyle(
                                color: mintColor,
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 20),
                      _buildFeatureRow(l10n.adFreeExperience, mintColor, isSmallScreen),
                      _buildFeatureRow(l10n.unlimitedAlerts, mintColor, isSmallScreen),
                      _buildFeatureRow(l10n.detailedStats, mintColor, isSmallScreen),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 32),

                // Options
                IntrinsicHeight(
                  child: Row(
                    children: [
                      _buildSubscriptionCard(
                        index: 0,
                        title: l10n.weekly,
                        price: "\$1.99/${l10n.week}",
                        mintColor: mintColor,
                        darkCardColor: darkCardColor,
                        isSmallScreen: isSmallScreen,
                      ),
                      const SizedBox(width: 12),
                      _buildSubscriptionCard(
                        index: 1,
                        title: l10n.monthly,
                        price: "\$4.99/${l10n.month}",
                        mintColor: mintColor,
                        darkCardColor: darkCardColor,
                        isSmallScreen: isSmallScreen,
                        badgeText: l10n.mostPopular,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 32),

                // Subscribe Button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mintColor,
                    minimumSize: Size(double.infinity, isSmallScreen ? 50 : 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.subscribeNow,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 20 : 32),

                // Policies
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPolicyLink(l10n.privacyPolicy, "https://example.com/privacy", isSmallScreen),
                    const SizedBox(width: 24),
                    _buildPolicyLink(l10n.termsOfService, "https://example.com/terms", isSmallScreen),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required int index,
    required String title,
    required String price,
    required Color mintColor,
    required Color darkCardColor,
    required bool isSmallScreen,
    String? badgeText,
  }) {
    final isSelected = _selectedOption == index;
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedOption = index),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 24, horizontal: 8),
              decoration: BoxDecoration(
                color: darkCardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? mintColor : Colors.white10,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 14 : 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (badgeText != null)
            Positioned(
              top: -10,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text, Color mintColor, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: mintColor, size: isSmallScreen ? 18 : 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 13 : 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyLink(String text, String url, bool isSmallScreen) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white38,
          fontSize: isSmallScreen ? 12 : 13,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
