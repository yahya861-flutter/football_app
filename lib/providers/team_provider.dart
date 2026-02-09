import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TeamProvider with ChangeNotifier {
  dynamic _selectedTeam;
  List<dynamic> _teamFixtures = [];
  List<dynamic> _teamStats = [];
  List<dynamic> _teamSquad = [];
  List<dynamic> _teamTransfers = [];
  bool _isLoading = false;
  String? _errorMessage;

  dynamic get selectedTeam => _selectedTeam;
  List<dynamic> get teamFixtures => _teamFixtures;
  List<dynamic> get teamStats => _teamStats;
  List<dynamic> get teamSquad => _teamSquad;
  List<dynamic> get teamTransfers => _teamTransfers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String _apiKey = 'tCaaAbgORG4Czb3byoAN4ywt70oCxMMpfQqVCmRetJp3BYapxRv419koCJQT';
  final String _baseUrl = 'https://api.sportmonks.com/v3/football';

  Future<void> fetchTeamDetails(int teamId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch general team info including country
      final response = await http.get(
        Uri.parse('$_baseUrl/teams/$teamId?include=country;seasons'),
        headers: {'Authorization': _apiKey},
      );

      if (response.statusCode == 200) {
        _selectedTeam = json.decode(response.body)['data'];
      } else {
        _errorMessage = 'Failed to load team details';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeamFixtures(int teamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startDate = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 30)));
      final endDate = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 30)));

      final url = '$_baseUrl/fixtures/between/$startDate/$endDate?filters=teamIds:$teamId&include=participants;scores;venue';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': _apiKey},
      );

      if (response.statusCode == 200) {
        _teamFixtures = json.decode(response.body)['data'] ?? [];
        _teamFixtures.sort((a, b) => a['starting_at'].compareTo(b['starting_at']));
      }
    } catch (e) {
      debugPrint("Error fetching team fixtures: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeamStats(int teamId, int seasonId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/teams/$teamId/seasons/$seasonId?include=stats'),
        headers: {'Authorization': _apiKey},
      );

      if (response.statusCode == 200) {
        _teamStats = json.decode(response.body)['data']?['stats'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching team stats: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchTeamSquad(int teamId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/teams/$teamId?include=squad.player'),
        headers: {'Authorization': _apiKey},
      );

      if (response.statusCode == 200) {
        _teamSquad = json.decode(response.body)['data']?['squad'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching team squad: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchTeamTransfers(int teamId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transfers/teams/$teamId?include=player;fromTeam;toTeam'),
        headers: {'Authorization': _apiKey},
      );

      if (response.statusCode == 200) {
        _teamTransfers = json.decode(response.body)['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching team transfers: $e");
    } finally {
      notifyListeners();
    }
  }
}
