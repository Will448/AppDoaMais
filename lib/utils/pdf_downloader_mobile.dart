import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> downloadPdf(Uint8List pdfData, String filename) async {
  try {
    // Obter diretório de documentos do app
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';

    // Salvar arquivo
    final file = File(filePath);
    await file.writeAsBytes(pdfData);

    // Abrir o PDF automaticamente
    final result = await OpenFile.open(filePath);

    if (result.type != ResultType.done) {
      throw Exception('Não foi possível abrir o PDF: ${result.message}');
    }
  } catch (e) {
    throw Exception('Erro ao salvar/abrir PDF: $e');
  }
}