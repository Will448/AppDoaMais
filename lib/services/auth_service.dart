
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class AuthService {
  final String baseUrl;

  AuthService({required this.baseUrl});

  Future<Map<String, dynamic>> login(String email, String password) async {
    if (baseUrl.isEmpty) {
      return {'success': false, 'message': 'API_URL não configurada.'};
    }

    try {
      final url = Uri.parse('$baseUrl/users/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = data['user'] ?? data['session']?['user'];
        if (user == null) {
          return {'success': false, 'message': 'Dados de usuário ausentes.'};
        }
        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Email ou senha inválidos.'};
      }
    } catch (e) {
      developer.log("Erro de login no serviço: $e");
      return {'success': false, 'message': 'Erro ao conectar ao servidor: $e'};
    }
  }
}
