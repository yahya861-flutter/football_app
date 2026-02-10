import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StatsProvider with ChangeNotifier {
  List<dynamic> _stats = [];
  List<dynamic> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get stats => _stats;
  List<dynamic> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  Future<void> fetchStats(int fixtureId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = 'https://api.sportmonks.com/v3/football/fixtures/$fixtureId?api_token=$_apiKey&include=statistics.type;statistics.participant';
      debugPrint('Fetching Stats via: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fixture = data['data'];
        _stats = fixture?['statistics'] ?? [];
        debugPrint('Stats loaded: ${_stats.length}');
      } else {
        _errorMessage = 'Failed to load statistics: ${response.statusCode}';
        debugPrint('Stats error: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'An error occurred fetching stats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEvents(int fixtureId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = 'https://api.sportmonks.com/v3/football/fixtures/$fixtureId?api_token=$_apiKey&include=events.type;events.participant;events.player';
      debugPrint('Fetching Events via: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fixture = data['data'];
        _events = fixture?['events'] ?? [];
        // Sort events by minute (ascending)
        _events.sort((a, b) {
          final minA = a['minute'] ?? 0;
          final minB = b['minute'] ?? 0;
          return minA.compareTo(minB);
        });
        debugPrint('Events loaded: ${_events.length}');
      } else {
        _errorMessage = 'Failed to load events: ${response.statusCode}';
        debugPrint('Events error: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'An error occurred fetching events: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
