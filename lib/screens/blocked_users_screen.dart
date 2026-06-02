import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _loading = true;
  List<Map<String, String>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  Future<void> _fetchBlockedUsers() async {
    if (_currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get();
      if (!doc.exists) {
        setState(() => _loading = false);
        return;
      }

      final data = doc.data();
      final List<dynamic> blockedIds = data?['blockedUids'] ?? [];

      if (blockedIds.isEmpty) {
        setState(() {
          _blockedUsers = [];
          _loading = false;
        });
        return;
      }

      // Fetch profiles of blocked users
      final List<Map<String, String>> fetchedBlocked = [];
      for (var id in blockedIds) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(id.toString()).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          fetchedBlocked.add({
            'uid': id.toString(),
            'name': userData?['name'] ?? 'SkillMate User',
            'email': userData?['email'] ?? 'No email',
          });
        } else {
          fetchedBlocked.add({
            'uid': id.toString(),
            'name': 'Unknown User',
            'email': 'Account deleted',
          });
        }
      }

      if (mounted) {
        setState(() {
          _blockedUsers = fetchedBlocked;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching blocked users: $e");
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _unblockUser(String uid, String name) async {
    if (_currentUser == null) return;

    try {
      setState(() => _loading = true);

      await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).update({
        'blockedUids': FieldValue.arrayRemove([uid])
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name unblocked!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _fetchBlockedUsers();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unblock: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Blocked Users", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF))))
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "You have no blocked users.",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _blockedUsers.length,
                  itemBuilder: (context, index) {
                    final blocked = _blockedUsers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          child: const Icon(Icons.person, color: Colors.red),
                        ),
                        title: Text(blocked['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(blocked['email']!, style: TextStyle(color: Colors.grey.shade500)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0,
                          ),
                          onPressed: () => _unblockUser(blocked['uid']!, blocked['name']!),
                          child: const Text("Unblock", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
