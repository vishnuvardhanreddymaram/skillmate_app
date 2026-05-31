import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support")),
      body: ListView(
        children: const [
          ListTile(title: Text("Contact Us"), leading: Icon(Icons.email)),
          ListTile(title: Text("Report an Issue"), leading: Icon(Icons.bug_report)),
        ],
      ),
    );
  }
}
