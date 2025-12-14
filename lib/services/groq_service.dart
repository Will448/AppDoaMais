import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class GroqService {
  final String apiKey;

  static const String _baseUrl = "https://api.groq.com/openai/v1";

  GroqService({required this.apiKey});

  Future<String> gerarInsight(String prompt) async {
    if (apiKey.isEmpty) {
      return "API_KEY não encontrada. Verifique seu .env";
    }

    final mensagens = [
      {"role": "user", "content": prompt},
    ];

    final body = {
      "model": "llama-3.1-8b-instant",
      "temperature": 1,
      "max_tokens": 100,
      "messages": mensagens,
    };

    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/chat/completions"),
        headers: headers,
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final content = responseBody["choices"]?[0]?["message"]?["content"];

        return content?.toString().trim().isNotEmpty == true
            ? content.toString().trim()
            : "Sem conteúdo na resposta.";
      } else {
        return "Erro ${response.statusCode}: ${responseBody['error']?['message'] ?? response.body}";
      }
    } catch (e, s) {
      developer.log(
        'Erro inesperado na chamada da API Groq',
        name: 'GroqService',
        error: e,
        stackTrace: s,
      );
      return "Desculpe, não foi possível gerar o insight no momento.";
    }
  }
}
