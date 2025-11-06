import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/verification_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VerificationDetailScreen extends StatefulWidget {
  final UserModel user;

  const VerificationDetailScreen({super.key, required this.user});

  @override
  State<VerificationDetailScreen> createState() =>
      _VerificationDetailScreenState();
}

class _VerificationDetailScreenState extends State<VerificationDetailScreen> {
  final VerificationService _verificationService = VerificationService();
  final AuthService _authService = AuthService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _rejectionReasonController =
      TextEditingController();
  bool _isLoading = false;

  late Future<String> _frontImageUrlFuture;
  late Future<String> _backImageUrlFuture;
  late Future<String> _selfieImageUrlFuture;

  @override
  void initState() {
    super.initState();
    _frontImageUrlFuture =
        _getImageUrl('kyc_documents/${widget.user.uid}/front.jpg');
    _backImageUrlFuture =
        _getImageUrl('kyc_documents/${widget.user.uid}/back.jpg');
    _selfieImageUrlFuture =
        _getImageUrl('kyc_documents/${widget.user.uid}/selfie.jpg');
  }

  Future<String> _getImageUrl(String path) async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: Text('Detalhes da Verificação')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildImageSection(
                    context, 'Frente do Documento', _frontImageUrlFuture),
                const SizedBox(height: 16),
                _buildImageSection(
                    context, 'Verso do Documento', _backImageUrlFuture),
                const SizedBox(height: 16),
                _buildImageSection(
                    context, 'Selfie com Documento', _selfieImageUrlFuture),
                const SizedBox(height: 24),
                _buildActionButtons(widget.user),
              ],
            ),
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

  Widget _buildInfoCard() {
    final createdAt = widget.user.createdAt;
    final formattedDate = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
        : 'N/A';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoRow('Nome:', widget.user.displayName ?? 'N/A'),
            _buildInfoRow('Email:', widget.user.email ?? 'N/A'),
            _buildInfoRow('Telefone:', widget.user.phoneNumber ?? 'N/A'),
            _buildInfoRow('Membro desde:', formattedDate),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
          children: [
            TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(
      BuildContext context, String title, Future<String> imageUrlFuture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        FutureBuilder<String>(
          future: imageUrlFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildErrorBox('Imagem não encontrada.');
            }

            final imageUrl = snapshot.data!;
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) =>
                      progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (context, error, stackTrace) =>
                      _buildErrorBox('Erro ao carregar imagem.'),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: const Text('Aprovar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () => _handleApproval(user.uid),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cancel, color: Colors.white),
            label: const Text('Rejeitar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () => _showRejectionDialog(user.uid),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(Future<void> Function() action,
      String successMessage, String errorMessage) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await action();
      _showSnackbar(successMessage, isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showSnackbar('$errorMessage: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApproval(String userId) async {
    final currentUser = _authService.getCurrentUser();
    final adminId = currentUser?.uid;
    if (adminId == null) {
      _showSnackbar('Erro: Administrador não autenticado.');
      return;
    }

    await _handleAction(
      () async {
        final requestId =
            await _verificationService.findPendingRequestIdForUser(userId);
        if (requestId == null) {
          throw Exception(
              'Nenhum pedido de verificação pendente encontrado para este utilizador.');
        }
        await _verificationService.approveRequest(requestId, adminId);
      },
      'Utilizador aprovado com sucesso!',
      'Erro ao aprovar utilizador',
    );
  }

  Future<void> _showRejectionDialog(String userId) async {
    _rejectionReasonController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar Verificação'),
        content: TextField(
          controller: _rejectionReasonController,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Motivo da Rejeição (obrigatório)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (_rejectionReasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                _handleRejection(
                    userId, _rejectionReasonController.text.trim());
              }
            },
            child: const Text('Confirmar Rejeição'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRejection(String userId, String reason) async {
    final currentUser = _authService.getCurrentUser();
    final adminId = currentUser?.uid;
    if (adminId == null) {
      _showSnackbar('Erro: Administrador não autenticado.');
      return;
    }

    await _handleAction(
      () async {
        final requestId =
            await _verificationService.findPendingRequestIdForUser(userId);
        if (requestId == null) {
          throw Exception(
              'Nenhum pedido de verificação pendente encontrado para este utilizador.');
        }
        await _verificationService.rejectRequest(requestId, adminId, reason);
      },
      'Utilizador rejeitado com sucesso.',
      'Erro ao rejeitar utilizador',
    );
  }

  void _showSnackbar(String message, {bool isError = true}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Theme.of(context).colorScheme.error : Colors.green,
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
