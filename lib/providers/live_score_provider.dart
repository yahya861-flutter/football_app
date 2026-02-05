import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LiveScoreProvider with ChangeNotifier {
  List<dynamic> _liveScores = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get liveScores => _liveScores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _baseUrl = 'https://api.sportmonks.com/v3/football/livescores';
  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  Future<void> fetchLiveScores() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _liveScores = data['data'] ?? [];
      } else {
        _errorMessage = 'Failed to load live scores: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
