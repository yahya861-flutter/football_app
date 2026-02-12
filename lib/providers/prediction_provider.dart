import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PredictionProvider with ChangeNotifier {
  dynamic _predictionData;
  bool _isLoading = false;
  String? _errorMessage;

  dynamic get predictionData => _predictionData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  Future<void> fetchPredictionDetails(int fixtureId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = 'https://api.sportmonks.com/v3/football/fixtures/$fixtureId?api_token=$_apiKey&include=league;participants;scores;periods;venue;lineups.player;formations;events.player;events.type;state;comments;statistics.type;predictions;pressure';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _predictionData = data['data'];
      } else {
        _errorMessage = 'Failed to load details: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to extract specific prediction percentages
  Map<String, String> getWinProbabilities() {
    if (_predictionData == null || _predictionData['predictions'] == null) {
      return {"home": "0%", "draw": "0%", "away": "0%"};
    }

    final predictions = _predictionData['predictions'];
    // Assuming predictions is an object or list with probability fields
    // Based on Sportmonks v3, it might be in different formats. 
    // Usually it's a list for different types. We'll look for 'win_draw_win' or similar.
    
    // Default fallback
    String home = "0%", draw = "0%", away = "0%";

    if (predictions is List && predictions.isNotEmpty) {
      // Find the correction prediction type (e.g. 'win_draw_win' if available)
      final winProb = predictions.firstWhere(
        (p) => p['type']?['name']?.toString().toLowerCase().contains('fulltime_result') ?? false,
        orElse: () => predictions[0]
      );
      
      if (winProb['predictions'] != null) {
        final pp = winProb['predictions'];
        home = "${(pp['home'] ?? 0).toString()}%";
        draw = "${(pp['draw'] ?? 0).toString()}%";
        away = "${(pp['away'] ?? 0).toString()}%";
      }
    }

    return {"home": home, "draw": draw, "away": away};
  }
}
