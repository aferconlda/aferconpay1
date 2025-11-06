import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/screens/qr_code/receive_qr_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Efetuar Depósito'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transferência'),
            Tab(text: 'Agente (QR Code)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BankTransferDepositTab(),
          QrCodeDepositTab(),
        ],
      ),
    );
  }
}

class BankTransferDepositTab extends StatefulWidget {
  const BankTransferDepositTab({super.key});

  @override
  State<BankTransferDepositTab> createState() => _BankTransferDepositTabState();
}

class _BankTransferDepositTabState extends State<BankTransferDepositTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  XFile? _proofFile;

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSending = false;

  final String _aferconIban = '0055 0000 39513329101 67';
  final String _aferconBank = 'Banco Atlântico';
  final String _aferconBeneficiary = 'Afercon Pay';
  final String _whatsappNumber = '+244945100502';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authUser = _authService.getCurrentUser();
    if (mounted) {
      if (authUser != null) {
        final userModel = await _firestoreService.getUser(authUser.uid);
        setState(() {
          _currentUser = userModel;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickProof() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _proofFile = image;
      });
    }
  }

  Future<void> _sendViaWhatsApp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_proofFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, anexe o comprovativo do depósito.')),
      );
      return;
    }

    if (_currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Utilizador não autenticado.')),
      );
      return;
    }

    setState(() => _isSending = true);

    final userName = _currentUser!.displayName ?? 'Nome não fornecido';
    final userEmail = _currentUser!.email ?? 'Email não fornecido';
    final String amount = _amountController.text;

    final String message = '''
Assunto: Depósito para Atualização de Saldo - Afercon Pay

Prezada equipa da Afercon Pay,

Escrevo para solicitar a atualização do meu saldo na plataforma.

Em anexo, envio o comprovativo de um depósito no valor de $amount Kz.

*Detalhes da Conta:*
- *Nome:* $userName
- *Email Associado:* $userEmail

Agradeço a vossa atenção e aguardo a confirmação da atualização do saldo.

Com os melhores cumprimentos,
$userName
''';

    final Uri whatsappUri = Uri.parse('https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(message)}');

    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ação Requerida'),
            content: Text('A conversa no WhatsApp foi aberta. Por favor, anexe e envie o comprovativo que selecionou:\n\n${_proofFile!.name}'),
            actions: [
              TextButton(child: const Text('OK'), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o WhatsApp: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(context),
                SizedBox(height: 24.h),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(labelText: 'Montante Transferido', suffixText: 'Kz'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Por favor, insira o montante.';
                          if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Insira um número válido.';
                          return null;
                        },
                      ),
                      SizedBox(height: 24.h),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: Text(_proofFile == null ? 'Anexar Comprovativo' : 'Comprovativo Anexado'),
                        onPressed: _pickProof,
                      ),
                      if (_proofFile != null)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text('Ficheiro: ${_proofFile!.name}', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                        ),
                      SizedBox(height: 32.h),
                      if (_isSending)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Enviar via WhatsApp'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                          onPressed: _sendViaWhatsApp,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dados para Transferência', style: theme.textTheme.titleLarge),
            const Divider(),
            _buildInfoRow(context, 'Beneficiário', _aferconBeneficiary),
            _buildInfoRow(context, 'Banco', _aferconBank),
            _buildInfoRow(context, 'IBAN', _aferconIban),
            SizedBox(height: 16.h),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.copy, size: 20.sp),
                label: const Text('Copiar IBAN'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _aferconIban));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('IBAN copiado para a área de transferência.')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          SizedBox(height: 4.h),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class QrCodeDepositTab extends StatefulWidget {
  const QrCodeDepositTab({super.key});

  @override
  State<QrCodeDepositTab> createState() => _QrCodeDepositTabState();
}

class _QrCodeDepositTabState extends State<QrCodeDepositTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isUserDataLoading = true;

  double _aferconFee = 0.0;
  double _agentFee = 0.0;
  double _totalCredited = 0.0;
  static const double _aferconFeePercentage = 0.015; // 1.5%
  static const double _agentFeePercentage = 0.035; // 3.5%

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateFee);
    _loadUserData();
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateFee);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authUser = _authService.getCurrentUser();
    if (mounted) {
      if (authUser != null) {
        final userModel = await _firestoreService.getUser(authUser.uid);
        setState(() {
          _currentUser = userModel;
          _isUserDataLoading = false;
        });
      } else {
        setState(() {
          _isUserDataLoading = false;
        });
      }
    }
  }

  void _updateFee() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    setState(() {
      _aferconFee = (amount * _aferconFeePercentage * 100).round() / 100;
      _agentFee = (amount * _agentFeePercentage * 100).round() / 100;
      _totalCredited = amount - _aferconFee - _agentFee;
    });
  }

  void _onGenerateQrPressed() {
    if (!(_formKey.currentState?.validate() ?? false) || !mounted) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilizador não autenticado. Tente novamente.')),
      );
      return;
    }

    final String amount = _amountController.text.replaceAll(',', '.');
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReceiveQrScreen(
        amount: double.parse(amount),
        transactionType: 'deposit',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Depósito com Agente', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            SizedBox(height: 12.h),
            Text(
              'Insira o montante que deseja depositar e gere um QR code para apresentar a um agente autorizado.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Montante a Depositar', suffixText: 'Kz'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Por favor, insira o montante.';
                final double? amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null) return 'Insira um número válido.';
                if (amount <= 0) return 'O montante deve ser superior a zero.';
                if (_totalCredited <= 0) return 'O montante é insuficiente para cobrir as taxas.';
                return null;
              },
            ),
            SizedBox(height: 24.h),
            _buildAgentDepositFeeSummary(
              context,
              currencyFormat,
              aferconFee: _aferconFee,
              agentFee: _agentFee,
              totalCredited: _totalCredited,
              amountText: _amountController.text,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Gerar QR Code'),
              onPressed: _isUserDataLoading ? null : _onGenerateQrPressed,
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16.h)),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildAgentDepositFeeSummary(BuildContext context, NumberFormat currencyFormat, {required double aferconFee, required double agentFee, required double totalCredited, required String amountText}) {
  final theme = Theme.of(context);

  if (amountText.isEmpty || (aferconFee + agentFee) <= 0) {
    return const SizedBox.shrink();
  }

  return Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(color: theme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(12.r)),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('Taxa Afercon Pay (1.5%)', style: theme.textTheme.bodyMedium), Text('- ${currencyFormat.format(aferconFee)}', style: theme.textTheme.bodyMedium)],
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('Taxa do Agente (3.5%)', style: theme.textTheme.bodyMedium), Text('- ${currencyFormat.format(agentFee)}', style: theme.textTheme.bodyMedium)],
        ),
        const Divider(height: 17),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total a ser creditado', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(currencyFormat.format(totalCredited > 0 ? totalCredited : 0), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}
