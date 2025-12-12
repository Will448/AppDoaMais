import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

class GoogleAuthService {
  final String baseUrl;
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({required this.baseUrl, required GoogleSignIn googleSignIn})
      : _googleSignIn = googleSignIn {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    final serverClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'];
    unawaited(_googleSignIn.initialize(
      serverClientId: serverClientId,
    ).then((_) {
      _googleSignIn.attemptLightweightAuthentication();
    }).catchError((e) {
      if (kDebugMode) {
        developer.log('Google Sign-In initialization error in service: $e', name: 'GoogleAuthService');
      }
    }));
  }

  Future<Map<String, dynamic>> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.authenticate();

      if (account == null) {
        return {'success': false, 'message': 'Login com Google cancelado.'};
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return {'success': false, 'message': 'Não foi possível obter o token do Google.'};
      }

      return await _sendTokenToBackend(idToken);
    } catch (e) {
      developer.log('Erro no Google Sign-In Service: $e', name: 'GoogleAuthService');
      return {'success': false, 'message': 'Falha ao fazer login com Google: $e'};
    }
  }

  Future<Map<String, dynamic>> _sendTokenToBackend(String idToken) async {
    if (baseUrl.isEmpty) {
      return {'success': false, 'message': 'API_URL não configurada.'};
    }

    try {
      final url = Uri.parse('$baseUrl/users/auth/google/token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': idToken}),
      );

      final data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final user = data['user'] ?? data['session']?['user'];
        if (user == null) {
          return {'success': false, 'message': 'Dados de usuário ausentes no backend.'};
        }
        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erro ao autenticar no backend.'};
      }
    } catch (e) {
      developer.log('Erro ao enviar token para o backend: $e', name: 'GoogleAuthService');
      return {'success': false, 'message': 'Erro ao conectar ao backend: $e'};
    }
  }
}
