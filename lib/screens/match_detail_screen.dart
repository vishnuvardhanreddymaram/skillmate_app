import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_room_screen.dart';

class MatchDetailScreen extends StatelessWidget {
  final String otherName;
  final String mySkill;
  final String theirSkill;
  final String? phoneNumber;
  final String chatId;

  const MatchDetailScreen({
    super.key,
    required this.otherName,
    required this.mySkill,
    required this.theirSkill,
    required this.chatId,
    this.phoneNumber,
  });

  void _launchCaller() async {
    if (phoneNumber == null) return;
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Connection Hub", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                    child: const Icon(Icons.person, size: 50, color: Color(0xFF6C63FF)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "You matched with $otherName!",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text("Ready to start swapping skills?", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionBtn(Icons.chat, "Chat", () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(
                          userName: otherName,
                          chatId: chatId,
                          swapSummary: "Swap: $mySkill for $theirSkill",
                        )));
                      }),
                      const SizedBox(width: 20),
                      _buildActionBtn(Icons.phone, "Call", _launchCaller, enabled: phoneNumber != null),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("THE SWAP PLAN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  _buildSwapCard("I am teaching", mySkill, Icons.school, Colors.green),
                  const SizedBox(height: 12),
                  _buildSwapCard("I am learning", theirSkill, Icons.auto_stories, Colors.orange),
                  const SizedBox(height: 32),
                  const Text("HOW TO GET STARTED", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  _buildStep(1, "Message $otherName to introduce yourself and fix a teaching time."),
                  _buildStep(2, "Decide on a platform (Zoom, Google Meet, or In-person)."),
                  _buildStep(3, "Share your first lesson and have fun swapping!"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap, {bool enabled = true}) {
    return Column(
      children: [
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFF6C63FF) : Colors.grey.shade300,
              shape: BoxShape.circle,
              boxShadow: enabled ? [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))] : [],
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: enabled ? Colors.black : Colors.grey)),
      ],
    );
  }

  Widget _buildSwapCard(String title, String skill, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(skill, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, backgroundColor: const Color(0xFF6C63FF), child: Text(num.toString(), style: const TextStyle(fontSize: 12, color: Colors.white))),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87))),
        ],
      ),
    );
  }
}
