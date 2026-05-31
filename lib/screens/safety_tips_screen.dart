import 'package:flutter/material.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Tips")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TipCard(
            title: "Meet in Public",
            description: "If you decide to meet your skill swap partner in person, always choose a busy public place like a cafe or library.",
            icon: Icons.location_city,
          ),
          _TipCard(
            title: "Verify Profiles",
            description: "Check the other user's reviews and portfolio before starting a swap to ensure they are trustworthy.",
            icon: Icons.verified_user,
          ),
          _TipCard(
            title: "Keep it on SkillMate",
            description: "Try to keep your early conversations within the app to protect your privacy.",
            icon: Icons.security,
          ),
          _TipCard(
            title: "No Money Involved",
            description: "SkillMate is for swapping knowledge. If someone asks for money, report them immediately.",
            icon: Icons.money_off,
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _TipCard({required this.title, required this.description, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
