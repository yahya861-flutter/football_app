import 'package:flutter/material.dart';

class FollowProvider with ChangeNotifier {
  final List<int> _followedLeagueIds = [];
  final List<int> _followedTeamIds = [];

  List<int> get followedLeagueIds => _followedLeagueIds;
  List<int> get followedTeamIds => _followedTeamIds;

  bool isLeagueFollowed(int leagueId) => _followedLeagueIds.contains(leagueId);
  bool isTeamFollowed(int teamId) => _followedTeamIds.contains(teamId);

  void toggleFollowLeague(int leagueId) {
    if (_followedLeagueIds.contains(leagueId)) {
      _followedLeagueIds.remove(leagueId);
    } else {
      _followedLeagueIds.add(leagueId);
    }
    notifyListeners();
  }

  void toggleFollowTeam(int teamId) {
    if (_followedTeamIds.contains(teamId)) {
      _followedTeamIds.remove(teamId);
    } else {
      _followedTeamIds.add(teamId);
    }
    notifyListeners();
  }
}
