import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Us")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            Icon(Icons.handshake, size: 80, color: Color(0xFF6C63FF)),
            SizedBox(height: 16),
            Text("SkillMate v1.0.0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(height: 16),
            Text("SkillMate is a platform built to help people share knowledge without money. Built for the final year project.", textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
