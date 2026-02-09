import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SquadProvider with ChangeNotifier {
  List<dynamic> _squad = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get squad => _squad;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _baseUrl = 'https://api.sportmonks.com/v3/football';
  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  Future<void> fetchSquad(int teamId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch squad records (contains jersey_number) and include player details
      final url = '$_baseUrl/squads/teams/$teamId?include=player.country;player.position';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _apiKey,
        },
      );
      if (response.statusCode == 200) {
        _squad = json.decode(response.body)['data'] ?? [];
      } else {
        _errorMessage = 'Failed to load squad details: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
