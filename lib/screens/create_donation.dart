import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/services/donation_service.dart';
import 'package:myapp/services/qr_service.dart';
import 'dart:typed_data';

// --- Formatters Customizados ---

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    var maskedText = '';

    if (newText.length <= 3) {
      maskedText = newText;
    } else if (newText.length <= 6) {
      maskedText = '${newText.substring(0, 3)}.${newText.substring(3)}';
    } else if (newText.length <= 9) {
      maskedText =
          '${newText.substring(0, 3)}.${newText.substring(3, 6)}.${newText.substring(6)}';
    } else {
      maskedText =
          '${newText.substring(0, 3)}.${newText.substring(3, 6)}.${newText.substring(6, 9)}-${newText.substring(9)}';
    }

    if (maskedText.length > 14) {
      maskedText = maskedText.substring(0, 14);
    }

    return TextEditingValue(
      text: maskedText,
      selection: TextSelection.collapsed(offset: maskedText.length),
    );
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    var maskedText = '';
    for (var i = 0; i < newText.length; i++) {
      if (i > 0 && i % 4 == 0) {
        maskedText += ' ';
      }
      maskedText += newText[i];
    }

    if (maskedText.length > 19) {
      maskedText = maskedText.substring(0, 19);
    }

    return TextEditingValue(
      text: maskedText,
      selection: TextSelection.collapsed(offset: maskedText.length),
    );
  }
}

class CardValidityInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    var maskedText = '';

    if (newText.length >= 2) {
      maskedText = '${newText.substring(0, 2)}/${newText.substring(2)}';
    } else {
      maskedText = newText;
    }

    if (maskedText.length > 5) {
      maskedText = maskedText.substring(0, 5);
    }

    return TextEditingValue(
      text: maskedText,
      selection: TextSelection.collapsed(offset: maskedText.length),
    );
  }
}

// --- Tela de Criação de Doação ---
class CreateDonation extends StatefulWidget {
  final Map<String, dynamic> campanha;
  final String userId;
  final String userName;

  const CreateDonation({
    super.key,
    required this.campanha,
    required this.userId,
    required this.userName,
  });

  @override
  State<CreateDonation> createState() => _CreateDonationState();
}

class _CreateDonationState extends State<CreateDonation> {
  final _formKey = GlobalKey<FormState>();
  late final DonationService _donationService;
  final QrService _qrService = QrService();

  // Controladores de campos
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _amountController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardValidityController = TextEditingController();
  final _cardCvvController = TextEditingController();

  // Estado para seleção de pagamento e doação anônima
  String _paymentMethod = 'pix';
  String _cardType = 'credito';
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final apiUrl = dotenv.env['API_URL'];
    if (apiUrl == null) {
      print("API_URL não encontrada no .env");
      return;
    }
    _donationService = DonationService(apiUrl: apiUrl);
    _nameController.text = widget.userName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _amountController.dispose();
    _cardNumberController.dispose();
    _cardValidityController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  Future<void> _generatePixQrCode() async {
    if (_amountController.text.isEmpty) {
      _showSnackBar('Por favor, insira um valor para a doação.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final valor = _amountController.text.replaceAll(',', '.');
      final linkPagamento =
          "https://pagamento.pix.example.com?valor=$valor&campanha=${widget.campanha['id']}";

      final qrCode = await _qrService.gerarQrCode(linkPagamento);

      setState(() => _isLoading = false);

      if (mounted) {
        // Mostra o dialog com QR Code
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            // Timer para fechar após 20 segundos
            Future.delayed(const Duration(seconds: 20), () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.of(dialogContext).pop();
              }
            });

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: Colors.deepPurple.shade600,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Escaneie o QR Code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use seu app de pagamento para escanear',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Image.memory(
                        qrCode.imageBytes,
                        width: 200,
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Aguardando confirmação do pagamento...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // Após fechar o dialog, mostra confirmação e processa doação
        if (mounted) {
          _showSnackBar('PIX confirmado com sucesso!', isError: false);

          // Aguarda 2 segundos e processa a doação
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            await _submitDonation();
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erro ao gerar QR Code: ${e.toString()}', isError: true);
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        'Por favor, corrija os erros no formulário.',
        isError: true,
      );
      return;
    }
    setState(() => _isLoading = true);

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final String finalPaymentMethod = _paymentMethod == 'cartao'
        ? _cardType
        : _paymentMethod;

    final result = await _donationService.registrarDoacao(
      campaignId: widget.campanha['id'].toString(),
      userId: widget.userId,
      amount: amount,
      paymentMethod: finalPaymentMethod,
      donorName: _isAnonymous ? null : _nameController.text,
      cpf: _isAnonymous
          ? null
          : _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );

    if (mounted) {
      _showSnackBar(result['message'], isError: !result['success']);
      if (result['success']) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Doação'),
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildCampaignInfoCard(),
              const SizedBox(height: 24),
              _buildAnonymousSwitch(),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _nameController,
                labelText: 'Nome Completo',
                icon: Icons.person_outline,
                enabled: !_isAnonymous,
                validator: (v) => !_isAnonymous && (v == null || v.isEmpty)
                    ? 'Insira seu nome'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _cpfController,
                labelText: 'CPF',
                icon: Icons.badge_outlined,
                enabled: !_isAnonymous,
                keyboardType: TextInputType.number,
                inputFormatters: [CpfInputFormatter()],
                validator: (v) {
                  if (_isAnonymous) return null;
                  if (v == null || v.isEmpty) return 'Insira seu CPF';
                  if (v.replaceAll(RegExp(r'[^0-9]'), '').length != 11) {
                    return 'CPF inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _amountController,
                labelText: 'Valor da Doação',
                icon: Icons.monetization_on_outlined,
                prefix: 'R\$ ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Insira um valor';
                  final amount = double.tryParse(v.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Método de Pagamento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodSelector(),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildPaymentDetailsForm(),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnonymousSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: const Text(
          'Fazer doação anônima',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        subtitle: Text(
          'Seus dados (Nome e CPF) não serão registrados.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        value: _isAnonymous,
        onChanged: (bool value) {
          setState(() {
            _isAnonymous = value;
            if (_isAnonymous) {
              _nameController.clear();
              _cpfController.clear();
            } else {
              _nameController.text = widget.userName;
            }
          });
        },
        activeColor: Colors.deepPurple.shade500,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCampaignInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Você está doando para:',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            widget.campanha['titulo'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return SegmentedButton<String>(
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(
          value: 'pix',
          label: Text('Pix'),
          icon: Icon(Icons.qr_code),
        ),
        ButtonSegment<String>(
          value: 'cartao',
          label: Text('Cartão'),
          icon: Icon(Icons.credit_card),
        ),
      ],
      selected: {_paymentMethod},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _paymentMethod = newSelection.first;
        });

        // Gera QR Code automaticamente ao selecionar PIX
        if (newSelection.first == 'pix') {
          _generatePixQrCode();
        }
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple.shade700,
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: Colors.deepPurple.shade500,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.deepPurple.shade100),
      ),
    );
  }

