import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/cashier_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/services/pin_service.dart';
import 'package:afercon_pay/utils/qr_code_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CashierDepositScreen extends StatefulWidget {
  const CashierDepositScreen({super.key});

  @override
  State<CashierDepositScreen> createState() => _CashierDepositScreenState();
}

class _CashierDepositScreenState extends State<CashierDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  // Serviços
  final _firestoreService = FirestoreService();
  final _cashierService = CashierService();
  final _pinService = PinService();

  // Controladores
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  // Estado
  UserModel? _foundClient;
  bool _isSearching = false;
  bool _isProcessing = false;
  String? _searchError;

  double _transactionFee = 0.0;
  double _netAmount = 0.0;
  static const double _feeRate = 0.045;
  final _currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateFeeCalculation);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.removeListener(_updateFeeCalculation);
    _amountController.dispose();
    super.dispose();
  }

  void _updateFeeCalculation() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _transactionFee = amount * _feeRate;
      _netAmount = amount - _transactionFee;
    });
  }

  Future<void> _findClientByPhone() async {
    if (_phoneController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundClient = null;
      _searchError = null;
    });

    try {
      final client = await _firestoreService.findUserByPhone(_phoneController.text.trim());
      if (!mounted) return;
      if (client == null) {
        setState(() => _searchError = 'Nenhum cliente encontrado com este número.');
      } else {
        setState(() => _foundClient = client);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searchError = 'Ocorreu um erro ao procurar o cliente.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _processDeposit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _foundClient == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final pinConfirmed = await _showPinConfirmationDialog();
    if (pinConfirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      await _cashierService.processQrTransaction({
        'clientUid': _foundClient!.uid,
        'amount': amount,
        'type': 'deposit',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Depósito realizado com sucesso!'),
            backgroundColor: Colors.green[600],
          ),
        );
        _formKey.currentState?.reset();
        _phoneController.clear();
        _amountController.clear();
        setState(() {
          _foundClient = null;
          _searchError = null;
        });
      }
    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
                backgroundColor: Theme.of(context).colorScheme.error,
                ),
            );
        }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _navigateToScanQr() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const ScanQrAndProcessScreen(),
      ),
    );

    if (result != null && mounted) {
        final String? clientUid = result['uid'];
        final double? amount = result['amount'];

        if(clientUid != null) {
            setState(() {
                _isSearching = true;
                _foundClient = null;
                _searchError = null;
            });

            try {
                final client = await _firestoreService.getUser(clientUid);
                if (!mounted) return;

                if (client == null) {
                    setState(() => _searchError = 'Cliente do QR Code não encontrado.');
                } else {
                    setState(() {
                        _foundClient = client;
                        if (amount != null && amount > 0) {
                            _amountController.text = amount.toStringAsFixed(2);
                        }
                    });
                }
            } catch (e) {
                if (mounted) {
                    setState(() => _searchError = 'Erro ao obter dados do cliente.');
                }
            } finally {
                if (mounted) {
                    setState(() => _isSearching = false);
                }
            }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Aceitar Depósito de Cliente')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchCard(theme),
              if (_searchError != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(_searchError!, style: TextStyle(color: theme.colorScheme.error)),
                ),
              SizedBox(height: 24.h),
              if (_isSearching)
                const Center(child: CircularProgressIndicator()),
              if (_foundClient != null) _buildDepositForm(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('1. Encontrar o Cliente', style: theme.textTheme.titleLarge),
        SizedBox(height: 16.h),
        ElevatedButton.icon(
          onPressed: _navigateToScanQr,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Escanear QR Code do Cliente'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
          ),
        ),
        SizedBox(height: 24.h),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text('OU', style: theme.textTheme.labelMedium),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        SizedBox(height: 24.h),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Nº de Telemóvel do Cliente', prefixIcon: Icon(Icons.phone)),
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16.h),
        ElevatedButton.icon(
          onPressed: _isSearching ? null : _findClientByPhone,
          icon: _isSearching ? const SizedBox.shrink() : const Icon(Icons.search),
          label: _isSearching ? const CircularProgressIndicator() : const Text('Procurar Cliente por Telemóvel'),
        ),
      ],
    );
  }

  Widget _buildDepositForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('2. Confirmar Detalhes', style: theme.textTheme.titleLarge),
        SizedBox(height: 16.h),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.green, size: 40),
            title: Text(_foundClient!.displayName ?? 'Nome não disponível', style: theme.textTheme.titleMedium),
            subtitle: Text('Cliente: ${_foundClient!.email ?? 'Email não disponível'}'),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(labelText: 'Valor a Depositar (Kz)', prefixIcon: Icon(Icons.attach_money)),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Insira um valor.';
            final amount = double.tryParse(value) ?? 0;
            if (amount <= 0) return 'O valor deve ser positivo.';
            if (_netAmount <= 0) return 'O valor final a depositar deve ser positivo após taxas.';
            return null;
          },
        ),
        SizedBox(height: 16.h),
        if (_amountController.text.isNotEmpty && (double.tryParse(_amountController.text) ?? 0) > 0)
          _buildFeeSummaryCard(theme),
        SizedBox(height: 24.h),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processDeposit,
          style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16.h), backgroundColor: Colors.green),
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('CONFIRMAR DEPÓSITO'),
        ),
      ],
    );
  }

  Widget _buildFeeSummaryCard(ThemeData theme) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumo da Transação', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 12.h),
            _buildSummaryRow('Valor do Depósito:', _currencyFormat.format(amount)),
            const Divider(),
            _buildSummaryRow('Taxa de Serviço (4.5%):', '- ${_currencyFormat.format(_transactionFee)}'),
            const Divider(),
            _buildSummaryRow('Valor Creditado ao Cliente:', _currencyFormat.format(_netAmount), isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          Text(value, style: isTotal
            ? theme.textTheme.titleLarge?.copyWith(fontSize: 16.sp, fontWeight: FontWeight.bold)
            : theme.textTheme.bodyMedium?.copyWith(fontSize: 15.sp)),
        ],
      ),
    );
  }

  Future<bool?> _showPinConfirmationDialog() {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);

        return AlertDialog(
          title: const Text('Confirmar Operação'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Para sua segurança, por favor insira o seu PIN de 4 dígitos.'),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value?.length ?? 0) < 4 ? 'PIN inválido' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => navigator.pop(false), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final storedPin = await _pinService.getPin();
                  if (!mounted) return;
                  if (storedPin == pinController.text) {
                    navigator.pop(true);
                  } else {
                    messenger.showSnackBar(const SnackBar(
                      content: Text('PIN Incorreto.'),
                      backgroundColor: Colors.red,
                    ));
                    navigator.pop(false);
                  }
                }
              },
              child: const Text('CONFIRMAR'),
            ),
          ],
        );
      },
    );
  }
}

