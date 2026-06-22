import 'package:dio/dio.dart';
import '../core/constants.dart';

// Message model
enum MessageRole { user, model }

class ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

// AiService

class AiService {
  AiService._();
  static final AiService instance = AiService._();
  factory AiService() => instance;

  final Dio _dio = Dio();

  static const String _systemPrompt = '''
You are Krishok AI (কৃষক AI), an expert agricultural assistant for farmers in Bangladesh.

Your role:
- Answer questions about crop farming, cultivation techniques, and best practices
- Help diagnose crop diseases and pest problems based on symptoms described
- Recommend remedies, pesticides, and fertilizers suitable for Bangladesh
- Provide advice on soil health, irrigation, and seasonal farming
- Give guidance on crop selection based on region, season, and soil type
- Help with equipment usage and maintenance questions
- Advise on post-harvest storage and market pricing

Rules:
- ONLY answer agricultural questions. If asked about anything unrelated to farming, agriculture, crops, soil, weather, or rural livelihoods, politely decline and redirect to agricultural topics.
- Keep answers practical and relevant to smallholder farmers in Bangladesh.
- When responding in Bengali, use simple, clear language that rural farmers can understand — avoid overly formal or academic Bengali.
- When recommending pesticides or chemicals, always mention safety precautions.
- If you are unsure about something, say so clearly rather than guessing.
''';

  Future<String> sendMessage({
    required String userMessage,
    required List<ChatMessage> history,
    required bool inBengali,
  }) async {
    final languageInstruction = inBengali
        ? 'Respond in Bengali (বাংলা). Use simple, clear Bengali.'
        : 'Respond in English. Keep it simple and practical.';

    const url = '${AppConstants.groqApiUrl}/chat/completions';

    final response = await _dio.post(
      url,
      data: {
        'model': AppConstants.groqModel,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          ...history.map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.text,
              }),
          {'role': 'user', 'content': '$userMessage\n\n[$languageInstruction]'},
        ],
        'max_tokens': 1024,
        'temperature': 0.7,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.groqApiKey}',
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    return response.data['choices'][0]['message']['content'] as String;
  }
}
