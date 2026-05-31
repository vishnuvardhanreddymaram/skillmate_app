import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Blocked Users")),
      body: const Center(
        child: Text("You have no blocked users.", style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
