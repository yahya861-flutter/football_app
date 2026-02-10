import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LineupProvider with ChangeNotifier {
  List<dynamic> _lineups = [];
  List<dynamic> _bench = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get lineups => _lineups;
  List<dynamic> get bench => _bench;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  Future<void> fetchLineupsAndBench(int fixtureId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch Lineups and Bench via Fixture Include
      final response = await http.get(
        Uri.parse('https://api.sportmonks.com/v3/football/fixtures/$fixtureId?api_token=$_apiKey&include=lineups.player;lineups.position;lineups.type'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fixture = data['data'];
        final List<dynamic> allLineups = fixture?['lineups'] ?? [];
        
        // type_id 11 = Starting XI, type_id 12 = Bench
        _lineups = allLineups.where((l) => l['type_id'] == 11).toList();
        _bench = allLineups.where((l) => l['type_id'] == 12).toList();
        
        debugPrint('Fetched ${allLineups.length} lineup entries');
      } else {
        _errorMessage = 'Failed to load lineups: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred fetching lineups/bench: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
