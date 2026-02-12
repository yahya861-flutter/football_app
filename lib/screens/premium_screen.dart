import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedOption = 0; // 0 for weekly, 1 for monthly

  @override
  Widget build(BuildContext context) {
    const Color mintColor = Color(0xFF00FF9D); // Mint/Neon green from screenshot
    const Color darkCardColor = Color(0xFF121212);

    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 700;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // Top Image with Back Button
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
                    top: 20,
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
                  // Bottom Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
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
      
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    "Go Premium",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 24),
          
                  // Features Card
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
                            Text(
                              "Get Access to",
                              style: TextStyle(
                                color: mintColor,
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: mintColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.sports_soccer, size: 16, color: Colors.black),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Explore Benefits",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 10 : 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 24),
                        _buildFeatureRow("Covering 2100+ leagues", mintColor, isSmallScreen),
                        _buildFeatureRow("Ads Free Version", mintColor, isSmallScreen),
                        _buildFeatureRow("Custom Match Alarm", mintColor, isSmallScreen),
                      ],
                    ),
                  ),
          
                  SizedBox(height: isSmallScreen ? 16 : 32),
          
                  // Subscription Options
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        _buildSubscriptionCard(
                          index: 0,
                          title: "Weekly",
                          price: "Rs 1,400/week",
                          mintColor: mintColor,
                          darkCardColor: darkCardColor,
                          badgeText: "50 % off",
                          isSmallScreen: isSmallScreen,
                        ),
                        const SizedBox(width: 16),
                        _buildSubscriptionCard(
                          index: 1,
                          title: "Monthly",
                          price: "Rs 4,200/month",
                          mintColor: mintColor,
                          darkCardColor: darkCardColor,
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ),
                  ),
          
                  SizedBox(height: isSmallScreen ? 16 : 32),
          
                  // Purchase Button
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mintColor,
                      minimumSize: Size(double.infinity, isSmallScreen ? 50 : 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Purchase Premium",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward, color: Colors.black),
                      ],
                    ),
                  ),
          
                  SizedBox(height: isSmallScreen ? 12 : 24),
          
                  // Terms & Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final Uri uri = Uri.parse("https://www.youtube.com/");
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            debugPrint('Could not launch YouTube URL');
                          }
                        },
                        child: Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: isSmallScreen ? 12 : 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        "Cancel any time",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 32),
                ],
              ),
            ),
          ],
        ),
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
                  SizedBox(height: isSmallScreen ? 4 : 8),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_soccer, size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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

  Widget _buildFeatureRow(String text, Color mintColor, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 16),
      child: Row(
        children: [
          Icon(Icons.check, color: mintColor, size: isSmallScreen ? 18 : 24),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
