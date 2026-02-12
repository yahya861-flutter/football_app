import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:football_app/providers/team_list_provider.dart';
import 'package:football_app/providers/follow_provider.dart';
import 'package:football_app/screens/team_details_screen.dart';
import 'package:football_app/widgets/notifications_activated_dialog.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final TextEditingController _teamSearchController = TextEditingController();
  final ScrollController _teamScrollController = ScrollController();
  String _teamSearchQuery = "";
  Timer? _teamDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamListProvider>().fetchTeams();
    });
    
    _teamScrollController.addListener(() {
      if (_teamScrollController.position.pixels >= _teamScrollController.position.maxScrollExtent - 200) {
        context.read<TeamListProvider>().loadMoreTeams();
      }
    });
  }

  @override
  void dispose() {
    _teamScrollController.dispose();
    _teamSearchController.dispose();
    _teamDebounce?.cancel();
    super.dispose();
  }

  bool _isFollowingExpanded = true;
  bool _isAllTeamsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? const Color(0xFF131321) : Colors.white;
    const Color accentColor = Color(0xFFFF8700);
    final Color cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: primaryColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? primaryColor : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
            ),
            child: TabBar(
              indicatorColor: accentColor,
              indicatorWeight: 3,
              labelColor: isDark ? Colors.white : Colors.black,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelColor: isDark ? Colors.white38 : Colors.black45,
              tabs: const [
                Tab(text: "Teams"),
                Tab(text: "Following"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildTeamsTab(accentColor, cardColor),
            _buildFollowingTeamsTab(accentColor, cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsTab(Color accentColor, Color cardColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Consumer2<TeamListProvider, FollowProvider>(
      builder: (context, teamProvider, followProvider, _) {
        if (teamProvider.isLoading && teamProvider.teams.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueGrey));
        }

        final filteredTeams = teamProvider.teams.where((t) {
          final name = t['name']?.toLowerCase() ?? "";
          return name.contains(_teamSearchQuery.toLowerCase());
        }).toList();

        final List<Widget> items = [];

        // Search Bar
        items.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          child: _buildTeamSearchBar(cardColor),
        ));

        // All Teams Header
        items.add(_buildSectionHeader(
          icon: Icons.groups_rounded,
          iconColor: isDark ? Colors.tealAccent : Colors.teal,
          title: "All Teams",
          count: teamProvider.teams.length,
          isExpanded: _isAllTeamsExpanded,
          onToggle: () => setState(() => _isAllTeamsExpanded = !_isAllTeamsExpanded),
        ));

        // All Teams Content
        if (_isAllTeamsExpanded) {
          items.addAll(filteredTeams.map((t) => _buildTeamItem(t, accentColor, followProvider, isDark)));
        }

        // Loading Indicator
        if (teamProvider.hasMore) {
          items.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: accentColor, strokeWidth: 2),
                  const SizedBox(height: 8),
                  Text(
                    "Loading more teams (${teamProvider.teams.length} loaded)...",
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ));
        }

        items.add(const SizedBox(height: 40));

        return ListView.builder(
          controller: _teamScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }

  Widget _buildFollowingTeamsTab(Color accentColor, Color cardColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Consumer<FollowProvider>(
      builder: (context, followProvider, child) {
        final followedTeams = context.watch<TeamListProvider>().teams.where((t) => followProvider.isTeamFollowed(t['id'])).toList();

        if (followedTeams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline_rounded, size: 64, color: subTextColor),
                const SizedBox(height: 16),
                Text("No favorited teams yet", style: TextStyle(color: textColor, fontSize: 16)),
                const SizedBox(height: 8),
                Text("Star a team to see it here", style: TextStyle(color: subTextColor, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: followedTeams.length,
          itemBuilder: (context, index) {
            return _buildTeamItem(followedTeams[index], accentColor, followProvider, isDark);
          },
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title, 
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(), 
                style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: subTextColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSearchBar(Color cardColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white.withOpacity(0.34) : Colors.black38;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05), width: 1) : null,
      ),
      child: TextField(
        controller: _teamSearchController,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(color: textColor, fontSize: 14),
        onChanged: (val) {
          setState(() => _teamSearchQuery = val);
          if (_teamDebounce?.isActive ?? false) _teamDebounce!.cancel();
          _teamDebounce = Timer(const Duration(milliseconds: 500), () {
            if (val.isNotEmpty) {
              context.read<TeamListProvider>().searchTeams(val);
            } else {
              context.read<TeamListProvider>().fetchTeams(forceRefresh: true);
            }
          });
        },
        onSubmitted: (val) {
          if (val.isNotEmpty) {
            context.read<TeamListProvider>().searchTeams(val);
          } else {
            context.read<TeamListProvider>().fetchTeams(forceRefresh: true);
          }
        },
        decoration: InputDecoration(
          hintText: "Search teams...",
          hintStyle: TextStyle(color: subTextColor, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: subTextColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTeamItem(dynamic team, Color accentColor, FollowProvider followProvider, bool isDark) {
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white.withOpacity(0.34) : Colors.black38;
    final isFollowed = followProvider.isTeamFollowed(team['id']);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailsScreen(
              teamId: team['id'],
              teamName: team['name'] ?? 'Unknown',
              teamLogo: team['image_path'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: team['image_path'] != null 
                  ? Image.network(team['image_path'], width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.shield_rounded, color: accentColor, size: 28))
                  : Icon(Icons.shield_rounded, color: accentColor, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                team['name'] ?? 'Unknown', 
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFollowed) ...[
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const NotificationsActivatedDialog(),
                      );
                    },
                    child: Icon(
                      Icons.notifications_active_rounded, 
                      color: accentColor, 
                      size: 22
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                IconButton(
                  icon: Icon(isFollowed ? Icons.star_rounded : Icons.star_outline_rounded, 
                       color: isFollowed ? accentColor : subTextColor, size: 24),
                  onPressed: () => followProvider.toggleFollowTeam(team['id'], teamData: team),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
