import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/screens/create_campaign.dart';
import 'package:myapp/screens/create_donation.dart';
import 'package:myapp/screens/donation_history.dart';
import 'package:myapp/screens/edit_campaign.dart';
import 'package:myapp/screens/login.dart';
import 'package:myapp/services/campaign_service.dart';
import 'package:myapp/services/groq_service.dart';
import 'package:myapp/widgets/campaign_card.dart';
import 'package:url_launcher/url_launcher.dart';

class Dashboard extends StatefulWidget {
  final Map<String, dynamic> user;

  const Dashboard({super.key, required this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late final CampaignService _campaignService;
  late final GroqService _groqService;

  List<Map<String, dynamic>> _minhasCampanhas = [];
  List<Map<String, dynamic>> _outrasCampanhas = [];
  List<Map<String, dynamic>> _campanhasGlobais = [];

  bool _isLoading = true;
  bool _isLoadingGlobal = true;
  String? _errorMessage;
  String? _errorMessageGlobal;

  String _aiInsightText = "Gerando insight para você...";
  bool _isAiInsightLoading = true;

  @override
  void initState() {
    super.initState();
    _campaignService = CampaignService();
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null) {
      setState(() {
        _aiInsightText = "GROQ_API_KEY não encontrada no seu arquivo .env";
        _isAiInsightLoading = false;
      });
    }
    _groqService = GroqService(apiKey: apiKey ?? '');
    _fetchAllCampaigns();
  }

  Future<void> _fetchAllCampaigns() async {
    await _fetchCampaigns();
    await _fetchGlobalGivingCampaigns();
  }

  Future<void> _fetchGlobalGivingCampaigns() async {
    setState(() {
      _isLoadingGlobal = true;
      _errorMessageGlobal = null;
    });
    try {
      final campaigns = await _campaignService.fetchGlobalCampaigns();
      setState(() {
        _campanhasGlobais = campaigns;
        _isLoadingGlobal = false;
      });
      _fetchAiInsight();
    } catch (e) {
      setState(() {
        _errorMessageGlobal = e.toString();
        _isLoadingGlobal = false;
      });
    }
  }

  Future<void> _fetchCampaigns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final campaigns = await _campaignService.fetchLocalCampaigns(
        widget.user['id'],
      );
      setState(() {
        _minhasCampanhas = campaigns['myCampaigns']!;
        _outrasCampanhas = campaigns['otherCampaigns']!;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAiInsight() async {
    if (_groqService.apiKey.isEmpty) return;

    final allCampaigns = [..._campanhasGlobais, ..._outrasCampanhas];
    if (allCampaigns.isEmpty) return;

    setState(() {
      _isAiInsightLoading = true;
    });

    try {
      final titulos = allCampaigns.map((c) => c['titulo']).take(10).join(', ');
      final prompt =
          'Baseado nestes temas de campanhas: "$titulos", gere um insight curto sobre o cenário atual de doações, com o fim de motivar doações. Seja criativo e direto. Máximo de 150 caracteres. **NÃO DEVE estar entre aspas**';

      final insight = await _groqService.gerarInsight(prompt);
      setState(() => _aiInsightText = insight);
    } catch (e, s) {
      setState(() => _aiInsightText = "Erro ao carregar o insight de IA.");
      developer.log(
        'Erro ao chamar GroqService',
        name: 'Dashboard',
        error: e,
        stackTrace: s,
      );
    } finally {
      if (mounted) setState(() => _isAiInsightLoading = false);
    }
  }

  void _logout(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Logout realizado com sucesso'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o link'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir link: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _navegarParaDoacao(Map<String, dynamic> campanha) async {
    final userName = widget.user['user_metadata']?['name'] ?? 'Usuário';
    final userId = widget.user['id'];

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDonation(
          campanha: campanha,
          userId: userId!,
          userName: userName,
        ),
      ),
    );

    if (result == true) {
      _fetchCampaigns();
    }
  }

  Future<void> _navegarParaEditar(Map<String, dynamic> campanha) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCampaignScreen(
          user: widget.user,
          campanha: campanha,
          onRefresh: _fetchCampaigns,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomeUsuario = widget.user['user_metadata']?['name'] ?? 'Usuário';
    final userId = widget.user['id'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade600,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Doa+",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Olá, $nomeUsuario",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Cadastrar campanha',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateCampaignScreen(userId: userId!),
                ),
              );
              _fetchCampaigns();
            },
          ),
          IconButton(
            icon: const Icon(Icons.volunteer_activism, color: Colors.white),
            tooltip: 'Minhas doações',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DonationsHistory(userId: userId, userName: nomeUsuario),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllCampaigns,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _aiInsightCard(),
              _buildSectionTitle("🌍", "Campanhas Globais"),
              _buildGlobalCampaignsList(),
              _buildSectionTitle("🌟", "Outras Campanhas"),
              _buildCampaignsList(
                _outrasCampanhas,
                "Nenhuma outra campanha encontrada no momento.",
                isOwnerList: false,
              ),
              _buildSectionTitle("👤", "Minhas Campanhas"),
              _buildCampaignsList(
                _minhasCampanhas,
                "Você ainda não criou nenhuma campanha.",
                isOwnerList: true,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aiInsightCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Insights de Doações",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_isAiInsightLoading)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Gerando insight...",
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    )
                  else
                    Text(
                      _aiInsightText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String emoji, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            title,
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

  Widget _buildGlobalCampaignsList() {
    if (_isLoadingGlobal) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando campanhas globais...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessageGlobal != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessageGlobal!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade900),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchGlobalGivingCampaigns,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_campanhasGlobais.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('Nenhuma campanha global encontrada no momento.'),
        ),
      );
    }

    return Column(
      children: _campanhasGlobais.map((c) {
        return CampaignCard(
          campanha: c,
          isOwner: false,
          onDonate: () {
            final url = c['url'];
            if (url != null && url.isNotEmpty) {
              _abrirUrl(url);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link da campanha não disponível'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildCampaignsList(
    List<Map<String, dynamic>> campaigns,
    String emptyMessage, {
    required bool isOwnerList,
  }) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade900),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchCampaigns,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (campaigns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text(emptyMessage)),
      );
    }

    return Column(
      children: campaigns.map((c) {
        return CampaignCard(
          campanha: c,
          isOwner: isOwnerList,
          onEdit: isOwnerList ? () => _navegarParaEditar(c) : null,
          onDonate: !isOwnerList ? () => _navegarParaDoacao(c) : null,
        );
      }).toList(),
    );
  }
}
