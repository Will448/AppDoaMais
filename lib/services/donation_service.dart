import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Serviço responsável por gerenciar doações via API.
class DonationService {
  final String apiUrl;

  DonationService({required this.apiUrl});

  Future<Map<String, dynamic>> registrarDoacao({
    required String campaignId,
    required String userId,
    required double amount,
    required String paymentMethod,
    String? donorName,
    String? cpf,
  }) async {
    if (apiUrl.isEmpty) {
      return _errorResponse("URL da API não configurada");
    }

    final validationError = _validarParametros(
      campaignId: campaignId,
      userId: userId,
      amount: amount,
      paymentMethod: paymentMethod,
      donorName: donorName,
      cpf: cpf,
    );

    if (validationError != null) {
      return _errorResponse(validationError);
    }

    final queryParameters = {
      'campaign_id': campaignId,
      'user_id': userId,
      'payment_method': paymentMethod,
      'amount': amount.toStringAsFixed(2),
      if (donorName != null && donorName.isNotEmpty) 'name': donorName,
      if (cpf != null && cpf.isNotEmpty) 'cpf': cpf,
    };

    final url = Uri.parse('$apiUrl/donations/pagamento').replace(queryParameters: queryParameters);

    developer.log(
      '📤 Registrando doação: $paymentMethod - R\$ ${amount.toStringAsFixed(2)} para campanha $campaignId',
      name: 'DonationService',
    );
    developer.log('🔗 URL: $url', name: 'DonationService');

    try {
      final response = await http.get(url);
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      developer.log(
        '📥 Resposta recebida: ${response.statusCode}',
        name: 'DonationService',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Doação processada com sucesso!',
          'data': responseBody,
        };
      } else {
        return _errorResponse(
          responseBody['error'] ?? 'Ocorreu uma falha no servidor.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      developer.log(
        '❌ Erro de conexão: ${e.toString()}',
        name: 'DonationService',
        error: e,
      );
      return _errorResponse('Não foi possível conectar ao servidor. Verifique sua conexão.');
    }
  }

  Future<Map<String, dynamic>> getDonationHistory({
    required String userId,
  }) async {
    if (apiUrl.isEmpty) {
      return _errorResponse("URL da API não configurada");
    }
    if (userId.isEmpty) {
      return _errorResponse("ID do usuário é obrigatório para buscar o histórico.");
    }

    final url = Uri.parse('$apiUrl/donations/user/$userId');
    developer.log('📤 Buscando histórico de doações para o usuário: $userId', name: 'DonationService');
    developer.log('🔗 URL: $url', name: 'DonationService');

    try {
      final response = await http.get(url);
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      developer.log(
        '📥 Resposta do histórico: ${response.statusCode}',
        name: 'DonationService',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'donations': responseBody, // A API deve retornar uma lista de doações
        };
      } else {
        return _errorResponse(
          responseBody['error'] ?? 'Falha ao buscar o histórico de doações.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      developer.log(
        '❌ Erro de conexão ao buscar histórico: ${e.toString()}',
        name: 'DonationService',
        error: e,
      );
      return _errorResponse('Não foi possível conectar ao servidor. Verifique sua conexão.');
    }
  }

  Map<String, dynamic> _errorResponse(String message, {int? statusCode}) {
    return {
      'success': false,
      'message': message,
      'statusCode': statusCode,
    };
  }

  String? _validarParametros({
    required String campaignId,
    required String userId,
    required double amount,
    required String paymentMethod,
    String? donorName,
    String? cpf,
  }) {
    if (campaignId.isEmpty) {
      return 'ID da campanha é obrigatório';
    }
    if (userId.isEmpty) {
      return 'ID do usuário é obrigatório';
    }
    if (amount <= 0) {
      return 'Valor da doação deve ser maior que zero';
    }

    if (donorName != null && donorName.isNotEmpty) {
      if (cpf == null || cpf.length != 11) {
        return 'CPF deve ter 11 dígitos para doações não anônimas.';
      }
    }

    const validPaymentMethods = ['pix', 'credito', 'debito'];
    if (!validPaymentMethods.contains(paymentMethod)) {
      return 'Método de pagamento inválido: $paymentMethod';
    }

    return null; // Sem erros
  }
}
