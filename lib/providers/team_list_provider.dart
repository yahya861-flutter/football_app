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
    if (_teams.isNotEmpty && !forceRefresh) return; // Don't fetch if already loaded
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?per_page=100&select=name,image_path'),
        headers: {'Authorization': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _teams = data['data'] ?? [];
        
        final pagination = data['pagination'];
        if (pagination != null && pagination['has_more'] == true) {
          _nextUrl = pagination['next_page'];
        } else {
          _nextUrl = null;
        }

        // Start controlled background loading
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

  /// Controlled background loading for teams
  Future<void> _loadRemainingPages() async {
    while (_nextUrl != null) {
      // Delay to keep UI responsive and network clear for other requests
      await Future.delayed(const Duration(seconds: 2));
      
      try {
        String url = _nextUrl!;
        if (!url.contains('api_token=')) {
          url += (_nextUrl!.contains('?') ? '&' : '?') + 'api_token=$_apiKey';
        }
        if (!url.contains('select=')) {
          url += '&select=name,image_path';
        }

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> newTeams = data['data'] ?? [];
          _teams.addAll(newTeams);
          
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
    // Keep for manual scroll triggers to bypass delay if user is actively scrolling
    if (_isFetchingMore || _nextUrl == null) return;
    // ... rest same

    _isFetchingMore = true;
    notifyListeners();

    try {
      String nextUrlWithKey = _nextUrl!.contains('api_token=') 
          ? _nextUrl! 
          : _nextUrl! + (_nextUrl!.contains('?') ? '&' : '?') + 'api_token=$_apiKey';
      
      // Ensure select is preserved or added
      if (!nextUrlWithKey.contains('select=')) {
        nextUrlWithKey += '&select=name,image_path';
      }

      final response = await http.get(
        Uri.parse(nextUrlWithKey),
        headers: {'Authorization': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newTeams = data['data'] ?? [];
        _teams.addAll(newTeams);
        
        final pagination = data['pagination'];
        if (pagination != null && pagination['has_more'] == true) {
          _nextUrl = pagination['next_page'];
        } else {
          _nextUrl = null;
        }
      }
    } catch (e) {
      debugPrint("Error loading more teams: $e");
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> searchTeams(String query) async {
    if (query.isEmpty) {
      fetchTeams(forceRefresh: true);
      return;
    }
    
    _isLoading = true;
    _teams = []; 
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/$query?select=name,image_path'),
        headers: {'Authorization': _apiKey},
      );

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
}
