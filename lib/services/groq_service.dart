import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

// Serviço responsável por interagir com a API da Groq.
class GroqService {
  // Chave de API usada no header Authorization.
  final String apiKey;

  // URL base da API da Groq.
  static const String _baseUrl = "https://api.groq.com/openai/v1";

  // Construtor: exige a chave da API.
  GroqService({required this.apiKey});

  // Método que gera um insight chamando o endpoint de chat.
  Future<String> gerarInsight(String prompt) async {
    // Valida se a API key foi informada.
    if (apiKey.isEmpty) {
      return "API_KEY não encontrada. Verifique seu .env";
    }

    // Monta a lista de mensagens no formato do endpoint de chat.
    final mensagens = [
      {"role": "user", "content": prompt},
    ];

    // Corpo da requisição para o endpoint /chat/completions.
    final body = {
      "model": "llama-3.1-8b-instant",
      "temperature": 1,
      "max_tokens": 100,
      "messages": mensagens,
    };

    // Cabeçalhos da requisição.
    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };

    try {
      // Faz a requisição POST para o endpoint de chat.
      final response = await http.post(
        Uri.parse("$_baseUrl/chat/completions"),
        headers: headers,
        body: jsonEncode(body),
      );

      // Decodifica o corpo da resposta.
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // Extrai o conteúdo da primeira escolha.
        final content = responseBody["choices"]?[0]?["message"]?["content"];

        // Retorna o conteúdo ou uma mensagem padrão.
        return content?.toString().trim().isNotEmpty == true
            ? content.toString().trim()
            : "Sem conteúdo na resposta.";
      } else {
        // Retorna uma mensagem de erro com o status e a descrição do erro.
        return "Erro ${response.statusCode}: ${responseBody['error']?['message'] ?? response.body}";
      }
    } catch (e, s) {
      // Fallback para qualquer exceção inesperada (ex: problemas de rede).
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
