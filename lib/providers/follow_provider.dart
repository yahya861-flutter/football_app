import 'package:flutter/material.dart';
import 'package:football_app/services/database_service.dart';
import 'dart:convert';

class FollowProvider with ChangeNotifier {
  final List<int> _followedLeagueIds = [];
  final List<int> _followedTeamIds = [];
  final DatabaseService _dbService = DatabaseService();

  List<int> get followedLeagueIds => _followedLeagueIds;
  List<int> get followedTeamIds => _followedTeamIds;

  FollowProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final favorites = await _dbService.getFavorites();
    _followedLeagueIds.clear();
    _followedTeamIds.clear();
    for (var fav in favorites) {
      if (fav['type'] == 'league') {
        _followedLeagueIds.add(fav['id']);
      } else if (fav['type'] == 'team') {
        _followedTeamIds.add(fav['id']);
      }
    }
    notifyListeners();
  }

  bool isLeagueFollowed(int leagueId) => _followedLeagueIds.contains(leagueId);
  bool isTeamFollowed(int teamId) => _followedTeamIds.contains(teamId);

  Future<void> toggleFollowLeague(int leagueId, {dynamic leagueData}) async {
    if (_followedLeagueIds.contains(leagueId)) {
      _followedLeagueIds.remove(leagueId);
      await _dbService.deleteFavorite(leagueId);
    } else {
      _followedLeagueIds.add(leagueId);
      final dataStr = leagueData != null ? jsonEncode(leagueData) : "{}";
      await _dbService.insertFavorite(leagueId, 'league', dataStr);
    }
    notifyListeners();
  }

  Future<void> toggleFollowTeam(int teamId, {dynamic teamData}) async {
    if (_followedTeamIds.contains(teamId)) {
      _followedTeamIds.remove(teamId);
      await _dbService.deleteFavorite(teamId);
    } else {
      _followedTeamIds.add(teamId);
      final dataStr = teamData != null ? jsonEncode(teamData) : "{}";
      await _dbService.insertFavorite(teamId, 'team', dataStr);
    }
    notifyListeners();
  }
}
