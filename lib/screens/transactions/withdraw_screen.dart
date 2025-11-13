import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/screens/qr_code/receive_qr_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:afercon_pay/widgets/pin_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

// Main Screen Widget
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Efetuar Levantamento'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Conta Bancária'),
            Tab(text: 'Agente (QR Code)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('Utilizador não autenticado.'))
              : StreamBuilder<UserModel?>(
                  stream: _firestoreService.getUserStream(_currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                          child: Text(
                              'Não foi possível carregar os dados do utilizador.'));
                    }

                    final user = snapshot.data!;

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        BankWithdrawalTab(currentUser: user),
                        QrWithdrawalTab(currentUser: user),
                      ],
                    );
                  },
                ),
    );
  }
}

// Tab 1: Bank Account Withdrawal
class BankWithdrawalTab extends StatefulWidget {
  final UserModel currentUser;

  const BankWithdrawalTab({super.key, required this.currentUser});

  @override
  State<BankWithdrawalTab> createState() => _BankWithdrawalTabState();
}

class _BankWithdrawalTabState extends State<BankWithdrawalTab>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  double _fee = 0.0;
  double _totalDebited = 0.0;
  static const double _feePercentage = 0.01; // 1%
  static const double _unverifiedTransactionLimit = 100000.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateFee);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ibanController.dispose();
    _amountController.removeListener(_updateFee);
    _amountController.dispose();
    super.dispose();
  }

  void _updateFee() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    setState(() {
      _fee = (amount * _feePercentage * 100).round() / 100;
      _totalDebited = amount + _fee;
    });
  }

  Future<void> _submitBankRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final bool isPinConfirmed = await showPinConfirmationDialog(context);
    if (!isPinConfirmed || !mounted) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double amount =
          double.parse(_amountController.text.replaceAll(',', '.'));
      await _firestoreService.createWithdrawalRequest(
        userId: widget.currentUser.uid,
        beneficiaryName: _nameController.text,
        iban: _ibanController.text,
        amount: amount,
        fee: _fee,
        totalDebited: _totalDebited,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pedido Enviado com Sucesso'),
            content: const Text(
                'O seu pedido de levantamento foi enviado e será processado em breve.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final remainingKycLimit = _unverifiedTransactionLimit -
        widget.currentUser.unverifiedTransactionVolume;
    final bool isKycVerified =
        widget.currentUser.kycStatus == KycStatus.approved;
    final isButtonDisabled =
        _isLoading || (!isKycVerified && remainingKycLimit <= 0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, widget.currentUser.balance['AOA'] ?? 0.0,
                    widget.currentUser.kycStatus, remainingKycLimit,
                    isBank: true),
                SizedBox(height: 24.h),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Nome do Beneficiário',
                      prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Insira o nome do beneficiário.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _ibanController,
                  decoration: const InputDecoration(
                      labelText: 'IBAN',
                      prefixIcon: Icon(Icons.account_balance_outlined)),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Por favor, insira o IBAN.';
                    }
                    if (v.length < 21) {
                      return 'IBAN inválido.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                      labelText: 'Montante a Levantar',
                      suffixText: 'Kz',
                      prefixIcon: Icon(Icons.attach_money)),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Insira o montante.';
                    }
                    final amount = double.tryParse(v.replaceAll(',', '.'));
                    if (amount == null) {
                      return 'Número inválido.';
                    }
                    if (amount <= 0) {
                      return 'O montante deve ser positivo.';
                    }
                    if (_totalDebited > (widget.currentUser.balance['AOA'] ?? 0.0)) {
                      return 'Saldo insuficiente. Necessita de ${NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz').format(_totalDebited)}.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),
                _buildFeeSummary(
                    context, NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz'),
                    fee: _fee,
                    totalDebited: _totalDebited,
                    amountText: _amountController.text),
                SizedBox(height: 32.h),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: isButtonDisabled ? null : _submitBankRequest,
                        child: const Text('Solicitar Levantamento'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Tab 2: QR Code Withdrawal
class QrWithdrawalTab extends StatefulWidget {
  final UserModel currentUser;

  const QrWithdrawalTab({super.key, required this.currentUser});

  @override
  State<QrWithdrawalTab> createState() => _QrWithdrawalTabState();
}

class _QrWithdrawalTabState extends State<QrWithdrawalTab>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  final bool _isLoading = false;
  double _aferconFee = 0.0;
  double _agentFee = 0.0;
  double _totalDebited = 0.0;
  static const double _aferconFeePercentage = 0.015; // 1.5%
  static const double _agentFeePercentage = 0.035; // 3.5%
  static const double _unverifiedTransactionLimit = 100000.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateFee);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateFee);
    _amountController.dispose();
    super.dispose();
  }

  void _updateFee() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    setState(() {
      _aferconFee = (amount * _aferconFeePercentage * 100).round() / 100;
      _agentFee = (amount * _agentFeePercentage * 100).round() / 100;
      _totalDebited = amount + _aferconFee + _agentFee;
    });
  }

  Future<void> _onGenerateQrPressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final bool isPinConfirmed = await showPinConfirmationDialog(context);
    if (!isPinConfirmed || !mounted) {
      return;
    }

    final String amount = _amountController.text.replaceAll(',', '.');

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReceiveQrScreen(
        amount: double.parse(amount),
        transactionType: 'withdrawal',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final remainingKycLimit = _unverifiedTransactionLimit -
        widget.currentUser.unverifiedTransactionVolume;
    final bool isKycVerified =
        widget.currentUser.kycStatus == KycStatus.approved;
    final isButtonDisabled =
        _isLoading || (!isKycVerified && remainingKycLimit <= 0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, widget.currentUser.balance['AOA'] ?? 0.0,
                    widget.currentUser.kycStatus, remainingKycLimit,
                    isBank: false),
                SizedBox(height: 24.h),
                Text(
                  'Insira o montante que deseja levantar e gere um QR code para apresentar a um agente autorizado.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                      labelText: 'Montante a Levantar', suffixText: 'Kz'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Insira o montante.';
                    }
                    final amount = double.tryParse(value.replaceAll(',', '.'));
                    if (amount == null) {
                      return 'Número inválido.';
                    }
                    if (amount <= 0) {
                      return 'O montante deve ser positivo.';
                    }
                    if (_totalDebited > (widget.currentUser.balance['AOA'] ?? 0.0)) {
                      return 'Saldo insuficiente. Necessita de ${NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz').format(_totalDebited)}.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),
                _buildAgentFeeSummary(context,
                    NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz'),
                    aferconFee: _aferconFee,
                    agentFee: _agentFee,
                    totalDebited: _totalDebited,
                    amountText: _amountController.text),
                SizedBox(height: 32.h),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Gerar QR Code'),
                  onPressed: isButtonDisabled ? null : _onGenerateQrPressed,
                  style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Common helper widgets
