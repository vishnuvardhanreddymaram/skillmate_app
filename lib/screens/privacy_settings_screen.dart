import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Settings")),
      body: ListView(
        children: [
          SwitchListTile(title: const Text("Public Profile"), subtitle: const Text("Allow anyone to see your profile"), value: true, onChanged: (v) {}),
          SwitchListTile(title: const Text("Show Online Status"), value: true, onChanged: (v) {}),
        ],
      ),
    );
  }
}
