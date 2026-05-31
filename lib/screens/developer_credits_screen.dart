import 'package:flutter/material.dart';

class DeveloperCreditsScreen extends StatelessWidget {
  const DeveloperCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Developer Credits")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF6C63FF),
              child: Icon(Icons.code, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              "Developed By",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your Name", // The user can change this to their real name
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48.0),
              child: Text(
                "This application was built as a final year project for the SkillMate Skill Swapping Platform.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 48),
            const Text("© 2026 SkillMate Team", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