// --- Ecrã de Leitura de QR Implementado ---
class ScanQrAndProcessScreen extends StatefulWidget {
  const ScanQrAndProcessScreen({super.key});

  @override
  State<ScanQrAndProcessScreen> createState() => _ScanQrAndProcessScreenState();
}

class _ScanQrAndProcessScreenState extends State<ScanQrAndProcessScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final Barcode? barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final qrParser = QrCodeParser(barcode.rawValue!);
        final parsedData = await qrParser.parse();

        if (mounted) {
          // Retorna os dados lidos para o ecrã anterior
          Navigator.of(context).pop(parsedData);
        }
      } on FormatException catch (e) {
        _showErrorSnackBar(e.message);
        setState(() => _isProcessing = false);
      } catch (e) {
        _showErrorSnackBar('Erro desconhecido ao processar o código.');
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double scanBoxSize = 250.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR do Cliente')),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: _onBarcodeDetected,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Erro ao iniciar a câmara: $error',
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
            CustomPaint(
              painter: _ScannerOverlayPainter(scanBoxSize: scanBoxSize),
            ),
             Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Colors.black.withAlpha(102), // ~40% opacity
                child: const Text(
                  'Aponte a câmara para o código QR do cliente.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
                onPressed: () => _scannerController.toggleTorch(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withAlpha(128), // ~50% opacity
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanBoxSize;

  _ScannerOverlayPainter({required this.scanBoxSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect scanWindow = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: scanBoxSize,
      height: scanBoxSize,
    );

    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        scanWindow,
        const Radius.circular(12),
      ));

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final overlayPaint = Paint()
      ..color = Colors.black.withAlpha(153) // ~60% opacity
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(overlayPath, overlayPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanBoxSize != scanBoxSize;
  }
}