Widget _buildHeader(BuildContext context, double balance, KycStatus kycStatus,
    double remainingKycLimit,
    {required bool isBank}) {
  final theme = Theme.of(context);
  final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');
  final bool isKycVerified = kycStatus == KycStatus.approved;

  return Column(
    children: [
      Text(
          isBank
              ? 'Preencha os dados para o levantamento.'
              : 'Levantamento com Agente',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge),
      SizedBox(height: 8.h),
      Text('Saldo disponível: ${currencyFormat.format(balance)}',
          textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
      if (!isKycVerified) ...[
        SizedBox(height: 20.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer.withAlpha(128),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: theme.colorScheme.onTertiaryContainer, size: 28.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A sua conta não foi verificada.',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4.h),
                    Text(
                      'O seu limite restante para levantamentos é de ${currencyFormat.format(remainingKycLimit > 0 ? remainingKycLimit : 0)}.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

Widget _buildFeeSummary(BuildContext context, NumberFormat currencyFormat,
    {required double fee,
    required double totalDebited,
    required String amountText}) {
  final theme = Theme.of(context);

  if (amountText.isEmpty || totalDebited <= 0) {
    return const SizedBox.shrink();
  }

  return Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
        color: theme.primaryColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12.r)),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Taxa de serviço (1%)', style: theme.textTheme.bodyMedium),
            Text(currencyFormat.format(fee), style: theme.textTheme.bodyMedium)
          ],
        ),
        const Divider(height: 17),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total a ser debitado',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(currencyFormat.format(totalDebited),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}

Widget _buildAgentFeeSummary(BuildContext context, NumberFormat currencyFormat,
    {required double aferconFee,
    required double agentFee,
    required double totalDebited,
    required String amountText}) {
  final theme = Theme.of(context);

  if (amountText.isEmpty || totalDebited <= 0) {
    return const SizedBox.shrink();
  }

  return Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
        color: theme.primaryColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12.r)),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Taxa Afercon Pay (1.5%)', style: theme.textTheme.bodyMedium),
            Text(currencyFormat.format(aferconFee),
                style: theme.textTheme.bodyMedium)
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Taxa do Agente (3.5%)', style: theme.textTheme.bodyMedium),
            Text(currencyFormat.format(agentFee),
                style: theme.textTheme.bodyMedium)
          ],
        ),
        const Divider(height: 17),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total a ser debitado',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(currencyFormat.format(totalDebited),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}
