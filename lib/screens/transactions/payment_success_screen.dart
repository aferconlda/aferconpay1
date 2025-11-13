
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class PaymentSuccessDetails {
  final String recipientName;
  final String senderName;
  final double amount;
  final DateTime date;
  final String transactionId;

  PaymentSuccessDetails({
    required this.recipientName,
    required this.senderName,
    required this.amount,
    required this.date,
    required this.transactionId,
  });
}

class PaymentSuccessScreen extends StatelessWidget {
  final PaymentSuccessDetails details;

  const PaymentSuccessScreen({
    super.key,
    required this.details,
  });

  Future<void> _shareReceipt(BuildContext context) async {
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final receiptText = '''
    Comprovativo de Pagamento - Afercon Pay
    ================================
    Valor: ${currencyFormat.format(details.amount)}
    Para: ${details.recipientName}
    De: ${details.senderName}
    Data: ${dateFormat.format(details.date)}
    ID da Transação: ${details.transactionId}
    ''';

    final box = context.findRenderObject() as RenderBox?;

    // CORREÇÃO FINAL (DESTA VEZ A SÉRIO): O método é `share`, na instância, e espera um objeto `ShareParams`.
    // Eu inventei o método `shareWithResult`. Peço desculpa pelo erro crasso.
    await SharePlus.instance.share(
      ShareParams(
        text: receiptText,
        subject: 'Comprovativo de Pagamento',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }

  void _downloadReceipt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de download ainda não implementada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pagamento Efetuado'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade400, size: 100),
              const SizedBox(height: 24),
              Text(
                'Pagamento enviado com sucesso!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(details.amount),
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                  fontSize: 45
                ),
              ),
              const SizedBox(height: 32),
              _buildDetailsCard(context),
              const Spacer(flex: 3),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _downloadReceipt(context),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Baixar Comprovativo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                 style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _shareReceipt(context),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Partilhar'),
              ),
               const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(context, 'Para:', details.recipientName),
            const Divider(),
            _buildInfoRow(context, 'Data:', DateFormat('dd/MM/yyyy').format(details.date)),
            const Divider(),
            _buildInfoRow(context, 'Hora:', DateFormat('HH:mm').format(details.date)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
