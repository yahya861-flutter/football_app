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

  // Store the live leagues (leagues with active matches)
  List<dynamic> _liveLeagues = [];

  // Getters to expose the private state variables to the UI
  List<dynamic> get leagues => _leagues;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  dynamic get selectedLeague => _selectedLeague;
  List<dynamic> get topScorers => _topScorers;
  List<dynamic> get standings => _standings;
  List<dynamic> get liveLeagues => _liveLeagues;

  // Pagination state
  String? _nextUrl;
  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _nextUrl != null;

  /// Returns leagues categorized as 'Top Leagues' (Category 1)
  List<dynamic> get topLeagues => _leagues.where((l) => l['category'] == 1).toList();

  /// Groups leagues by country for the "All Leagues" section
  Map<String, List<dynamic>> get leaguesByCountry {
    Map<String, List<dynamic>> groups = {};
    for (var league in _leagues) {
      final countryName = league['country']?['name'] ?? 'International';
      if (!groups.containsKey(countryName)) {
        groups[countryName] = [];
      }
      groups[countryName]!.add(league);
    }
    return groups;
  }

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

  /// Fetches the first page of football leagues and then loads the rest in the background
  Future<void> fetchLeagues() async {
    _isLoading = true;
    _errorMessage = null;
    _leagues = [];
    _nextUrl = null;
    notifyListeners();

    try {
      // Increase per_page to load more data faster
      final String firstPageUrl = '$_baseUrl?include=country&per_page=50&api_token=$_apiKey';
      final response = await http.get(Uri.parse(firstPageUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _leagues = data['data'] ?? [];
        
        // Find next page
        final pagination = data['pagination'];
        if (pagination != null && pagination['has_more'] == true) {
          _nextUrl = pagination['next_page'];
          if (_nextUrl != null && !_nextUrl!.contains('api_token=')) {
            _nextUrl = _nextUrl! + (_nextUrl!.contains('?') ? '&' : '?') + 'api_token=$_apiKey';
          }
        }
        
        // KEY: Set loading to false after the first page so the UI is usable immediately
        _isLoading = false;
        notifyListeners();

        // Continue loading the rest in the background without blocking the UI
        if (_nextUrl != null) {
          _loadRemainingPages();
        }
      } else {
        _isLoading = false;
        _errorMessage = 'Failed to load leagues: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred while fetching leagues: $e';
      notifyListeners();
    }
  }

  /// Private helper to load all remaining pages in the background
  Future<void> _loadRemainingPages() async {
    while (_nextUrl != null) {
      try {
        final response = await http.get(Uri.parse(_nextUrl!));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> newLeagues = data['data'] ?? [];
          _leagues.addAll(newLeagues);
          
          // Update next URL
          final pagination = data['pagination'];
          if (pagination != null && pagination['has_more'] == true) {
            _nextUrl = pagination['next_page'];
            if (_nextUrl != null && !_nextUrl!.contains('api_token=')) {
              _nextUrl = _nextUrl! + (_nextUrl!.contains('?') ? '&' : '?') + 'api_token=$_apiKey';
            }
          } else {
            _nextUrl = null;
          }
          
          // Notify listeners so UI updates with new data (new countries/leagues appearing)
          notifyListeners();
        } else {
          break; // Stop on error
        }
      } catch (e) {
        break; // Stop on error
      }
    }
  }

  /// Keep this for compatibility, but fetchLeagues now handles background loading
  Future<void> loadMoreLeagues() async {
    // This is now handled automatically by _loadRemainingPages in the background
    // but we can keep the logic if needed for manual triggers
    if (_isFetchingMore || _nextUrl == null) return;
    _isFetchingMore = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(_nextUrl!));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newLeagues = data['data'] ?? [];
        _leagues.addAll(newLeagues);
        final pagination = data['pagination'];
        if (pagination != null && pagination['has_more'] == true) {
          _nextUrl = pagination['next_page'];
          if (_nextUrl != null && !_nextUrl!.contains('api_token=')) {
            _nextUrl = _nextUrl! + (_nextUrl!.contains('?') ? '&' : '?') + 'api_token=$_apiKey';
          }
        } else {
          _nextUrl = null;
        }
      }
    } finally {
      _isFetchingMore = false;
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

  /// Fetches the list of leagues that currently have live matches
  Future<void> fetchLiveLeagues() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/live'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _liveLeagues = data['data'] ?? [];
      } else {
        _errorMessage = 'Failed to load live leagues: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while fetching live leagues: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns true if the given league ID is currently live
  bool isLeagueLive(int leagueId) {
    return _liveLeagues.any((league) => league['id'] == leagueId);
  }
}
