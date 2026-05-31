import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Language")),
      body: ListView(
        children: const [
          ListTile(title: Text("English"), trailing: Icon(Icons.check, color: Colors.blue)),
          ListTile(title: Text("Spanish")),
          ListTile(title: Text("French")),
        ],
      ),
    );
  }
}
