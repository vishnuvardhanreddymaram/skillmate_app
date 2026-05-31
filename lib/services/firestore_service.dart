import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Profiles ---

  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<UserModel?> getUserProfile(String uid) async {
    var snapshot = await _db.collection('users').doc(uid).get();
    if (snapshot.exists) {
      return UserModel.fromMap(snapshot.data()!, snapshot.id);
    }
    return null;
  }

  Stream<List<UserModel>> getDiscoverFeed(String currentUserId) {
    return _db.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .where((user) {
            // Exclude current user
            if (user.uid == currentUserId) return false;
            // Exclude unwanted/incomplete profiles
            if (user.name.trim().isEmpty || user.email.trim().isEmpty) return false;
            if (user.skillsHave.trim().isEmpty) return false;
            return true;
          })
          .toList();
      
      // Sort alphabetically for a stable UI
      users.sort((a, b) => a.name.compareTo(b.name));
      return users;
    });
  }

  // --- Swap Requests & Matches ---

  Future<void> sendSwapRequest({
    required String fromUid,
    required String fromName,
    required String fromSkills,
    String? fromPhone,
    required String toUid,
    required String toName,
    required String toSkills,
    String? toPhone,
  }) async {
    // Check if a request already exists in either direction
    final existingFromMe = await _db
        .collection('requests')
        .where('fromUid', isEqualTo: fromUid)
        .where('toUid', isEqualTo: toUid)
        .get();

    final existingFromThem = await _db
        .collection('requests')
        .where('fromUid', isEqualTo: toUid)
        .where('toUid', isEqualTo: fromUid)
        .get();

    if (existingFromMe.docs.isEmpty && existingFromThem.docs.isEmpty) {
      await _db.collection('requests').add({
        'fromUid': fromUid,
        'fromName': fromName,
        'fromSkills': fromSkills,
        'fromPhone': fromPhone,
        'toUid': toUid,
        'toName': toName,
        'toSkills': toSkills,
        'toPhone': toPhone,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<QuerySnapshot> getSwapRequests(String toUid) {
    return _db
        .collection('requests')
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getMyMatches(String uid) {
    return _db
        .collection('requests')
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  Future<void> acceptSwapRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({'status': 'accepted'});
  }

  Future<void> rejectSwapRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({'status': 'rejected'});
  }

  // --- Chat / Messaging ---

  Future<void> sendMessage(String chatId, String senderUid, String text) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderUid': senderUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    await _db.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Also update the request document to show last message in the list
    await _db.collection('requests').doc(chatId).update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderUid,
      'isRead': false, // Mark as unread for the receiver
    });
  }

  Future<void> markMessageAsRead(String chatId) async {
    await _db.collection('requests').doc(chatId).update({
      'isRead': true,
    });
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // --- Delete Messages ---

  Future<void> deleteMessageForEveryone(String chatId, String messageId) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> deleteMessageForMe(String chatId, String messageId, String userId) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'hiddenFor': FieldValue.arrayUnion([userId])
    });
  }

  // --- AI Chat ---

  Future<void> sendAIMessage(String userId, String text, bool isMe) async {
    await _db.collection('users').doc(userId).collection('ai_messages').add({
      'text': text,
      'isMe': isMe,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAIMessages(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('ai_messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
