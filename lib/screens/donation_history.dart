import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/donation_service.dart';
import 'dart:developer' as developer;

class DonationsHistory extends StatefulWidget {
  final String userId;
  final String userName;

  const DonationsHistory({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<DonationsHistory> createState() => _DonationsHistoryState();
}

class _DonationsHistoryState extends State<DonationsHistory> {
  late final DonationService _donationService;
  List<Map<String, dynamic>> _donations = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _totalDoado = 0.0;

  @override
  void initState() {
    super.initState();
    final apiUrl = dotenv.env['API_URL'] ?? '';
    if (apiUrl.isEmpty) {
      developer.log("URL da API não configurada", name: "DonationsHistory");
    }
    _donationService = DonationService(apiUrl: apiUrl);
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _donationService.getDonationHistory(userId: widget.userId);

    if (result['success']) {
      final List data = result['donations'] ?? [];
      developer.log('✅ ${data.length} doações encontradas', name: 'DonationsHistory');

      double total = 0.0;
      final donations = data.map((item) {
        final donation = item as Map<String, dynamic>;
        final amount = double.tryParse(donation['amount'].toString()) ?? 0.0;
        total += amount;

        return {
          'id': donation['id'],
          'campaign_id': donation['campaign_id'],
          'name': donation['name'] ?? 'Doador',
          'cpf': donation['cpf'] ?? '',
          'amount': amount,
          'payment_method': donation['payment_method'] ?? 'N/A',
          'created_at': donation['created_at'],
          'updated_at': donation['updated_at'],
        };
      }).toList();

      donations.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _donations = donations;
          _totalDoado = total;
          _isLoading = false;
        });
      }
    } else {
      developer.log(
        '❌ Erro ao buscar doações: ${result['message']}',
        name: 'DonationsHistory',
      );
      if (mounted) {
        setState(() {
          _errorMessage = result['message'] ?? 'Erro ao carregar histórico de doações';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCPF(String cpf) {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
  }

  Map<String, dynamic> _getPaymentMethodInfo(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'pix':
        return {
          'text': 'Pix',
          'icon': Icons.qr_code,
          'color': Colors.cyan.shade700,
        };
      case 'credito':
        return {
          'text': 'Crédito',
          'icon': Icons.credit_card,
          'color': Colors.blue.shade700,
        };
      case 'debito':
        return {
          'text': 'Débito',
          'icon': Icons.credit_card,
          'color': Colors.purple.shade700,
        };
      default:
        return {
          'text': paymentMethod,
          'icon': Icons.payment,
          'color': Colors.grey.shade600,
        };
    }
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final amount = donation['amount'] as double;
    final donorName = donation['name'] as String;
    final cpf = donation['cpf'] as String;
    final paymentMethod = donation['payment_method'] as String;
    final createdAt = DateTime.parse(donation['created_at']);

    final paymentInfo = _getPaymentMethodInfo(paymentMethod);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: paymentInfo['color'].withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    paymentInfo['icon'],
                    color: paymentInfo['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doação para Campanha',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: paymentInfo['color'].withAlpha(51),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          paymentInfo['text'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: paymentInfo['color'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'R\$ ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Doador: $donorName',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'CPF: ${_formatCPF(cpf)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  timeFormat.format(createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade600,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Minhas Doações",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "ID: ${widget.userId.substring(0, 8)}...",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando doações...'),
          ],
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade900),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchDonations,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchDonations,
        child: _donations.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.volunteer_activism_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Você ainda não fez doações',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore campanhas e faça a diferença!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Doado',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'R\$ ${_totalDoado.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_donations.length} ${_donations.length == 1 ? "doação realizada" : "doações realizadas"}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _donations.length,
                itemBuilder: (context, index) {
                  return _buildDonationCard(_donations[index]);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}