import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _defaultModel = 'gemini-1.5-flash';

  Future<String> getGeminiResponse({
    required String prompt,
    required String apiKey,
    List<Map<String, dynamic>> chatHistory = const [],
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent?key=$apiKey',
    );

    // Build the request body with system instructions and chat history
    final List<Map<String, dynamic>> contents = [];

    // System instruction to guide the AI to act as the SkillMate Assistant
    final systemInstruction = {
      "parts": [
        {
          "text": "You are the SkillMate AI Assistant, a friendly and helpful guide for the SkillMate app. "
              "SkillMate is a peer-to-peer skill-sharing and freelancing platform where users swap skills "
              "(e.g., teaching Python in exchange for learning cooking). "
              "Answer questions about how the app works, give suggestions for skill swapping, provide safety tips "
              "(meeting in public, checking reviews, starting with video calls), and encourage users to build their profiles "
              "to get matches. Keep your tone encouraging, professional, and friendly. Use formatting like bullet points and emojis to make it readable."
        }
      ]
    };

    // Add history (Gemini format: role is 'user' or 'model')
    // We reverse or iterate to format correctly. Note: in firestore, we retrieved reverse order (latest first), 
    // but when we pass to Gemini we want chronological order (oldest first).
    // Let's filter and add them.
    for (var message in chatHistory.reversed) {
      final isMe = message['isMe'] as bool? ?? false;
      contents.add({
        "role": isMe ? "user" : "model",
        "parts": [
          {"text": message['text'] as String? ?? ""}
        ]
      });
    }

    // Add current user message
    contents.add({
      "role": "user",
      "parts": [
        {"text": prompt}
      ]
    });

    final body = {
      "contents": contents,
      "systemInstruction": systemInstruction,
      "generationConfig": {
        "temperature": 0.7,
        "maxOutputTokens": 800,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text;
    } else {
      final errorData = jsonDecode(response.body);
      final message = errorData['error']?['message'] ?? 'Unknown API error';
      throw Exception('Gemini API Error: $message');
    }
  }
}
