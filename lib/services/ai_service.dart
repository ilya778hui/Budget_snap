import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static Future<String> askFinancialQuestion({
    required String userMessage,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception('API ключ не найден');

    final messages = [
      ...?conversationHistory,
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-5',
        'max_tokens': 1024,
        'system': '''Ты финансовый помощник для подростков в Казахстане. 
Отвечай на русском языке, простым языком. 
Используй примеры с тенге, играми, едой — то что близко подросткам.
Давай конкретные советы по накоплению и тратам.''',
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Ошибка API: ${error['error']['message']}');
    }
  }
}