  Widget _buildPaymentDetailsForm() {
    switch (_paymentMethod) {
      case 'cartao':
        return _buildCardForm();
      case 'pix':
        return _buildPixForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardForm() {
    return Column(
      key: const ValueKey('card_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Cartão',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(value: 'credito', label: Text('Crédito')),
            ButtonSegment<String>(value: 'debito', label: Text('Débito')),
          ],
          selected: {_cardType},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _cardType = newSelection.first;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildTextFormField(
          controller: _cardNumberController,
          labelText: 'Número do Cartão',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          inputFormatters: [CardNumberInputFormatter()],
          validator: (v) =>
              !_isAnonymous && v!.length < 19 ? 'Número inválido' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextFormField(
                controller: _cardValidityController,
                labelText: 'Validade',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                inputFormatters: [CardValidityInputFormatter()],
                validator: (v) =>
                    !_isAnonymous && v!.length < 5 ? 'Data inválida' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextFormField(
                controller: _cardCvvController,
                labelText: 'CVV',
                icon: Icons.lock,
                keyboardType: TextInputType.number,
                inputFormatters: [LengthLimitingTextInputFormatter(3)],
                validator: (v) =>
                    !_isAnonymous && v!.length < 3 ? 'CVV inválido' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPixForm() {
    return _buildInfoContainer(
      key: const ValueKey('pix_form'),
      icon: Icons.qr_code_scanner,
      text: 'Clique no botão abaixo para gerar o QR Code PIX',
    );
  }

  Widget _buildInfoContainer({
    required Key key,
    required IconData icon,
    required String text,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.deepPurple.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.deepPurple.shade800, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isPix = _paymentMethod == 'pix';

    return ElevatedButton.icon(
      onPressed: isPix ? _generatePixQrCode : _submitDonation,
      icon: Icon(
        isPix ? Icons.qr_code_2 : Icons.check_circle_outline,
        color: Colors.white,
      ),
      label: Text(
        isPix ? 'Gerar QR Code PIX' : 'Confirmar Doação',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: isPix
            ? Colors.deepPurple.shade600
            : Colors.green.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        shadowColor: (isPix ? Colors.deepPurple : Colors.green).withOpacity(
          0.4,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? prefix,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _buildInputDecoration(
        labelText: labelText,
        icon: icon,
        prefix: prefix,
        enabled: enabled,
      ),
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData icon,
    String? prefix,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixText: prefix,
      prefixIcon: Icon(
        icon,
        color: enabled ? Colors.deepPurple.shade300 : Colors.grey.shade400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.deepPurple.shade500, width: 2),
      ),
      filled: true,
      fillColor: enabled ? Colors.white : Colors.grey.shade100,
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }
}
