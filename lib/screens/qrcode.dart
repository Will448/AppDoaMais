import 'dart:typed_data';
import 'package:myapp/services/qr_service.dart';
import 'package:flutter/material.dart';
import '../model/qr_model.dart';

class QrApiExample extends StatefulWidget {
  const QrApiExample({super.key});

  @override
  State<QrApiExample> createState() => _QrApiExampleState();
}

class _QrApiExampleState extends State<QrApiExample> {
  final QrService _qrService =
      QrService();
  final TextEditingController valorController =
      TextEditingController();

  Uint8List?
  qrImage;
  bool carregando = false;

  Future<void> gerarQr(String valor) async {
    setState(() {
      carregando = true;
      qrImage = null;
    });

    try {
      final linkPagamento =
          "https://claude.ai/public/artifacts/0a13c1ae-1b53-4f67-8b9b-8573c93055fa?valor=$valor";

      final QrCode qr = await _qrService.gerarQrCode(
        linkPagamento,
      );
      setState(() {
        qrImage =
            qr.imageBytes;
      });

      print("✅ API pública usada e finalizada com sucesso.");
      print("🔗 QR Code gerado redireciona para: $linkPagamento");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
    } finally {
      setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gerar QR Code da Doação")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              "Digite o valor da doação (em reais):",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Exemplo: 50.00",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(
                  Icons.monetization_on,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: const Text("Gerar QR Code"),
              onPressed: () {
                final valor = valorController.text.trim();
                if (valor.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Por favor, insira um valor válido."),
                    ),
                  );
                  return;
                }
                gerarQr(valor);
              },
            ),

            const SizedBox(height: 30),
            if (carregando) const CircularProgressIndicator(),
            if (qrImage != null && !carregando)
              Column(
                children: [
                  const Text("QR Code Gerado:", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Image.memory(
                    qrImage!,
                    width: 250,
                    height: 250,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Escaneie o QR para abrir a página de pagamento.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
