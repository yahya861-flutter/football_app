import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlayerDetailsScreen extends StatelessWidget {
  final dynamic squadItem;
  final String teamName;
  final String teamLogo;

  const PlayerDetailsScreen({
    super.key,
    required this.squadItem,
    required this.teamName,
    required this.teamLogo,
  });

  @override
  Widget build(BuildContext context) {
    final player = squadItem['player'] ?? squadItem;
    final String name = player['display_name'] ?? player['name'] ?? 'Unknown Player';
    final String img = player['image_path'] ?? '';
    final String nationality = player['country']?['name'] ?? 'Unknown';
    final String position = player['position']?['name'] ?? 'N/A';
    
    // Calculate Age
    String age = "N/A";
    if (player['date_of_birth'] != null) {
      try {
        final dob = DateTime.parse(player['date_of_birth']);
        final now = DateTime.now();
        int years = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          years--;
        }
        age = "$years Years";
      } catch (_) {}
    }

    final String height = player['height'] != null ? "${player['height']} CM" : "N/A";
    final String weight = player['weight'] != null ? "${player['weight']} KG" : "N/A";
    final String foot = player['preferred_foot'] ?? player['foot'] ?? "N/A";
    final dynamic jerseyNum = squadItem['jersey_number'] ?? player['jersey_number'];
    final String shirt = jerseyNum?.toString() ?? "N/A";

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black38;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                   if (img.isNotEmpty)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(img),
                    )
                  else
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nationality,
                    style: TextStyle(color: subTextColor, fontSize: 16),
                  ),
                ],
              ),
            ),
            
            // Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Label
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF5CC091),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.black, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Info",
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  
                  // Details Grid
                  _buildInfoGrid([
                    _InfoItem("Height", height),
                    _InfoItem("Age", age),
                    _InfoItem("Club", teamName, teamLogo),
                    _InfoItem("Shirt", shirt),
                    _InfoItem("Prefer Foot", foot),
                    _InfoItem("Weight", weight),
                    _InfoItem("Position", position),
                    _InfoItem("Nationality", nationality),
                  ], isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(List<_InfoItem> items, bool isDark) {
    return Wrap(
      spacing: 0,
      runSpacing: 24,
      children: items.map((item) {
        return SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.logo != null && item.logo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Image.network(item.logo!, width: 16, height: 16),
                    ),
                  Expanded(
                    child: Text(
                      item.value,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final String? logo;
  _InfoItem(this.label, this.value, [this.logo]);
}
