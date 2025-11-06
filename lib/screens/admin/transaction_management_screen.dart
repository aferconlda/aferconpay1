import 'package:afercon_pay/models/deposit_request_model.dart';
import 'package:afercon_pay/models/withdrawal_request_model.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

enum RequestType { deposit, withdrawal }

class TransactionManagementScreen extends StatefulWidget {
  const TransactionManagementScreen({super.key});

  @override
  State<TransactionManagementScreen> createState() => _TransactionManagementScreenState();
}

class _TransactionManagementScreenState extends State<TransactionManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _rejectionReasonController = TextEditingController();
  bool _isLoading = false;

  Stream<List<dynamic>>? _combinedStream;

  @override
  void initState() {
    super.initState();
    // Combina os streams de depósitos e levantamentos numa única lista.
    _combinedStream = CombineLatestStream.combine2(
      _firestoreService.getPendingDepositRequestsStream(),
      _firestoreService.getPendingWithdrawalRequestsStream(),
      (List<DepositRequestModel> deposits, List<WithdrawalRequestModel> withdrawals) {
        final List<dynamic> combined = [ ...deposits, ...withdrawals ];
        // Ordena a lista combinada pela data de criação.
        combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return combined;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: Text('Pedidos Pendentes')),
      body: Stack(
        children: [
          StreamBuilder<List<dynamic>>(
            stream: _combinedStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Nenhum pedido pendente encontrado.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final request = snapshot.data![index];
                  return _buildRequestCard(request);
                },
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(dynamic request) {
    final isDeposit = request is DepositRequestModel;
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final String title = isDeposit ? 'Pedido de Depósito' : 'Pedido de Levantamento';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            _buildInfoRow('Cliente:', request.userDisplayName ?? 'N/A'),
            _buildInfoRow('Email:', request.userEmail ?? 'N/A'),
            _buildInfoRow('Valor:', currencyFormat.format(request.amount)),
            if (!isDeposit) ...[
              _buildInfoRow('Taxa:', currencyFormat.format(request.fee)),
              _buildInfoRow('Total Debitado:', currencyFormat.format(request.totalDebited)),
              _buildInfoRow('IBAN:', request.iban ?? 'N/A'),
            ],
            _buildInfoRow('Data Pedido:', dateFormat.format(request.createdAt.toDate())),
            const SizedBox(height: 12),
            _buildActionButtons(request),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic request) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
          label: const Text('Aprovar', style: TextStyle(color: Colors.green)),
          onPressed: () => _handleApproval(request),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          label: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
          onPressed: () => _showRejectionDialog(request),
        ),
      ],
    );
  }

  Future<void> _handleApproval(dynamic request) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (request is DepositRequestModel) {
        await _firestoreService.approveDepositRequest(request.id);
      } else if (request is WithdrawalRequestModel) {
        await _firestoreService.approveWithdrawalRequest(request.id);
      }
      _showSnackbar('Pedido aprovado com sucesso.', isError: false);
    } catch (e) {
      _showSnackbar('Erro ao aprovar o pedido: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showRejectionDialog(dynamic request) async {
    _rejectionReasonController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar Pedido'),
        content: TextField(
          controller: _rejectionReasonController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Motivo da Rejeição (obrigatório)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (_rejectionReasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                _handleRejection(request, _rejectionReasonController.text.trim());
              }
            },
            child: const Text('Confirmar Rejeição'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRejection(dynamic request, String reason) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (request is DepositRequestModel) {
        await _firestoreService.rejectDepositRequest(request.id, reason);
      } else if (request is WithdrawalRequestModel) {
        await _firestoreService.rejectWithdrawalRequest(request.id, reason);
      }
      _showSnackbar('Pedido rejeitado com sucesso.', isError: false);
    } catch (e) {
      _showSnackbar('Erro ao rejeitar o pedido: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = true}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }
}
