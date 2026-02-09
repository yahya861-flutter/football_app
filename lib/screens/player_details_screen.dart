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
    final String foot = player['preferred_foot'] ?? "N/A";
    final String shirt = squadItem['jersey_number']?.toString() ?? "N/A";

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nationality,
                    style: const TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                ],
              ),
            ),
            
            // Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
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
                      const Text(
                        "Info",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.white10),
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
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(List<_InfoItem> items) {
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
                style: const TextStyle(color: Colors.white38, fontSize: 13),
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
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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
