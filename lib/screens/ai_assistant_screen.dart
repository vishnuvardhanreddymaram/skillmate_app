import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  String? _customApiKey;
  String? _firestoreApiKey;
  bool _loadingKey = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    if (!mounted) return;
    setState(() => _loadingKey = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _customApiKey = prefs.getString('custom_gemini_api_key');
    } catch (e) {
      debugPrint("Error loading SharedPreferences: $e");
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('gemini')
          .get();
      if (doc.exists) {
        _firestoreApiKey = doc.data()?['apiKey'] as String?;
      }
    } catch (e) {
      debugPrint("Error loading firestore config: $e");
    }

    if (mounted) {
      setState(() => _loadingKey = false);
    }
  }

  Future<void> _launchAIStudio() async {
    final Uri url = Uri.parse('https://aistudio.google.com/app/apikey');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Launch URL error: $e');
    }
  }

  void _showKeyDialog() {
    final controller = TextEditingController(text: _customApiKey);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: Color(0xFF6C63FF)),
              SizedBox(width: 10),
              Text("Gemini API Key", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Save your personal Gemini API Key on this device to use the AI Assistant.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: "API Key",
                  hintText: "AIzaSy...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.key, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _launchAIStudio,
                child: const Text(
                  "Get a free API Key from Google AI Studio",
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);
                final key = controller.text.trim();
                final prefs = await SharedPreferences.getInstance();
                if (key.isEmpty) {
                  await prefs.remove('custom_gemini_api_key');
                  _customApiKey = null;
                } else {
                  await prefs.setString('custom_gemini_api_key', key);
                  _customApiKey = key;
                }
                navigator.pop();
                _loadKeys();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text("Gemini API key saved!"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _handleSend() async {
    if (_controller.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final activeKey = _customApiKey ?? _firestoreApiKey;
    if (activeKey == null || activeKey.isEmpty) {
      _showKeyDialog();
      return;
    }

    final userMessage = _controller.text.trim();
    _controller.clear();

    await _firestoreService.sendAIMessage(user.uid, userMessage, true);

    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      final historySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_messages')
          .orderBy('timestamp', descending: true)
          .limit(15)
          .get();

      final List<Map<String, dynamic>> chatHistory = [];
      for (var doc in historySnapshot.docs) {
        chatHistory.add({
          'text': doc.data()['text'] ?? '',
          'isMe': doc.data()['isMe'] ?? false,
        });
      }

      final response = await _geminiService.getGeminiResponse(
        prompt: userMessage,
        apiKey: activeKey,
        chatHistory: chatHistory,
      );

      await _firestoreService.sendAIMessage(user.uid, response, false);
    } catch (e) {
      debugPrint("AI Query failed: $e");
      String friendlyError = "I'm sorry, I'm having trouble connecting right now. Make sure your API key is valid and you have an active internet connection.";
      if (e.toString().contains("API key not valid")) {
        friendlyError = "Your Gemini API key appears to be invalid. Please click the key icon at the top to reconfigure it.";
      }
      await _firestoreService.sendAIMessage(user.uid, friendlyError, false);
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
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

  Widget _buildKeyWarningBanner() {
    final hasKey = (_customApiKey?.isNotEmpty ?? false) || (_firestoreApiKey?.isNotEmpty ?? false);

    if (hasKey || _loadingKey) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Assistant Not Configured",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 13),
                ),
                const Text(
                  "Please set your Gemini API key to start chatting.",
                  style: TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showKeyDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Setup Key", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SkillMate AI", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded),
            onPressed: _showKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildKeyWarningBanner(),
          Expanded(
            child: user == null
                ? const Center(child: Text("Please sign in to use AI Assistant"))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getAIMessages(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty && !_loadingKey) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  "Start a conversation!",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
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
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("AI is thinking...", style: TextStyle(fontStyle: FontStyle.italic)),
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



import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();
  final ScrollController _scrollController = ScrollController();
  
  bool _isTyping = false;
  String? _customApiKey;
  String? _firestoreApiKey;
  bool _loadingKey = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    if (!mounted) return;
    setState(() => _loadingKey = true);

    // 1. Fetch custom key from local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      _customApiKey = prefs.getString('custom_gemini_api_key');
    } catch (e) {
      debugPrint("Error loading SharedPreferences: $e");
    }

    // 2. Fetch shared key from Firestore (config/gemini)
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('gemini').get();
      if (doc.exists) {
        _firestoreApiKey = doc.data()?['apiKey'] as String?;
      }
    } catch (e) {
      debugPrint("Error loading firestore config: $e");
    }

    if (mounted) {
      setState(() => _loadingKey = false);
    }
  }

  Future<void> _launchAIStudio() async {
    final Uri url = Uri.parse('https://aistudio.google.com/app/apikey');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Launch URL error: $e');
    }
  }

  void _showKeyDialog() {
    final controller = TextEditingController(text: _customApiKey);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: Color(0xFF6C63FF)),
              SizedBox(width: 10),
              Text("Gemini API Key", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Save your personal Gemini API Key on this device to use the AI Assistant.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: "API Key",
                  hintText: "AIzaSy...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.key, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _launchAIStudio,
                child: const Text(
                  "Get a free API Key from Google AI Studio",
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);
                final key = controller.text.trim();
                final prefs = await SharedPreferences.getInstance();
                if (key.isEmpty) {
                  await prefs.remove('custom_gemini_api_key');
                  _customApiKey = null;
                } else {
                  await prefs.setString('custom_gemini_api_key', key);
                  _customApiKey = key;
                }
                navigator.pop();
                _loadKeys();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text("Gemini API key saved!"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _handleSend() async {
    if (_controller.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final activeKey = _customApiKey ?? _firestoreApiKey;
    if (activeKey == null || activeKey.isEmpty) {
      _showKeyDialog();
      return;
    }

    final userMessage = _controller.text.trim();
    _controller.clear();

    // Save user message to Firestore
    await _firestoreService.sendAIMessage(user.uid, userMessage, true);

    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      // Fetch last 15 messages for context
      final historySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_messages')
          .orderBy('timestamp', descending: true)
          .limit(15)
          .get();

      final List<Map<String, dynamic>> chatHistory = [];
      for (var doc in historySnapshot.docs) {
        chatHistory.add({
          'text': doc.data()['text'] ?? '',
          'isMe': doc.data()['isMe'] ?? false,
        });
      }

      // Query Gemini
      final response = await _geminiService.getGeminiResponse(
        prompt: userMessage,
        apiKey: activeKey,
        chatHistory: chatHistory,
      );

      // Save AI response to Firestore
      await _firestoreService.sendAIMessage(user.uid, response, false);
    } catch (e) {
      debugPrint("AI Query failed: $e");
      String friendlyError = "I'm sorry, I'm having trouble connecting right now. Make sure your API key is valid and you have an active internet connection.";
      if (e.toString().contains("API key not valid")) {
        friendlyError = "Your Gemini API key appears to be invalid. Please click the key icon at the top to reconfigure it.";
      }
      await _firestoreService.sendAIMessage(user.uid, friendlyError, false);
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
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

  Widget _buildKeyWarningBanner() {
    final hasKey = (_customApiKey != null && _customApiKey!.isNotEmpty) ||
        (_firestoreApiKey != null && _firestoreApiKey!.isNotEmpty);

    if (hasKey || _loadingKey) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Assistant Not Configured",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                ),
                Text(
                  "Please set your Gemini API key to start chatting.",
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showKeyDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Setup Key", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SkillMate AI", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded),
            onPressed: _showKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildKeyWarningBanner(),
          Expanded(
            child: user == null
                ? const Center(child: Text("Please sign in to use AI Assistant"))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getAIMessages(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      
                      if (docs.isEmpty && !_loadingKey) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  "Start a conversation!",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
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
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("AI is thinking...", style: TextStyle(fontStyle: FontStyle.italic)),
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
