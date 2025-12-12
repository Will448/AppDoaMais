import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/services/registration_service.dart';
import 'dart:developer' as developer;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final cpfController = TextEditingController();
  bool _isLoading = false;

  late final RegistrationService _registrationService;

  @override
  void initState() {
    super.initState();
    final baseUrl = dotenv.env['API_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
        developer.log("API_URL não configurada no .env", name: "RegisterScreen");
        // Futuramente, pode-se exibir um erro persistente na UI
        _registrationService = RegistrationService(baseUrl: '');
    } else {
        _registrationService = RegistrationService(baseUrl: baseUrl);
    }
  }

  Future<void> _register() async {
    // 1. Validação da UI permanece na tela
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        cpfController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _showSnackBar("❌ Preencha todos os campos!", Colors.orange);
      return;
    }

    if (!emailController.text.contains('@')) {
      _showSnackBar("❌ Email inválido!", Colors.orange);
      return;
    }

    final cpf = cpfController.text.replaceAll(RegExp(r'[.-]'), '');
    if (cpf.length != 11) {
      _showSnackBar("❌ CPF deve ter exatamente 11 dígitos!", Colors.orange);
      return;
    }

    if (passwordController.text.length < 6) {
      _showSnackBar("❌ Senha deve ter no mínimo 6 caracteres!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    // 2. Lógica de negócio é delegada ao serviço
    final result = await _registrationService.register(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      cpf: cpfController.text,
    );

    if (!mounted) return;

    // 3. UI reage ao resultado do serviço
    if (result['success']) {
      _showSnackBar(result['message'] ?? "✅ Usuário cadastrado!", Colors.green);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } else {
      _showSnackBar("❌ ${result['message'] ?? 'Erro ao cadastrar'}", Colors.red);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Conta"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.person_add, size: 60, color: Colors.blue),
            const SizedBox(height: 10),
            const Text(
              "Cadastre-se",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nome completo",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: cpfController,
              decoration: const InputDecoration(
                labelText: "CPF",
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                // A formatação do CPF pode ser feita com um formatter customizado no futuro
              ],
              maxLength: 11, 
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: "Senha",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Cadastrar"),
              ),
            ),

            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text("Já tem conta? Faça login"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    cpfController.dispose();
    super.dispose();
  }
}
