import 'dart:typed_data';

class QrCode {
  final Uint8List imageBytes;

  QrCode({
    required this.imageBytes,
  }); //construtor que recebe os bytes da imagem do QR Code
}
