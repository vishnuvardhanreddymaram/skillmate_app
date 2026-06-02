import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'my_portfolio_screen.dart';
import 'reviews_screen.dart';
import 'dart:convert';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;
  final String currentUserName;

  const UserDetailScreen({
    super.key,
    required this.user,
    this.currentUserName = 'A user',
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _requestSent = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _sendSwapRequest() async {
    final fromUser = FirebaseAuth.instance.currentUser;
    if (fromUser == null) return;

    setState(() => _requestSent = true);

    try {
      // Fetch current user details to get their skills
      final currentProfile = await _firestoreService.getUserProfile(fromUser.uid);
      
      if (currentProfile != null) {
        await _firestoreService.sendSwapRequest(
          fromUid: currentProfile.uid,
          fromName: currentProfile.name,
          fromSkills: currentProfile.skillsHave,
          fromPhone: currentProfile.phone,
          toUid: widget.user.uid,
          toName: widget.user.name,
          toSkills: widget.user.skillsHave,
          toPhone: widget.user.phone,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Swap request sent to ${widget.user.name}!'),
              backgroundColor: const Color(0xFF6C63FF),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _requestSent = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFFE0E7FF),
              backgroundImage: user.photoBase64 != null
                  ? MemoryImage(base64Decode(user.photoBase64!))
                  : null,
              child: user.photoBase64 == null
                  ? const Icon(Icons.person, size: 60, color: Color(0xFF6C63FF))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              user.bio.isEmpty ? 'No bio yet.' : user.bio,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Quick Actions: Portfolio and Reviews
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(context, "Portfolio", Icons.photo_library, MyPortfolioScreen(targetUserId: user.uid, targetUserName: user.name)),
                _buildQuickAction(context, "Reviews", Icons.star, ReviewsScreen(targetUserId: user.uid, targetUserName: user.name)),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoCard("I can teach", user.skillsHave, Icons.check_circle, Colors.green),
            const SizedBox(height: 16),
            _buildInfoCard("I want to learn", user.skillsWant, Icons.search, Colors.orange),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _requestSent ? Colors.grey : const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(_requestSent ? Icons.check : Icons.handshake),
                label: Text(
                  _requestSent ? "Request Sent" : "Request Swap",
                  style: const TextStyle(fontSize: 18),
                ),
                onPressed: _requestSent ? null : _sendSwapRequest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color iconColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content.isEmpty ? 'Not specified' : content),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, Widget target) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE0E7FF),
              child: Icon(icon, color: const Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
