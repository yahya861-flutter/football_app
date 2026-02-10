import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// This provider is responsible for fetching and managing real-time "In-Play" match data.
/// It hits the SportMonks livescores/inplay endpoint to get status for ongoing matches.
class MatchProvider with ChangeNotifier {
  // Store the list of matches currently in progress
  List<dynamic> _inPlayMatches = [];
  
  // Track loading state
  bool _isLoading = false;
  
  // Error message storage
  String? _errorMessage;

  // Public getters for the UI to consume
  List<dynamic> get inPlayMatches => _inPlayMatches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Base configuration for SportMonks API
  final String _baseUrl = 'https://api.sportmonks.com/v3/football/livescores/inplay';
  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  /// Fetches all matches that are currently in-play across all leagues
  Future<void> fetchInPlayMatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? nextUrl = _baseUrl;
      
      while (nextUrl != null) {
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': _apiKey,
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> pageMatches = data['data'] ?? [];
          _inPlayMatches.addAll(pageMatches);

          final pagination = data['pagination'];
          if (pagination != null && pagination['has_more'] == true) {
            nextUrl = pagination['next_page'];
          } else {
            nextUrl = null;
          }
        } else {
          _errorMessage = 'Failed to fetch in-play matches: ${response.statusCode}';
          break;
        }
      }
    } catch (e) {
      _errorMessage = 'Network error fetching live scores: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
