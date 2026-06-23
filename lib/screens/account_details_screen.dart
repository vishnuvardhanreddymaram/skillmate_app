import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'package:flutter/services.dart';


class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6C63FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Account Details")),
        body: const Center(child: Text("Not logged in.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Account Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        future: firestoreService.getUserProfile(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            // Fallback to FirebaseAuth profile if Firestore profile lookup fails
            return _buildDetailsBody(
              context,
              name: user.displayName ?? "SkillMate User",
              email: user.email ?? "No Email",
              phone: user.phoneNumber ?? "Not linked",
              bio: "Hey there! I am using SkillMate.",
            );
          }

          final userModel = snapshot.data!;
          return _buildDetailsBody(
            context,
            name: userModel.name,
            email: userModel.email,
            phone: userModel.phone ?? "Not linked",
            bio: userModel.bio,
          );
        },
      ),
    );
  }

  Widget _buildDetailsBody(
    BuildContext context, {
    required String name,
    required String email,
    required String phone,
    required String bio,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PERSONAL PROFILE",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            context,
            icon: Icons.person_outline,
            title: "Full Name",
            value: name,
            copyable: true,
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            context,
            icon: Icons.email_outlined,
            title: "Email Address",
            value: email,
            copyable: true,
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            context,
            icon: Icons.phone_outlined,
            title: "Phone Number",
            value: phone,
            copyable: phone != "Not linked",
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            context,
            icon: Icons.info_outline,
            title: "Short Bio",
            value: bio,
            copyable: false,
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              "Account created via SkillMate Secure Auth",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool copyable,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: Icon(Icons.copy_rounded, color: Colors.grey.shade400, size: 20),
              onPressed: () => _copyToClipboard(context, value, title),
            ),
        ],
      ),
    );
  }
}
