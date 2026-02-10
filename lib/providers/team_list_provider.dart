import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TeamListProvider with ChangeNotifier {
  List<dynamic> _teams = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _nextUrl;
  bool _isFetchingMore = false;

  List<dynamic> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _nextUrl != null;

  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';
  final String _baseUrl = 'https://api.sportmonks.com/v3/football/teams';

  Future<void> fetchTeams({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_teams.isNotEmpty && !forceRefresh) return;
    
    _isLoading = true;
    _errorMessage = null;
    _teams = []; // Clear for fresh load
    notifyListeners();

    try {
      final url = '$_baseUrl?api_token=$_apiKey&per_page=100&select=name,image_path';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> pageTeams = data['data'] ?? [];
        for (var team in pageTeams) {
          if (!_inTeams(team['id'])) {
            _teams.add(team);
          }
        }
        
        final pagination = data['pagination'];
        if (pagination != null && pagination['has_more'] == true) {
          _nextUrl = pagination['next_page'];
        } else {
          _nextUrl = null;
        }

        if (_nextUrl != null) {
          _loadRemainingPages();
        }
      } else {
        _errorMessage = 'Failed to load teams';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRemainingPages() async {
    while (_nextUrl != null) {
      await Future.delayed(const Duration(seconds: 2));
      
      try {
        String url = _nextUrl!;
        if (!url.contains('api_token=')) url += (_nextUrl!.contains('?') ? '&' : '?') + 'api_token=$_apiKey';
        if (!url.contains('select=')) url += '&select=name,image_path';

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> newTeams = data['data'] ?? [];
          for (var team in newTeams) {
            if (!_inTeams(team['id'])) {
              _teams.add(team);
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

  Future<void> loadMoreTeams() async {
    if (_isFetchingMore || _nextUrl == null) return;
    _isFetchingMore = true;
    notifyListeners();

    try {
      String url = _nextUrl!;
      if (!url.contains('api_token=')) url += (url.contains('?') ? '&' : '?') + 'api_token=$_apiKey';
      if (!url.contains('select=')) url += '&select=name,image_path';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newTeams = data['data'] ?? [];
        for (var team in newTeams) {
          if (!_inTeams(team['id'])) {
            _teams.add(team);
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

  String? _currentSearchQuery;

  Future<void> searchTeams(String query) async {
    if (query.isEmpty) {
      _currentSearchQuery = null;
      fetchTeams(forceRefresh: true);
      return;
    }
    
    _currentSearchQuery = query;
    _isLoading = true;
    _teams = []; 
    notifyListeners();

    try {
      final url = '$_baseUrl/search/$query?api_token=$_apiKey&select=name,image_path';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (_currentSearchQuery != query) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _teams = data['data'] ?? [];
        _nextUrl = null; 
      }
    } catch (e) {
      debugPrint("Error searching teams: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _inTeams(int id) => _teams.any((t) => t['id'] == id);
}
