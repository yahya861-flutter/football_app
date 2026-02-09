import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InPlayProvider with ChangeNotifier {
  List<dynamic> _inPlayMatches = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get inPlayMatches => _inPlayMatches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _baseUrl = 'https://api.sportmonks.com/v3/football/livescores/inplay';
  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  Future<void> fetchInPlayMatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Include league for grouping, participants for names/logos, scores for live results, and state for periods/minutes
      final url = '$_baseUrl?include=league;participants;scores;state';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _inPlayMatches = data['data'] ?? [];
      } else {
        _errorMessage = 'Failed to load in-play matches: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while fetching in-play matches: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
