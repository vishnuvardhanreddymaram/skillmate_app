import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView(
        children: [
          SwitchListTile(title: const Text("Push Notifications"), value: true, onChanged: (v) {}),
          SwitchListTile(title: const Text("Email Notifications"), value: false, onChanged: (v) {}),
          SwitchListTile(title: const Text("Swap Requests"), value: true, onChanged: (v) {}),
        ],
      ),
    );
  }
}
