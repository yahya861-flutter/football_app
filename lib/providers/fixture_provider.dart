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

      String? nextUrl = 'https://api.sportmonks.com/v3/football/fixtures/between/$startDateFormatted/$endDateFormatted?api_token=$_apiKey&filters=fixtureLeagues:$leagueId&include=participants;scores;venue;league';
      
      while (nextUrl != null) {
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> pageFixtures = data['data'] ?? [];
          
          // Filter out finished matches for the Fixtures tab
          _fixtures.addAll(pageFixtures.where((f) => f['state_id'] != 5));
          
          final pagination = data['pagination'];
          if (pagination != null && pagination['has_more'] == true) {
            nextUrl = pagination['next_page'];
          } else {
            nextUrl = null;
          }
        } else {
          _errorMessage = 'Failed to load fixtures: ${response.statusCode}';
          break;
        }
      }
      
      // Sort by date (ascending for upcoming fixtures)
      _fixtures.sort((a, b) => a['starting_at'].compareTo(b['starting_at']));
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

      String? nextUrl = 'https://api.sportmonks.com/v3/football/fixtures/between/$startDateFormatted/$endDateFormatted?api_token=$_apiKey&include=participants;scores;venue;league';
      
      while (nextUrl != null) {
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> pageFixtures = data['data'] ?? [];
          
          _fixtures.addAll(pageFixtures.where((f) => f['state_id'] != 5));

          final pagination = data['pagination'];
          if (pagination != null && pagination['has_more'] == true) {
            nextUrl = pagination['next_page'];
          } else {
            nextUrl = null;
          }
        } else {
          _errorMessage = 'Failed to load global fixtures: ${response.statusCode}';
          break;
        }
      }
      _fixtures.sort((a, b) => a['starting_at'].compareTo(b['starting_at']));
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

      String? nextUrl = 'https://api.sportmonks.com/v3/football/fixtures/date/$dateFormatted?api_token=$_apiKey&include=participants;scores;venue;league;state';
      
      while (nextUrl != null) {
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> pageFixtures = data['data'] ?? [];
          _todayFixtures.addAll(pageFixtures);

          final pagination = data['pagination'];
          if (pagination != null && pagination['has_more'] == true) {
            nextUrl = pagination['next_page'];
          } else {
            nextUrl = null;
          }
        } else {
          _errorMessage = 'Failed to load today\'s matches: ${response.statusCode}';
          break;
        }
      }
      
      // Sort by starting time
      _todayFixtures.sort((a, b) => a['starting_at'].compareTo(b['starting_at']));
    } catch (e) {
      _errorMessage = 'An error occurred fetching today\'s matches: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches ALL fixtures for a specific date across all leagues
  Future<void> fetchFixturesByDate(DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    _todayFixtures = []; // We reuse this list for the current selected date view
    notifyListeners();

    try {
      final dateFormatted = DateFormat('yyyy-MM-dd').format(date);

      String? nextUrl = 'https://api.sportmonks.com/v3/football/fixtures/date/$dateFormatted?api_token=$_apiKey&include=participants;scores;venue;league;state';
      
      while (nextUrl != null) {
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> pageFixtures = data['data'] ?? [];
          _todayFixtures.addAll(pageFixtures);

          final pagination = data['pagination'];
          if (pagination != null && pagination['has_more'] == true) {
            nextUrl = pagination['next_page'];
          } else {
            nextUrl = null;
          }
        } else {
          _errorMessage = 'Failed to load matches for $dateFormatted: ${response.statusCode}';
          break;
        }
      }
      _todayFixtures.sort((a, b) => a['starting_at'].compareTo(b['starting_at']));
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
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

      String? nextUrl = 'https://api.sportmonks.com/v3/football/fixtures/between/$startDateFormatted/$endDateFormatted?api_token=$_apiKey&filters=fixtureLeagues:$leagueId&include=participants;scores;venue';
      
      while (nextUrl != null) {
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> pageFixtures = data['data'] ?? [];
          
          // Filter for finished matches (state_id 5)
          _results.addAll(pageFixtures.where((f) => f['state_id'] == 5));

          final pagination = data['pagination'];
          if (pagination != null && pagination['has_more'] == true) {
            nextUrl = pagination['next_page'];
          } else {
            nextUrl = null;
          }
        } else {
          _errorMessage = 'Failed to load results: ${response.statusCode}';
          break;
        }
      }
      
      // Sort by date (descending, most recent results first)
      _results.sort((a, b) => b['starting_at'].compareTo(a['starting_at']));
      
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
