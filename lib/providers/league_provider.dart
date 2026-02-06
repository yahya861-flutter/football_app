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

  // Store the details of a specific selected league
  dynamic _selectedLeague;

  // Store the top scorers for the current season
  List<dynamic> _topScorers = [];

  // Store the standings for the current season
  List<dynamic> _standings = [];

  // Getters to expose the private state variables to the UI
  List<dynamic> get leagues => _leagues;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  dynamic get selectedLeague => _selectedLeague;
  List<dynamic> get topScorers => _topScorers;
  List<dynamic> get standings => _standings;

  /// Returns the list of teams for the currently selected league
  /// Extracted from the current season included in the API response
  List<dynamic> get teams {
    if (_selectedLeague != null && _selectedLeague['currentseason'] != null) {
      return _selectedLeague['currentseason']['teams'] ?? [];
    }
    return [];
  }

  /// Returns the current season ID for the selected league
  int? get currentSeasonId {
    if (_selectedLeague != null && _selectedLeague['currentseason'] != null) {
      return _selectedLeague['currentseason']['id'];
    }
    return null;
  }

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

  /// Fetches detailed information for a single league by its unique ID
  Future<void> fetchLeagueById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedLeague = null; // Clear previous selection
    notifyListeners();

    try {
      final response = await http.get(
        // Include currentSeason and its teams to show them in the Home tab
        Uri.parse('$_baseUrl/$id?include=currentSeason.teams'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The individual league data is inside the 'data' key
        _selectedLeague = data['data'];
      } else {
        _errorMessage = 'Failed to load league details: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while fetching league details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the top scorers for a specific season
  Future<void> fetchTopScorers(int seasonId) async {
    _isLoading = true;
    _errorMessage = null;
    _topScorers = [];
    notifyListeners();

    try {
      final response = await http.get(
        // Include player and team (participant) details
        Uri.parse('https://api.sportmonks.com/v3/football/topscorers/seasons/$seasonId?include=player;participant'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _topScorers = data['data'] ?? [];
      } else {
        _errorMessage = 'Failed to load top scorers: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while fetching top scorers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the standings for a specific season
  Future<void> fetchStandings(int seasonId) async {
    _isLoading = true;
    _errorMessage = null;
    _standings = [];
    notifyListeners();

    try {
      final response = await http.get(
        // Include participant details (team name, logo)
        Uri.parse('https://api.sportmonks.com/v3/football/standings/seasons/$seasonId?include=participant'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _apiKey,
        },
      );
      print("Status Response: ${response.statusCode}");
      print("Status Body:${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _standings = data['data'] ?? [];
      } else {
        _errorMessage = 'Failed to load standings: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while fetching standings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
