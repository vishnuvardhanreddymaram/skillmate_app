import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String userName;
  final String? chatId;
  final String? swapSummary;

  const ChatRoomScreen({super.key, required this.userName, this.chatId, this.swapSummary});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  void _markAsRead() {
    if (widget.chatId != null) {
      _firestoreService.markMessageAsRead(widget.chatId!);
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUser == null) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    final id = widget.chatId ?? "default_chat";
    await _firestoreService.sendMessage(id, currentUser!.uid, text);
  }

  void _sendActionMessage(String text) async {
    if (currentUser == null) return;
    final id = widget.chatId ?? "default_chat";
    await _firestoreService.sendMessage(id, currentUser!.uid, "🚀 $text");
  }

  void _showSwapActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Connection Tools",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose how you want to connect and share knowledge",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionItem(
                  icon: Icons.phone_android_rounded,
                  label: "Share Phone",
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _sendActionMessage("Let's connect via Phone/WhatsApp! My number is: +91 XXXXX XXXXX");
                  },
                ),
                _buildActionItem(
                  icon: Icons.videocam_rounded,
                  label: "Video Call",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _sendActionMessage("Let's have a video session on Google Meet: https://meet.google.com/skill-swap");
                  },
                ),
                _buildActionItem(
                  icon: Icons.calendar_today_rounded,
                  label: "Schedule",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _sendActionMessage("I'm suggesting a skill-sharing session for tomorrow at 5:00 PM. Does that work?");
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showDeleteOptions(String messageId, bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.black),
                title: const Text("Delete for me"),
                onTap: () async {
                  Navigator.pop(context);
                  if (currentUser != null) {
                    await _firestoreService.deleteMessageForMe(
                      widget.chatId ?? "default_chat",
                      messageId,
                      currentUser!.uid,
                    );
                  }
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text("Delete for everyone", style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _firestoreService.deleteMessageForEveryone(
                      widget.chatId ?? "default_chat",
                      messageId,
                    );
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Online", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Swap Summary Header
          if (widget.swapSummary != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: Color(0xFF6C63FF), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.swapSummary!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getMessages(widget.chatId ?? "default_chat"),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text("Start your skill swap conversation\nwith ${widget.userName}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final allMessages = snapshot.data!.docs;
                final messages = allMessages.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final List<dynamic> hiddenFor = data['hiddenFor'] ?? [];
                  return !hiddenFor.contains(currentUser?.uid);
                }).toList();

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final msg = doc.data() as Map<String, dynamic>;
                    final bool isMe = msg['senderUid'] == currentUser?.uid;
                    final String messageId = doc.id;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () => _showDeleteOptions(messageId, isMe),
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF6C63FF) : Colors.white,
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(20),
                              bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(2),
                            ),
                            boxShadow: [
                              if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Text(
                            msg['text'] ?? "",
                            style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6C63FF)),
                          onPressed: _showSwapActions,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
