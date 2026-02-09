import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TransferProvider with ChangeNotifier {
  List<dynamic> _transfers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get transfers => _transfers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _baseUrl = 'https://api.sportmonks.com/v3/football';
  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  Future<void> fetchTransfers(int teamId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch transfers with player details, type, and both teams
      final url = '$_baseUrl/transfers/teams/$teamId?include=player;fromTeam;toTeam;type';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        _transfers = json.decode(response.body)['data'] ?? [];
      } else {
        _errorMessage = 'Failed to load transfers: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
