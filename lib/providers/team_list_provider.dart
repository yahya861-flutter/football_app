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

  Future<void> fetchTeams() async {
    if (_teams.isNotEmpty) return; // Don't fetch if already loaded
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?per_page=50'),
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

  Future<void> loadMoreTeams() async {
    if (_isFetchingMore || _nextUrl == null) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      final nextUrlWithKey = _nextUrl!.contains('api_token=') 
          ? _nextUrl! 
          : _nextUrl! + (_nextUrl!.contains('?') ? '&' : '?') + 'api_token=$_apiKey';

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
      // If query is empty, maybe reset to initial state? 
      // For now, let's keep it simple. The UI will filter the existing list.
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      // SportMonks typically supports search via 'search' or 'name' filter
      final response = await http.get(
        Uri.parse('$_baseUrl/search/$query'),
        headers: {'Authorization': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _teams = data['data'] ?? [];
        _nextUrl = null; // Search results might not support same pagination
      }
    } catch (e) {
      debugPrint("Error searching teams: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
