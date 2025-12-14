import 'package:http/http.dart' as http;
import '../model/qr_model.dart';

class QrService {
  static const String _baseUrl =
      'https://api.qrserver.com/v1/create-qr-code/'; //URL da API pública, sendo um
  //método para gerar o QR Code, recebe um texto e retorna um objeto QrCode contendo a imagem em bytes

  Future<QrCode> gerarQrCode(String texto) async {
    final uri = Uri.parse(
      '$_baseUrl?size=300x300&data=${Uri.encodeComponent(texto)}', //construção da URL com parâmetros de tamanho e dados do QR Code
    );

    final resposta = await http.get(uri); //requisição GET para a API pública

    if (resposta.statusCode == 200) {
      //se a resposta for bem-sucedida, cria e retorna o objeto QrCode com os bytes da imagem
      return QrCode(imageBytes: resposta.bodyBytes);
    } else {
      throw Exception(
        'Erro ao gerar QR Code',
      ); //em caso de erro, lança uma exceção
    }
  }
}
