import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class FixtureProvider with ChangeNotifier {
  List<dynamic> _fixtures = [];
  List<dynamic> _todayFixtures = [];
  List<dynamic> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get fixtures => _fixtures;
  List<dynamic> get todayFixtures => _todayFixtures;
  List<dynamic> get results => _results;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  Future<void> fetchFixturesByDateRange(int leagueId) async {
    _isLoading = true;
    _errorMessage = null;
    _fixtures = [];
    notifyListeners();

    try {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 15));
      
      final startDateFormatted = DateFormat('yyyy-MM-dd').format(now);
      final endDateFormatted = DateFormat('yyyy-MM-dd').format(futureDate);

      // Using the correct SportMonks v3 filtering syntax and includes
      final url = 'https://api.sportmonks.com/v3/football/fixtures/between/$startDateFormatted/$endDateFormatted?api_token=$_apiKey&filters=fixtureLeagues:$leagueId&include=participants;scores;venue;league';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allFixtures = data['data'] ?? [];
        
        // Filter out finished matches for the Fixtures tab
        _fixtures = allFixtures.where((f) => f['state_id'] != 5).toList();
        
        // Sort by date (ascending for upcoming fixtures)
        _fixtures.sort((a, b) => a['starting_at'].compareTo(b['starting_at']));
        
      } else {
        _errorMessage = 'Failed to load fixtures: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches upcoming fixtures for ALL leagues (global)
  Future<void> fetchAllFixturesByDateRange() async {
    _isLoading = true;
    _errorMessage = null;
    _fixtures = [];
    notifyListeners();

    try {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 3)); // Smaller range for global to avoid huge data
      
      final startDateFormatted = DateFormat('yyyy-MM-dd').format(now);
      final endDateFormatted = DateFormat('yyyy-MM-dd').format(futureDate);

      // No league filter for global view
      final url = 'https://api.sportmonks.com/v3/football/fixtures/between/$startDateFormatted/$endDateFormatted?api_token=$_apiKey&include=participants;scores;venue;league';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allFixtures = data['data'] ?? [];
        
        _fixtures = allFixtures.where((f) => f['state_id'] != 5).toList();
        _fixtures.sort((a, b) => a['starting_at'].compareTo(b['starting_at']));
      } else {
        _errorMessage = 'Failed to load global fixtures: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches ALL fixtures (scheduled, live, finished) for today
  Future<void> fetchTodayFixtures() async {
    _isLoading = true;
    _errorMessage = null;
    _todayFixtures = [];
    notifyListeners();

    try {
      final now = DateTime.now();
      final dateFormatted = DateFormat('yyyy-MM-dd').format(now);

      // Fetch all matches for today across all leagues
      final url = 'https://api.sportmonks.com/v3/football/fixtures/between/$dateFormatted/$dateFormatted?api_token=$_apiKey&include=participants;scores;venue;league;state';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _todayFixtures = data['data'] ?? [];
        
        // Sort by starting time
        _todayFixtures.sort((a, b) => a['starting_at'].compareTo(b['starting_at']));
      } else {
        _errorMessage = 'Failed to load today\'s matches: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred fetching today\'s matches: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches all finished matches (results) for a specific league
  Future<void> fetchResultsByLeague(int leagueId) async {
    _isLoading = true;
    _errorMessage = null;
    _results = [];
    notifyListeners();

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      final startDateFormatted = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
      final endDateFormatted = DateFormat('yyyy-MM-dd').format(now);

      // Using the correct SportMonks v3 filtering syntax with date range for last month
      final url = 'https://api.sportmonks.com/v3/football/fixtures/between/$startDateFormatted/$endDateFormatted?api_token=$_apiKey&filters=fixtureLeagues:$leagueId&include=participants;scores;venue';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allFixtures = data['data'] ?? [];
        
        // Filter for finished matches (state_id 5)
        _results = allFixtures.where((f) => f['state_id'] == 5).toList();
        
        // Sort by date (descending, most recent results first)
        _results.sort((a, b) => b['starting_at'].compareTo(a['starting_at']));
        
      } else {
        _errorMessage = 'Failed to load results: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
