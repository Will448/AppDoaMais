import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptService {
  static Future<Uint8List> generateReceipt({
    required String donorName,
    required String cpf,
    required double amount,
    required String paymentMethod,
    required DateTime date,
    required String campaignName,
  }) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      // Formatar CPF
      String formatCPF(String cpf) {
        if (cpf.length == 11) {
          return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
        }
        return cpf;
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RECIBO DE DOACAO',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Plataforma Doa+',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                // Dados do doador
                pw.Text(
                  'DADOS DO DOADOR',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Nome: $donorName', style: pw.TextStyle(fontSize: 12)),
                pw.Text(
                  'CPF: ${formatCPF(cpf)}',
                  style: pw.TextStyle(fontSize: 12),
                ),

                pw.SizedBox(height: 20),

                // Dados da doação
                pw.Text(
                  'DADOS DA DOACAO',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Campanha: $campaignName',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Forma de pagamento: $paymentMethod',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Data: ${dateFormat.format(date)}',
                  style: pw.TextStyle(fontSize: 12),
                ),

                pw.SizedBox(height: 24),

                // Valor destacado
                pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green, width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'VALOR DOADO',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'R\$ ${amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(height: 24),

                // Mensagem de agradecimento
                pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'Agradecemos sua contribuicao! Este recibo confirma a doacao realizada por meio do aplicativo Doa+. Sua generosidade faz a diferenca!',
                    style: pw.TextStyle(fontSize: 11),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),

                pw.Spacer(),

                // Rodapé
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Doa+ - Plataforma de Doacoes Digitais',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Documento gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ),
              ],
            );
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      print('Erro ao gerar PDF: $e');
      rethrow;
    }
  }
}
