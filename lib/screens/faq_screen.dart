import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FAQ")),
      body: ListView(
        children: const [
          ExpansionTile(
            title: Text("How do I request a swap?"),
            children: [Padding(padding: EdgeInsets.all(16.0), child: Text("Go to the Discover feed and tap Request Swap!"))],
          ),
          ExpansionTile(
            title: Text("Is SkillMate free?"),
            children: [Padding(padding: EdgeInsets.all(16.0), child: Text("Yes, basic skill swapping is completely free!"))],
          ),
        ],
      ),
    );
  }
}
