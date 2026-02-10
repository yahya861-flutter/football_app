import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class H2HProvider with ChangeNotifier {
  List<dynamic> _h2hMatches = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get h2hMatches => _h2hMatches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  Future<void> fetchH2HMatches(int team1Id, int team2Id) async {
    _isLoading = true;
    _errorMessage = null;
    _h2hMatches = [];
    notifyListeners();

    try {
      String? nextUrl = 'https://api.sportmonks.com/v3/football/fixtures/head-to-head/$team1Id/$team2Id?api_token=$_apiKey&include=participants;scores;league;venue;state';
      debugPrint('Fetching H2H: $nextUrl');
      
      while (nextUrl != null) {
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        debugPrint('H2H Response Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> pageMatches = data['data'] ?? [];
          debugPrint('H2H Matches found on page: ${pageMatches.length}');
          _h2hMatches.addAll(pageMatches);

          final pagination = data['pagination'];
          if (pagination != null && pagination['has_more'] == true) {
            nextUrl = pagination['next_page'];
          } else {
            nextUrl = null;
          }
        } else {
          _errorMessage = 'Failed to load H2H matches: ${response.statusCode}';
          debugPrint('H2H Error: $_errorMessage');
          break;
        }
      }
      
      // Sort by timestamp (descending, most recent first)
      _h2hMatches.sort((a, b) {
        final timeA = a['starting_at_timestamp'] ?? 0;
        final timeB = b['starting_at_timestamp'] ?? 0;
        return timeB.compareTo(timeA);
      });
      debugPrint('H2H Total matches: ${_h2hMatches.length}');
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      debugPrint('H2H Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
