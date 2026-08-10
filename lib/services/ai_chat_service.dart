import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class AiChatMessage {
  final String role; // 'system', 'user', 'assistant'
  final String content;

  AiChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {
        'role': role,
        'content': content,
      };
}

class AiChatService {
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';
  static const String _systemInstruction =
      "You are Gymyzio's AI Fitness Coach. Give helpful, safe, encouraging advice about exercises, workout form, basic nutrition tips, and motivation. Keep answers concise and beginner-friendly. If asked about medical conditions, injuries, or anything requiring professional medical advice, tell the user to consult a doctor or certified trainer instead of guessing.";

  /// Sends the conversation messages to Groq API and returns the AI's response text.
  Future<String> sendMessage(List<AiChatMessage> history) async {
    try {
      final messages = [
        AiChatMessage(role: 'system', content: _systemInstruction).toJson(),
        ...history.map((msg) => msg.toJson()),
      ];

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final content = decoded['choices']?[0]?['message']?['content'];
        if (content != null && content.toString().trim().isNotEmpty) {
          return content.toString().trim();
        }
      }

      // Handle specific error codes if needed
      if (response.statusCode == 401) {
        return "I'm currently undergoing maintenance (API Key configuration needed). Please try again shortly! 💪";
      }

      return "I'm having trouble retrieving a response right now. Please try again in a moment! 💪";
    } catch (e) {
      return "I'm sorry, I couldn't process your request right now. Please check your internet connection or try again in a moment. 💪";
    }
  }
}
