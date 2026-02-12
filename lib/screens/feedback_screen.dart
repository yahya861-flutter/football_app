import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _detailsController = TextEditingController();
  String? _selectedProblem;

  final List<String> _problems = [
    "Alerts not working",
    "Live score not refreshing",
    "Function disabled",
    "App not responding",
    "Crash",
    "Ads",
    "Other",
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color mintColor = Color(0xFF48C9B0);
    const Color darkBg = Color(0xFF131321);
    const Color cardBg = Color(0xFF1E1E2C);

    return Scaffold(
      backgroundColor: darkBg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Feedback",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "What type of problem are you facing?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: _problems.map((problem) {
                  final bool isSelected = _selectedProblem == problem;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedProblem = problem;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? mintColor : cardBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        problem,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              const Text(
                "Details",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _detailsController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Share your thoughts",
                    hintStyle: TextStyle(color: Colors.white24),
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 100), // Space for button at bottom
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedProblem == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a problem type")),
                    );
                    return;
                  }
                  // Implementation for submission
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Feedback submitted successfully!"),
                      backgroundColor: mintColor,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mintColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
