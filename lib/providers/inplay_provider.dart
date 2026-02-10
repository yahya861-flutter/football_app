import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InPlayProvider with ChangeNotifier {
  List<dynamic> _inPlayMatches = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get inPlayMatches => _inPlayMatches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _baseUrl = 'https://api.sportmonks.com/v3/football/livescores/inplay';
  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  Future<void> fetchInPlayMatches() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _inPlayMatches = []; // Clear the list to prevent duplicates
    notifyListeners();

    try {
      String? nextUrl = '$_baseUrl?include=league;participants;scores;state';
      
      while (nextUrl != null) {
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': _apiKey,
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> pageMatches = data['data'] ?? [];
          for (var match in pageMatches) {
            if (!_inInPlayMatches(match['id'])) {
              _inPlayMatches.add(match);
            }
          }

          final pagination = data['pagination'];
          if (pagination != null && pagination['has_more'] == true) {
            nextUrl = pagination['next_page'];
          } else {
            nextUrl = null;
          }
        } else {
          _errorMessage = 'Failed to load in-play matches: ${response.statusCode}';
          break;
        }
      }
    } catch (e) {
      _errorMessage = 'An error occurred while fetching in-play matches: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _inInPlayMatches(int id) {
    return _inPlayMatches.any((m) => m['id'] == id);
  }
}
