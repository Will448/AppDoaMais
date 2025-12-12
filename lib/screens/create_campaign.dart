import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/services/campaign_service.dart';

class CreateCampaignScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? campaignToEdit;

  const CreateCampaignScreen({
    super.key,
    required this.userId,
    this.campaignToEdit,
  });

  @override
  _CreateCampaignScreenState createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalAmountController = TextEditingController();
  bool _isLoading = false;

  bool get _isEditing => widget.campaignToEdit != null;
  late final CampaignService _campaignService;

  @override
  void initState() {
    super.initState();

    _campaignService = CampaignService();

    if (_isEditing) {
      _titleController.text = widget.campaignToEdit!['titulo'] ?? '';
      _descriptionController.text = widget.campaignToEdit!['descricao'] ?? '';
      final meta = widget.campaignToEdit!['meta'];
      _goalAmountController.text = meta != null ? meta.toString() : '';
    }
  }

  Future<void> _saveCampaign() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final goalAmount =
        double.tryParse(_goalAmountController.text.replaceAll(',', '.'));

    if (goalAmount == null) {
      _showSnackBar('Meta inválida', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        await _campaignService.updateCampaign(
          campaignId: widget.campaignToEdit!['id'].toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          goalAmount: goalAmount,
        );

        _showSnackBar('Campanha atualizada com sucesso!', isError: false);
      } else {
        await _campaignService.createCampaign(
          title: _titleController.text,
          description: _descriptionController.text,
          goalAmount: goalAmount,
          userId: widget.userId,
        );

        _showSnackBar('Campanha criada com sucesso!', isError: false);
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      _showSnackBar(
        'Erro ao ${_isEditing ? 'atualizar' : 'criar'} campanha: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        title: Text(
          _isEditing ? 'Editar Campanha' : 'Criar Nova Campanha',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.shade200,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit : Icons.volunteer_activism,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isEditing ? 'Atualize sua campanha' : 'Faça a diferença',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditing
                        ? 'Mantenha as informações sempre atualizadas'
                        : 'Crie sua campanha e ajude quem precisa',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha(230),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Form card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Título da Campanha', Icons.title),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 16),
                    decoration: _buildInputDecoration(
                      hint: 'Ex: Ajude o João a realizar cirurgia',
                      icon: Icons.edit,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um título';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  _buildLabel('Descrição', Icons.description),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 5,
                    decoration: _buildInputDecoration(
                      hint: 'Conte a história da sua campanha...',
                      icon: Icons.notes,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira uma descrição';
                      }
                      if (value.length < 20) {
                        return 'A descrição deve ter pelo menos 20 caracteres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  _buildLabel('Meta de Arrecadação', Icons.attach_money),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _goalAmountController,
                    style: const TextStyle(fontSize: 16),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: _buildInputDecoration(
                      hint: '0,00',
                      icon: Icons.monetization_on,
                      prefix: 'R\$ ',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira uma meta de arrecadação';
                      }
                      final amount =
                          double.tryParse(value.replaceAll(',', '.'));
                      if (amount == null) {
                        return 'Por favor, insira um número válido';
                      }
                      if (amount <= 0) {
                        return 'A meta deve ser maior que zero';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade100,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Defina uma meta realista e explique bem como os recursos serão utilizados',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _isLoading
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.deepPurple.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isEditing
                                ? 'Atualizando campanha...'
                                : 'Criando campanha...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.shade300,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _saveCampaign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isEditing ? Icons.check : Icons.rocket_launch,
                            size: 22,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isEditing ? 'Salvar Alterações' : 'Criar Campanha',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepPurple.shade600),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 15,
      ),
      prefixText: prefix,
      prefixStyle: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      suffixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.deepPurple.shade400, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
      errorStyle: TextStyle(
        color: Colors.red.shade700,
        fontSize: 12,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }
}
