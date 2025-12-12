import 'dart:typed_data';
import 'package:myapp/services/qr_service.dart';
import 'package:flutter/material.dart';
import '../model/qr_model.dart';

class QrApiExample extends StatefulWidget {
  //classe principal da aplicação
  const QrApiExample({super.key});

  @override
  State<QrApiExample> createState() => _QrApiExampleState();
}

class _QrApiExampleState extends State<QrApiExample> {
  final QrService _qrService =
      QrService(); //é feito o instanciamento do serviço de QR Code
  final TextEditingController valorController =
      TextEditingController(); //controlador para o campo de entrada do valor da doação

  Uint8List?
  qrImage; //imagem do QR Code gerado, guardada como uma lista de bytes
  bool carregando = false;

  Future<void> gerarQr(String valor) async {
    //função para gerar o QR Code, recebe o valor da doação como parâmetro
    setState(() {
      carregando = true;
      qrImage = null;
    });

    try {
      // realiza a chamada ao serviço de geração do QR Code e trata possíveis erros
      // 🔗 Agora o QR redireciona para a página de pagamento simulada
      final linkPagamento =
          "https://claude.ai/public/artifacts/0a13c1ae-1b53-4f67-8b9b-8573c93055fa?valor=$valor";

      final QrCode qr = await _qrService.gerarQrCode(
        linkPagamento,
      ); //chama o serviço para gerar o QR Code, ou seja, a API pública
      setState(() {
        qrImage =
            qr.imageBytes; //atualiza o estado com a imagem do QR Code gerado
      });

      // Logging para depuração e verificação do fluxo e uso da API
      print("✅ API pública usada e finalizada com sucesso.");
      print("🔗 QR Code gerado redireciona para: $linkPagamento");
    } catch (e) {
      // em caso de erro, exibe uma mensagem na tela, ou seja, trata a exceção
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
    } finally {
      // finalmente, atualiza o estado para indicar que o carregamento terminou, independente do sucesso ou falha
      setState(() => carregando = false);
    }
  }

  // os containers e widgets abaixo constroem a interface gráfica da aplicação, exibindo campos de entrada, botões e a imagem do QR Code gerado

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
                ), //ícone de moeda para o campo de entrada
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2), //ícone do QR Code no botão
              label: const Text("Gerar QR Code"),
              onPressed: () {
                final valor = valorController.text.trim();
                if (valor.isEmpty) {
                  //validação simples para garantir que o campo não está vazio
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
                  ), //exibe a imagem do QR Code gerado
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
