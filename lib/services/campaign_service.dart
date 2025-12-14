import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CampaignService {
  final String? _apiUrl = dotenv.env['API_URL'];
  final String? _globalGivingApiKey = dotenv.env['GLOBALGIVING_API_KEY'];

  void _handleApiError(http.Response response, String functionName) {
    developer.log(
      'Erro na API em $functionName: ${response.statusCode}', 
      name: 'CampaignService',
      error: response.body
    );
    throw Exception('Erro em $functionName: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createCampaign({
    required String title,
    required String description,
    required double goalAmount,
    required String userId,
  }) async {
    if (_apiUrl == null || _apiUrl.isEmpty) {
      throw Exception('URL da API não configurada');
    }

    final response = await http.post(
      Uri.parse('$_apiUrl/campaigns'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'goal_amount': goalAmount,
        'user_id': userId,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      _handleApiError(response, 'createCampaign');
      return {}; 
    }
  }

  Future<void> updateCampaign({
    required String campaignId,
    required String title,
    required String description,
    required double goalAmount,
  }) async {
    if (_apiUrl == null || _apiUrl.isEmpty) {
      throw Exception('URL da API não configurada');
    }
    
    final uri = Uri.parse('$_apiUrl/campaigns/$campaignId').replace(queryParameters: {
      'title': title,
      'description': description,
      'goal_amount': goalAmount.toString(),
    });

    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      _handleApiError(response, 'updateCampaign');
    }
  }

  Future<void> deleteCampaign(String campaignId) async {
    if (_apiUrl == null || _apiUrl.isEmpty) {
      throw Exception('URL da API não configurada');
    }

    final response = await http.delete(Uri.parse('$_apiUrl/campaigns/$campaignId'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      _handleApiError(response, 'deleteCampaign');
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchLocalCampaigns(
      String currentUserId) async {
    if (_apiUrl == null || _apiUrl.isEmpty) {
      throw Exception('URL da API não configurada no arquivo .env');
    }

    try {
      final url = Uri.parse('$_apiUrl/campaigns');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> allCampaignsData = jsonDecode(response.body);
        final List<Map<String, dynamic>> allCampaigns = allCampaignsData.map((item) {
          final campaign = item as Map<String, dynamic>;
          return {
            'id': campaign['id'],
            'user_id': campaign['user_id'],
            'titulo': campaign['title'],
            'descricao': campaign['description'],
            'meta': double.tryParse(campaign['goal_amount'].toString()) ?? 0.0,
            'arrecadado':
                double.tryParse(campaign['current_amount']?.toString() ?? '0.0') ??
                    0.0,
            'imagem': 'images/doacao.jpg',
            'isLocal': true,
          };
        }).toList();

        final minhas = allCampaigns
            .where((c) => c['user_id'] == currentUserId)
            .toList();
        final outras = allCampaigns
            .where((c) => c['user_id'] != currentUserId)
            .toList();

        return {'myCampaigns': minhas, 'otherCampaigns': outras};
      } else {
        _handleApiError(response, 'fetchLocalCampaigns');
        return {'myCampaigns': [], 'otherCampaigns': []}; // Retorno para análise estática
      }
    } catch (e) {
      developer.log('Erro ao buscar campanhas locais: $e', name: 'CampaignService');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchGlobalCampaigns() async {
    if (_globalGivingApiKey == null || _globalGivingApiKey.isEmpty) {
      throw Exception('GLOBALGIVING_API_KEY não encontrada no .env');
    }

    try {
      final url = Uri.parse(
        'https://api.globalgiving.org/api/public/projectservice/all/projects/active?api_key=$_globalGivingApiKey',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final projects = document.findAllElements('project');

        return projects.take(5).map((project) {
          return {
            'id': project.findElements('id').firstOrNull?.innerText ?? '',
            'titulo':
                project.findElements('title').firstOrNull?.innerText ?? 'Sem título',
            'descricao':
                project.findElements('summary').firstOrNull?.innerText ??
                    'Sem descrição',
            'imagem':
                project.findElements('imageLink').firstOrNull?.innerText ?? '',
            'meta': double.tryParse(
                    project.findElements('goal').firstOrNull?.innerText ?? '0') ??
                0.0,
            'arrecadado': double.tryParse(
                    project.findElements('funding').firstOrNull?.innerText ?? '0') ??
                0.0,
            'url': project.findElements('projectLink').firstOrNull?.innerText ?? '',
            'organizacao': project
                    .findElements('organization')
                    .firstOrNull
                    ?.findElements('name')
                    .firstOrNull
                    ?.innerText ??
                '',
            'isLocal': false,
          };
        }).toList();
      } else {
         _handleApiError(response, 'fetchGlobalCampaigns');
         return [];
      }
    } catch (e) {
      developer.log('Erro ao buscar campanhas globais: $e',
          name: 'CampaignService');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCampaignById(String campaignId) async {
    if (_apiUrl == null || _apiUrl.isEmpty) {
      developer.log('URL da API não configurada', name: 'CampaignService');
      throw Exception('URL da API não configurada');
    }

    final url = Uri.parse('$_apiUrl/campaigns/$campaignId');
    developer.log('Buscando campanha por ID: $url', name: 'CampaignService');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Campanha encontrada: ${data['id']}', name: 'CampaignService');
        return data as Map<String, dynamic>;
      } else {
        developer.log('Erro ao buscar campanha por ID: ${response.statusCode} ${response.body}', name: 'CampaignService');
        throw Exception('Falha ao carregar a campanha: ${response.statusCode}');
      }
    } catch (e, s) {
      developer.log('Exceção ao buscar campanha por ID: $e', name: 'CampaignService', error: e, stackTrace: s);
      rethrow;
    }
  }
}
