import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:football_app/providers/league_provider.dart';
import 'package:football_app/providers/follow_provider.dart';
import 'package:football_app/screens/league_details_screen.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E1E2C);
    const Color accentColor = Color(0xFFD4FF00);
    const Color cardColor = Color(0xFF2D2D44);

    return Scaffold(
      backgroundColor: primaryColor,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Sub Tabs: Leagues | Teams
            const TabBar(
              indicatorColor: accentColor,
              labelColor: accentColor,
              unselectedLabelColor: Colors.white38,
              tabs: [
                Tab(text: "Leagues"),
                Tab(text: "Teams"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildLeaguesTab(accentColor, cardColor),
                  _buildTeamsTab(accentColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguesTab(Color accentColor, Color cardColor) {
    return Consumer2<LeagueProvider, FollowProvider>(
      builder: (context, leagueProvider, followProvider, child) {
        if (leagueProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueGrey));
        }

        // Apply search filtering
        final filteredLeagues = leagueProvider.leagues.where((l) {
          final name = l['name']?.toLowerCase() ?? "";
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        final topLeagues = filteredLeagues.where((l) => l['category'] == 1).toList();
        
        // Regroup filtered leagues by country
        Map<String, List<dynamic>> leaguesByCountry = {};
        for (var league in filteredLeagues) {
          final countryName = league['country']?['name'] ?? 'International';
          if (!leaguesByCountry.containsKey(countryName)) {
            leaguesByCountry[countryName] = [];
          }
          leaguesByCountry[countryName]!.add(league);
        }

        final followedLeagues = filteredLeagues.where((l) => followProvider.isLeagueFollowed(l['id'])).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Search Bar
              _buildSearchBar(cardColor),
              const SizedBox(height: 24),
              
              // Following Section
              _buildExpandableSection(
                icon: Icons.star,
                iconColor: Colors.tealAccent,
                title: "Following",
                count: followedLeagues.length,
                content: followedLeagues.isEmpty 
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("You are not following any leagues", style: TextStyle(color: Colors.white38)),
                    )
                  : Column(children: followedLeagues.map((l) => _buildLeagueItem(l, accentColor)).toList()),
              ),
              const SizedBox(height: 12),

              // Top Leagues Section
              _buildExpandableSection(
                icon: Icons.thumb_up,
                iconColor: Colors.tealAccent,
                title: "Top Leagues",
                showSeeAll: true,
                count: topLeagues.length,
                content: Column(children: topLeagues.map((l) => _buildLeagueItem(l, accentColor)).toList()),
              ),
              const SizedBox(height: 12),

              // Suggestions Section
              _buildExpandableSection(
                icon: Icons.lightbulb_outline,
                iconColor: Colors.tealAccent,
                title: "Suggestions",
                count: 3,
                content: _buildSuggestionsRow(accentColor, cardColor, leagueProvider.leagues),
              ),
              const SizedBox(height: 32),

              const Text("All Leagues", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // All Leagues grouped by country
              ...leaguesByCountry.entries.map((entry) {
                return _buildCountryExpandable(entry.key, entry.value, accentColor);
              }).toList(),
              
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: const InputDecoration(
          hintText: "Type to search leagues",
          hintStyle: TextStyle(color: Colors.white38),
          prefixIcon: Icon(Icons.search, color: Colors.white38),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
// Expandable content
  Widget _buildExpandableSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required Widget content,
    bool showSeeAll = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: iconColor),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSeeAll)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Text("See All", style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
            ],
          ),
          children: [content],
        ),
      ),
    );
  }
// suggestion area
  Widget _buildSuggestionsRow(Color accentColor, Color cardColor, List<dynamic> leagues) {
    // Pick a few leagues for suggestions
    final suggestions = leagues.take(3).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: suggestions.map((l) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                if (l['image_path'] != null)
                  Image.network(l['image_path'], width: 24, height: 24)
                else
                  Icon(Icons.emoji_events, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(l['name'] ?? 'League', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.star_border, color: Colors.white38, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
// all leageus area by country
  Widget _buildCountryExpandable(String countryName, List<dynamic> leagues, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
            child: const Icon(Icons.public, color: Colors.blue, size: 20),
          ),
          title: Text(countryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(leagues.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
            ],
          ),
          children: leagues.map((l) => _buildLeagueItem(l, accentColor)).toList(),
        ),
      ),
    );
  }

  Widget _buildLeagueItem(dynamic league, Color accentColor) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeagueDetailsScreen(leagueId: league['id']),
          ),
        );
      },
      leading: league['image_path'] != null 
        ? Image.network(league['image_path'], width: 30, height: 30)
        : Icon(Icons.emoji_events, color: accentColor, size: 30),
      title: Text(league['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Consumer<FollowProvider>(
        builder: (context, follow, child) {
          final isFollowed = follow.isLeagueFollowed(league['id']);
          return IconButton(
            icon: Icon(isFollowed ? Icons.star : Icons.star_border, 
                 color: isFollowed ? accentColor : Colors.white38),
            onPressed: () => follow.toggleFollowLeague(league['id']),
          );
        },
      ),
    );
  }

  Widget _buildTeamsTab(Color accentColor) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 80, color: Colors.white10),
          SizedBox(height: 16),
          Text("Follow Teams", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text("Search for your favorite teams to follow them", style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
