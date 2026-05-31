import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'match_detail_screen.dart';
import '../models/user_model.dart';

class MyMatchesScreen extends StatelessWidget {
  const MyMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    if (currentUser == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("My Matches", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getMyMatches(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          final matches = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['fromUid'] == currentUser.uid || data['toUid'] == currentUser.uid;
          }).toList();
          
          // Sort by last activity
          matches.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['lastTimestamp'] ?? aData['timestamp'] ?? Timestamp.now();
            final bTime = bData['lastTimestamp'] ?? bData['timestamp'] ?? Timestamp.now();
            return bTime.compareTo(aTime);
          });

          if (matches.isEmpty) return _buildEmptyState(context);

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final data = matches[index].data() as Map<String, dynamic>;
              final bool isMeSender = data['fromUid'] == currentUser.uid;
              
              final String otherName = isMeSender ? (data['toName'] ?? "Skillmate User") : (data['fromName'] ?? "Skillmate User");
              final String mySkill = (isMeSender ? data['fromSkills'] : data['toSkills']) ?? "Skills";
              final String theirSkill = (isMeSender ? data['toSkills'] : data['fromSkills']) ?? "Skills";
              final String? otherPhone = isMeSender ? data['toPhone'] : data['fromPhone'];

              return FutureBuilder<UserModel?>(
                future: firestoreService.getUserProfile(isMeSender ? data['toUid'] : data['fromUid']),
                builder: (context, profileSnapshot) {
                  final String finalName = profileSnapshot.data?.name ?? otherName;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                        child: const Icon(Icons.handshake, color: Color(0xFF6C63FF)),
                      ),
                      title: Text(finalName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Exchange: $mySkill ↔ $theirSkill", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                            const SizedBox(height: 4),
                            const Text("Tap to view connection hub", style: TextStyle(fontSize: 12, color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MatchDetailScreen(
                              otherName: finalName,
                              mySkill: mySkill,
                              theirSkill: theirSkill,
                              chatId: matches[index].id,
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No matches yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text("Start exploring and requesting swaps!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
