import 'package:flutter/material.dart';

class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account Details")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(title: Text("Email"), subtitle: Text("user@example.com")),
          ListTile(title: Text("Phone"), subtitle: Text("+1 234 567 8900")),
        ],
      ),
    );
  }
}
