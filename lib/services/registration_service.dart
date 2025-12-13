import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class RegistrationService {
  final String baseUrl;

  RegistrationService({required this.baseUrl});

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String cpf,
  }) async {
    if (baseUrl.isEmpty) {
      return {'success': false, 'message': 'API_URL não configurada.'};
    }

    try {
      final url = Uri.parse('$baseUrl/users');
      final body = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password.trim(),
        'cpf': cpf.replaceAll(RegExp(r'[.-]'), ''),
      };

      developer.log("📤 ENVIANDO PARA: $url", name: 'RegistrationService');
      developer.log("📦 DADOS: ${jsonEncode(body)}", name: 'RegistrationService');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      developer.log("📥 STATUS CODE: ${response.statusCode}", name: 'RegistrationService');
      developer.log("📥 RESPOSTA: ${response.body}", name: 'RegistrationService');

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = data['user'];
        return {'success': true, 'user': user, 'message': data['message'] ?? 'Registro bem-sucedido!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Ocorreu um erro no registro.'};
      }
    } catch (e) {
      developer.log("Erro no serviço de registro: $e", name: 'RegistrationService');
      return {'success': false, 'message': 'Erro ao conectar ao servidor: $e'};
    }
  }
}
