import 'package:flutter/material.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Reviews")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.orange),
              title: Text("Great swapper! ${index + 1}"),
              subtitle: const Text("Highly recommended for anyone looking to learn."),
            ),
          );
        },
      ),
    );
  }
}
