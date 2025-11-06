import 'package:afercon_pay/services/credit_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CreditApplicationDetailScreen extends StatefulWidget {
  final String applicationId;
  final Map<String, dynamic> applicationData;

  const CreditApplicationDetailScreen({
    super.key,
    required this.applicationId,
    required this.applicationData,
  });

  @override
  State<CreditApplicationDetailScreen> createState() =>
      _CreditApplicationDetailScreenState();
}

class _CreditApplicationDetailScreenState
    extends State<CreditApplicationDetailScreen> {
  final CreditService _creditService = CreditService();
  bool _isLoading = false;

  Future<void> _updateStatus(String newStatus) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _creditService.updateCreditApplicationStatus(
        widget.applicationId,
        newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pedido "$newStatus" com sucesso.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar o pedido: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'AOA');
    final data = widget.applicationData;

    final String creditTypeDisplay =
        data['type'] == 'personal' ? 'Crédito Pessoal' : 'Crédito Empresarial';

    return Scaffold(
      appBar: CustomAppBar(title: Text(creditTypeDisplay)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailCard(context, data, currencyFormat),
                SizedBox(height: 24.h),
                _buildActionButtons(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54, // Correção da descontinuação
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
      BuildContext context, Map<String, dynamic> data, NumberFormat format) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context, 'Cliente:', data['fullName'] ?? 'N/A'),
            _buildInfoRow(context, 'ID do Cliente:', data['userId'] ?? 'N/A'),
            const Divider(height: 20),
            _buildInfoRow(context, 'Valor Solicitado:', format.format(data['amount'] ?? 0)),
            _buildInfoRow(context, 'Prazo:', '${data['termInMonths'] ?? 0} meses'),
            _buildInfoRow(context, 'Motivo:', data['reason'] ?? 'N/A'),
            const Divider(height: 20),
            _buildInfoRow(context, 'Prestação Mensal:', format.format(data['monthlyPayment'] ?? 0)),
            _buildInfoRow(context, 'Taxa de Juro:', '${((data['interestRate'] ?? 0) * 100).toStringAsFixed(1)}%'),
            _buildInfoRow(context, 'Reembolso Total:', format.format(data['totalRepayment'] ?? 0)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Aprovar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              minimumSize: Size.fromHeight(50.h),
            ),
            onPressed: () => _updateStatus('approved'),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Rejeitar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              minimumSize: Size.fromHeight(50.h),
            ),
            onPressed: () => _updateStatus('rejected'),
          ),
        ),
      ],
    );
  }
}
