import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// This provider handles all data fetching and state management for Football Leagues
/// It uses the SportMonks v3 API to retrieve league information.
class LeagueProvider with ChangeNotifier {
  // Store the list of leagues retrieved from the API
  List<dynamic> _leagues = [];
  
  // Track the loading state to show/hide progress indicators in the UI
  bool _isLoading = false;
  
  // Store any error messages that occur during the API call
  String? _errorMessage;

  // Getters to expose the private state variables to the UI
  List<dynamic> get leagues => _leagues;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // API Configuration
  final String _baseUrl = 'https://api.sportmonks.com/v3/football/leagues';
  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  /// Fetches the list of football leagues from the SportMonks API
  Future<void> fetchLeagues() async {
    _isLoading = true;
    _errorMessage = null;
    
    // Notify the UI to show the loading spinner
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

      // Check if the request was successful (HTTP status 200)
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract the 'data' array from the JSON response
        _leagues = data['data'] ?? [];
      } else {
        // Handle server-side errors
        _errorMessage = 'Failed to load leagues: ${response.statusCode}';
      }
    } catch (e) {
      // Handle network or parsing errors
      _errorMessage = 'An error occurred while fetching leagues: $e';
    } finally {
      // Data fetching is complete, either successfully or with an error
      _isLoading = false;
      
      // Notify the UI to rebuild with the new data or error message
      notifyListeners();
    }
  }
}
