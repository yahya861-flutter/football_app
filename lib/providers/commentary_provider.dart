import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CommentaryProvider with ChangeNotifier {
  List<dynamic> _comments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';

  Future<void> fetchComments(int fixtureId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = 'https://api.sportmonks.com/v3/football/fixtures/$fixtureId?api_token=$_apiKey&include=comments';
      debugPrint('Fetching Comments via: $url');
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
        _comments = fixture?['comments'] ?? [];
        // Sort by minute (descending, latest first)
        _comments.sort((a, b) {
          final minA = a['minute'] ?? 0;
          final minB = b['minute'] ?? 0;
          return minB.compareTo(minA);
        });
      } else {
        _errorMessage = 'Failed to load comments: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred fetching comments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
