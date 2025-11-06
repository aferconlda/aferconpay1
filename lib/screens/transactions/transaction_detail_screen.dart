
import 'package:afercon_pay/models/transaction_model.dart';
import 'package:afercon_pay/services/receipt_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isLoading = false;

  Future<void> _handleReceiptGeneration() async {
    setState(() => _isLoading = true);

    // Captura o ScaffoldMessenger ANTES da chamada async
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Usa o método estático com o nome correto
      await ReceiptService.generateAndShowReceipt(widget.transaction);
    } catch (e) {
      // A verificação 'mounted' ainda é uma boa prática
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Erro ao gerar o comprovativo: $e')),
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
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');
    final formattedDate = DateFormat('dd MMM, yyyy HH:mm', 'pt_AO').format(widget.transaction.date); // Corrected
    final isRevenue = widget.transaction.type == 'revenue';

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Detalhes da Transação')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDetailCard(context, isRevenue, formattedDate, currencyFormat),
            const Spacer(),
            ElevatedButton.icon(
              icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.download_rounded),
              label: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)
                  : const Text('Baixar Comprovativo'),
              onPressed: _isLoading ? null : _handleReceiptGeneration,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                textStyle: TextStyle(fontSize: 16.sp),
                minimumSize: Size(double.infinity, 50.h), // Garante que o botão tenha uma altura mínima
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, bool isRevenue, String formattedDate, NumberFormat currencyFormat) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
             _buildDetailRow(context, 'Descrição:', widget.transaction.description),
             SizedBox(height: 12.h),
            _buildDetailRow(context, 'Data:', formattedDate),
             SizedBox(height: 12.h),
            _buildDetailRow(context, 'Tipo:', isRevenue ? 'Entrada' : 'Saída'),
             SizedBox(height: 12.h),
            _buildDetailRow(context, 'Valor:', currencyFormat.format(widget.transaction.amount),
              valueColor: isRevenue ? Colors.green[800] : Colors.red[800]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        SizedBox(width: 16.w),
        Expanded(
          child: Text(
            value, 
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ),
      ],
    );
  }
}
