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

  // Store live standings
  List<dynamic> _liveStandings = [];

  // Getters to expose the private state variables to the UI
  List<dynamic> get leagues => _leagues;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  dynamic get selectedLeague => _selectedLeague;
  List<dynamic> get topScorers => _topScorers;
  List<dynamic> get standings => _standings;
  List<dynamic> get liveLeagues => _liveLeagues;
  List<dynamic> get liveStandings => _liveStandings;

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
  Future<void> fetchLeagues({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_leagues.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    _nextUrl = null;
    _leagues = []; // Clear for fresh load
    notifyListeners();

    try {
      final String firstPageUrl = '$_baseUrl?include=country&per_page=100&select=name,image_path,category&api_token=$_apiKey';
      final response = await http.get(Uri.parse(firstPageUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> pageLeagues = data['data'] ?? [];
        for (var league in pageLeagues) {
          if (!_inLeagues(league['id'])) {
            _leagues.add(league);
          }
        }
        
        // Find next page
        final pagination = data['pagination'];
        if (pagination != null && pagination['has_more'] == true) {
          _nextUrl = pagination['next_page'];
          if (_nextUrl != null && !_nextUrl!.contains('api_token=')) {
            _nextUrl = _nextUrl! + (_nextUrl!.contains('?') ? '&' : '?') + 'api_token=$_apiKey';
          }
        }
        
        _isLoading = false;
        notifyListeners();

        // Start controlled background loading
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

  /// Controlled background loading to prevent network saturation and UI jank
  Future<void> _loadRemainingPages() async {
    while (_nextUrl != null) {
      await Future.delayed(const Duration(seconds: 2));
      
      try {
        String url = _nextUrl!;
        if (!url.contains('select=')) url += '&select=name,image_path,category';
        if (!url.contains('api_token=')) url += '&api_token=$_apiKey';

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> newLeagues = data['data'] ?? [];
          for (var league in newLeagues) {
            if (!_inLeagues(league['id'])) {
              _leagues.add(league);
            }
          }
          
          final pagination = data['pagination'];
          if (pagination != null && pagination['has_more'] == true) {
            _nextUrl = pagination['next_page'];
          } else {
            _nextUrl = null;
          }
          notifyListeners();
        } else {
          break; 
        }
      } catch (e) {
        break;
      }
    }
  }

  Future<void> loadMoreLeagues() async {
    if (_isFetchingMore || _nextUrl == null) return;
    _isFetchingMore = true;
    notifyListeners();
    try {
      String url = _nextUrl!;
      if (!url.contains('select=')) url += '&select=name,image_path,category';
      if (!url.contains('api_token=')) url += '&api_token=$_apiKey';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newLeagues = data['data'] ?? [];
        for (var league in newLeagues) {
          if (!_inLeagues(league['id'])) {
            _leagues.add(league);
          }
        }
        final pagination = data['pagination'];
        if (pagination != null && pagination['has_more'] == true) {
          _nextUrl = pagination['next_page'];
        } else {
          _nextUrl = null;
        }
      }
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchLeagueById(int id) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _selectedLeague = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$id?include=currentSeason.teams;country'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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

  Future<void> fetchTopScorers(int seasonId) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _topScorers = [];
    notifyListeners();

    try {
      final response = await http.get(
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

  Future<void> fetchStandings(int seasonId) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _standings = [];
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.sportmonks.com/v3/football/standings/seasons/$seasonId?include=participant;details'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _apiKey,
        },
      );

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

  Future<void> fetchLiveLeagues() async {
    if (_isLoading) return;
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

  Future<void> fetchLiveStandings(int leagueId) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _liveStandings = [];
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.sportmonks.com/v3/football/standings/live/leagues/$leagueId?api_token=$_apiKey&include=participant;details'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _liveStandings = data['data'] ?? [];
      } else {
        _errorMessage = 'Failed to load live standings: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while fetching live standings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isLeagueLive(int leagueId) {
    return _liveLeagues.any((league) => league['id'] == leagueId);
  }

  bool _inLeagues(int id) => _leagues.any((l) => l['id'] == id);
}
