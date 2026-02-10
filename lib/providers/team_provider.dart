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
      final url = '$_baseUrl/teams/$teamId?api_token=$_apiKey&include=country;seasons';
      debugPrint('Fetching Team Details: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _selectedTeam = json.decode(response.body)['data'];
      } else {
        _errorMessage = 'Failed to load team details: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeamFixtures(int teamId, {String? startDate, String? endDate}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final start = startDate ?? DateFormat('yyyy-MM-dd').format(now);
      final end = endDate ?? DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 365)));

      final url = '$_baseUrl/fixtures/between/$start/$end/$teamId?api_token=$_apiKey&include=participants;scores;venue';
      debugPrint('Fetching Team Fixtures: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _teamFixtures = json.decode(response.body)['data'] ?? [];
        _teamFixtures.sort((a, b) => a['starting_at'].compareTo(b['starting_at']));
      } else {
        debugPrint('Team fixtures error: ${response.statusCode}');
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
      final url = '$_baseUrl/statistics/seasons/teams/$teamId?api_token=$_apiKey&filters=teamStatisticSeasons:$seasonId&include=details.type';
      debugPrint('Fetching Team Stats (v3): $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _teamStats = data['data'] ?? [];
        debugPrint('Team stats loaded: ${_teamStats.length} entries');
      } else {
        debugPrint('Team stats error: ${response.statusCode}');
        _teamStats = [];
      }
    } catch (e) {
      debugPrint("Error fetching team stats: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchTeamSquad(int teamId) async {
    try {
      final url = '$_baseUrl/teams/$teamId?api_token=$_apiKey&include=squad.player';
      debugPrint('Fetching Team Squad: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
      final url = '$_baseUrl/transfers/teams/$teamId?api_token=$_apiKey&include=player;fromTeam;toTeam';
      debugPrint('Fetching Team Transfers: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
