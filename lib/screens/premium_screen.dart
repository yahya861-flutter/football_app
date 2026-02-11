import 'package:flutter/material.dart';

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

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Top Image with Back Button
              Stack(
                children: [
                  Image.asset(
                    'lib/assets/images/footbal.jpg',
                    width: double.infinity,
                    height: 350,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 50,
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
                  // Bottom Gradient Overlay for fading into black
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
      
              const SizedBox(height: 10),
              const Text(
                "Go Premium",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
      
              // Features Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
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
                        const Text(
                          "Get Access to",
                          style: TextStyle(
                            color: mintColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: mintColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.sports_soccer, size: 16, color: Colors.black),
                              SizedBox(width: 4),
                              Text(
                                "Exp",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureRow("Covering 2100+ leagues", mintColor),
                    _buildFeatureRow("Ads Free Version", mintColor),
                    _buildFeatureRow("Custom Match Alarm", mintColor),
                    _buildFeatureRow("Winning Probability", mintColor),
                  ],
                ),
              ),
      
              const SizedBox(height: 32),
      
              // Subscription Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Weekly Option
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _selectedOption = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: darkCardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedOption == 0 ? mintColor : Colors.white10,
                                  width: 2,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Text(
                                    "Weekly",
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Rs 1,400/week",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 50% Off Badge
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
                              child: const Row(
                                children: [
                                  Icon(Icons.sports_soccer, size: 14, color: Colors.black),
                                  SizedBox(width: 4),
                                  Text(
                                    "50 % off",
                                    style: TextStyle(
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
                    ),
                    const SizedBox(width: 16),
                    // Monthly Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedOption = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: darkCardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedOption == 1 ? mintColor : Colors.white10,
                              width: 2,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                "Monthly",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Rs 4,200/month",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      
              const SizedBox(height: 32),
      
              // Purchase Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement purchase logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mintColor,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Purchase Premium",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward, color: Colors.black),
                    ],
                  ),
                ),
              ),
      
              const SizedBox(height: 24),
      
              // Terms Text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Payment will be charged from your Google Play account. Subscription automatically renews unless it is cancelled at least 24 hours before the end of current period. Your account will be charged for renewal within 24 hours prior to the end of current period. You can manage and cancel your subscription at any time from the Google Play store.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text, Color mintColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.check, color: mintColor, size: 24),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
