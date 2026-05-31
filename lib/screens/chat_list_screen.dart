import 'package:flutter/material.dart';
import 'connection_requests_screen.dart';
import 'my_matches_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'match_detail_screen.dart';
import '../models/user_model.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Connections", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildCategoryItem(context, "Requests", Icons.auto_awesome_motion_rounded, const ConnectionRequestsScreen()),
                const SizedBox(width: 16),
                _buildCategoryItem(context, "Matches", Icons.handshake_rounded, const MyMatchesScreen()),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                Text("RECENT CHATS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
                SizedBox(width: 8),
                Expanded(child: Divider()),
              ],
            ),
          ),
          Expanded(
            child: currentUser == null
                ? const Center(child: Text("Login to see chats"))
                : StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: firestoreService.getMyMatches(currentUser.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final matches = snapshot.data ?? [];

                      // Sort by last message timestamp or creation timestamp
                      final sortedMatches = List<QueryDocumentSnapshot>.from(matches)
                        ..sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final aTime = aData['lastTimestamp'] ?? aData['timestamp'] ?? Timestamp.now();
                          final bTime = bData['lastTimestamp'] ?? bData['timestamp'] ?? Timestamp.now();
                          return bTime.compareTo(aTime);
                        });

                      // Deduplicate: Only show one chat per user pair
                      final List<QueryDocumentSnapshot> uniqueMatches = [];
                      final Set<String> seenUids = {};

                      for (var match in sortedMatches) {
                        final data = match.data() as Map<String, dynamic>;
                        final String otherUid = data['fromUid'] == currentUser.uid ? data['toUid'] : data['fromUid'];
                        if (!seenUids.contains(otherUid)) {
                          uniqueMatches.add(match);
                          seenUids.add(otherUid);
                        }
                      }

                      if (uniqueMatches.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text("No active chats yet", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: uniqueMatches.length,
                        itemBuilder: (context, index) {
                          final data = uniqueMatches[index].data() as Map<String, dynamic>;
                          final bool isMeSender = data['fromUid'] == currentUser.uid;
                          final String otherName = isMeSender ? (data['toName'] ?? "User") : (data['fromName'] ?? "User");
                          final String mySkill = (isMeSender ? data['fromSkills'] : data['toSkills']) ?? "Skills";
                          final String theirSkill = (isMeSender ? data['toSkills'] : data['fromSkills']) ?? "Skills";
                          final String? otherPhone = isMeSender ? data['toPhone'] : data['fromPhone'];

                          return FutureBuilder<UserModel?>(
                            future: firestoreService.getUserProfile(isMeSender ? data['toUid'] : data['fromUid']),
                            builder: (context, profileSnapshot) {
                              final String finalName = profileSnapshot.data?.name ?? otherName;
                              final String? lastMsg = data['lastMessage'];
                              final String subtitle = lastMsg != null ? "Message: $lastMsg" : "Swapping: $mySkill for $theirSkill";

                              final bool hasUnread = data['isRead'] == false && data['lastMessageSenderId'] != currentUser.uid;

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasUnread ? const Color(0xFF6C63FF).withValues(alpha: 0.05) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                                        child: Text(
                                          finalName.isNotEmpty ? finalName[0].toUpperCase() : 'U',
                                          style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ),
                                      if (hasUnread)
                                        Positioned(
                                          right: 2,
                                          top: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6C63FF),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    finalName, 
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: hasUnread ? FontWeight.w800 : FontWeight.bold,
                                      color: Colors.black87,
                                    )
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      subtitle, 
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                        color: hasUnread ? const Color(0xFF6C63FF) : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MatchDetailScreen(
                                          otherName: finalName,
                                          mySkill: mySkill,
                                          theirSkill: theirSkill,
                                          chatId: uniqueMatches[index].id,
                                          phoneNumber: otherPhone,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String title, IconData icon, Widget screen) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF6C63FF)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
