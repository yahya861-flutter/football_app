import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/team_list_provider.dart';
import 'team_details_screen.dart';
import 'package:football_app/l10n/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        context.read<TeamListProvider>().searchTeams(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).appBarTheme.backgroundColor;
    final textPrimary = Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.white;
    final secondaryColor = isDark ? const Color(0xFF121212) : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchTeams,
              hintStyle: TextStyle(color: textPrimary.withOpacity(0.4), fontSize: 14),
              prefixIcon: Icon(Icons.search, color: textPrimary.withOpacity(0.4), size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: textPrimary.withOpacity(0.4), size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 10, bottom: 12),
            ),
            onChanged: (value) {
              setState(() {}); // Toggle clear icon
              _onSearchChanged(value);
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                context.read<TeamListProvider>().searchTeams(value);
              }
            },
          ),
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;
    const Color accentColor = Color(0xFFFF8700);

    return Consumer<TeamListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: accentColor));
        }

        if (provider.teams.isEmpty && _searchController.text.isNotEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.noTeamsFound, style: TextStyle(color: subTextColor)),
          );
        }

        if (_searchController.text.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 60, color: subTextColor.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.searchFavoriteTeamsPrompt, style: TextStyle(color: subTextColor)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: provider.teams.length,
          itemBuilder: (context, index) {
            final team = provider.teams[index];
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: team['image_path'] != null
                    ? Image.network(team['image_path'], errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: accentColor, size: 24))
                    : const Icon(Icons.shield, color: accentColor, size: 24),
              ),
              title: Text(
                team['name'] ?? 'Unknown',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(AppLocalizations.of(context)!.team, style: TextStyle(color: subTextColor, fontSize: 12)),
              trailing: Icon(Icons.arrow_forward_ios_rounded, color: subTextColor, size: 14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamDetailsScreen(
                      teamId: team['id'],
                      teamName: team['name'],
                      teamLogo: team['image_path'] ?? '',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
