import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: "Current Password")),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: "New Password")),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () {}, child: const Text("Update Password"))
          ],
        ),
      ),
    );
  }
}
