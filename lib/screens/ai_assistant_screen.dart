import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  void _handleSend() async {
    if (_controller.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userMessage = _controller.text.trim();
    _controller.clear();

    // Save user message to Firestore
    await _firestoreService.sendAIMessage(user.uid, userMessage, true);

    setState(() => _isTyping = true);
    _scrollToBottom();

    // Simulate AI thinking time
    await Future.delayed(const Duration(seconds: 1));

    String response = _getAIResponse(userMessage);

    // Save AI response to Firestore
    await _firestoreService.sendAIMessage(user.uid, response, false);

    if (mounted) {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getAIResponse(String query) {
    query = query.toLowerCase().trim();
    
    // Greetings
    if (query.contains('good morning')) {
      return "Good morning! ☀️ I hope you're ready for some productive skill swapping today. How can I help you clear any doubts?";
    } else if (query.contains('good afternoon')) {
      return "Good afternoon! 🌤️ Looking to learn something new today? Ask me anything about SkillMate!";
    } else if (query.contains('good evening')) {
      return "Good evening! 🌙 It's a great time to connect with other skillmates. What's on your mind?";
    } else if (query.contains('hello') || query.contains('hi') || query.contains('hey')) {
      return "Hello! 👋 I'm your SkillMate Assistant. I'm here to help you find partners, explain features, or just chat about skill swapping. What's up?";
    }
    
    // App Specifics
    else if (query.contains('how') && query.contains('work')) {
      return "It's easy! Find a partner in 'Discover', send a 'Swap Request', and once they accept, you can start chatting to share knowledge. It's a win-win!";
    } else if (query.contains('safe') || query.contains('security') || query.contains('danger')) {
      return "Your safety is our top priority! 🛡️ We recommend checking user reviews, meeting in public places, and starting with a video call. Never share sensitive info!";
    } else if (query.contains('java') || query.contains('c') || query.contains('coding') || query.contains('python')) {
      return "Great choice! We have many experts in Java, C, and Python. Just use the category filters on the Home screen to find them instantly. 💻";
    } else if (query.contains('profile') || query.contains('complete')) {
      return "A complete profile is your best tool! Add a photo, a nice bio, and all your skills. Check your 'Completeness Meter' in the Profile tab to see how you're doing. 📊";
    } else if (query.contains('contact') || query.contains('phone')) {
      return "Once a request is accepted, you can see your partner's phone number in the chat details. This makes it easy to move the conversation to WhatsApp or a call!";
    } else if (query.contains('thank')) {
      return "You're very welcome! 😊 I'm always here if you have more doubts. Happy swapping!";
    }
    
    // Default
    else {
      return "I understand! That's a great point. SkillMate is all about building a community of learners. Is there anything else specific about the app, the features, or the swap process you'd like to know?";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF6C63FF), size: 20),
            SizedBox(width: 8),
            Text("SkillMate AI", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () {
              // Optional: Clear chat history
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: user == null
                ? const Center(child: Text("Please log in to use the AI Assistant"))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getAIMessages(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Show latest at bottom
                        padding: const EdgeInsets.all(20),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return _buildMessage(data['text'] ?? '', data['isMe'] ?? false);
                        },
                      );
                    },
                  ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text("SkillMate AI is thinking...",
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6C63FF) : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: [
            if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Ask about SkillMate...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleSend,
              child: const CircleAvatar(
                backgroundColor: Color(0xFF6C63FF),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
