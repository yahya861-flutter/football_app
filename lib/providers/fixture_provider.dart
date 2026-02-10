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
    if (_isLoading) return;
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
          for (var fixture in pageFixtures) {
            if (fixture['state_id'] != 5 && !_inFixtures(fixture['id'])) {
              _fixtures.add(fixture);
            }
          }
          
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
      
      _fixtures.sort((a, b) => a['starting_at'].compareTo(b['starting_at']));
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllFixturesByDateRange() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _fixtures = [];
    notifyListeners();

    try {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 3));
      
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
          for (var fixture in pageFixtures) {
            if (fixture['state_id'] != 5 && !_inFixtures(fixture['id'])) {
              _fixtures.add(fixture);
            }
          }

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

  Future<void> fetchTodayFixtures() async {
    if (_isLoading) return;
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
          for (var fixture in pageFixtures) {
            if (!_inTodayFixtures(fixture['id'])) {
              _todayFixtures.add(fixture);
            }
          }

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
      
      _todayFixtures.sort((a, b) => a['starting_at'].compareTo(b['starting_at']));
    } catch (e) {
      _errorMessage = 'An error occurred fetching today\'s matches: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFixturesByDate(DateTime date) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _todayFixtures = [];
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
          for (var fixture in pageFixtures) {
            if (!_inTodayFixtures(fixture['id'])) {
              _todayFixtures.add(fixture);
            }
          }

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

  Future<void> fetchResultsByLeague(int leagueId) async {
    if (_isLoading) return;
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
          for (var fixture in pageFixtures) {
            if (fixture['state_id'] == 5 && !_inResults(fixture['id'])) {
              _results.add(fixture);
            }
          }

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
      _results.sort((a, b) => b['starting_at'].compareTo(a['starting_at']));
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _inFixtures(int id) => _fixtures.any((f) => f['id'] == id);
  bool _inTodayFixtures(int id) => _todayFixtures.any((f) => f['id'] == id);
  bool _inResults(int id) => _results.any((f) => f['id'] == id);
}
