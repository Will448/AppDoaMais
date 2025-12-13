import 'package:http/http.dart' as http;
import '../model/qr_model.dart';

class QrService {
  static const String _baseUrl =
      'https://api.qrserver.com/v1/create-qr-code/';

  Future<QrCode> gerarQrCode(String texto) async {
    final uri = Uri.parse(
      '$_baseUrl?size=300x300&data=${Uri.encodeComponent(texto)}',
    );

    final resposta = await http.get(uri);

    if (resposta.statusCode == 200) {
      return QrCode(imageBytes: resposta.bodyBytes);
    } else {
      throw Exception(
        'Erro ao gerar QR Code',
      ); 
    }
  }
}
