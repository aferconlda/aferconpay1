import 'package:afercon_pay/screens/qr_code/pay_with_qr_screen.dart';
import 'package:afercon_pay/utils/qr_code_parser.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _isWebUnsupported = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      setState(() {
        _isWebUnsupported = true;
      });
    } else {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

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

      final String scannedCode = barcode.rawValue!;
      debugPrint('QR Code Detected: $scannedCode');

      try {
        final qrParser = QrCodeParser(scannedCode);
        final parsedData = await qrParser.parse();

        final recipientId = parsedData['uid'];
        final amount = parsedData['amount'];

        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PayWithQrScreen(
                recipientId: recipientId,
                amount: amount,
              ),
            ),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      } on FormatException catch (e) {
        _showErrorSnackBar(e.message);
        debugPrint('Error processing QR Code: $e');
        setState(() {
          _isProcessing = false;
        });
      } catch (e) {
        _showErrorSnackBar('Ocorreu um erro desconhecido ao processar o código.');
        debugPrint('Error processing QR Code: $e');
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isWebUnsupported) {
      return Scaffold(
        appBar: const CustomAppBar(title: Text('Ler Código QR')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'A leitura de código QR não é suportada nesta plataforma. Por favor, utilize a aplicação móvel.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final double scanBoxSize = 250.0;

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Ler Código QR')),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _scannerController!,
              onDetect: _onBarcodeDetected,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Ocorreu um erro ao iniciar a câmara: $error',
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
                  'Aponte a câmara para o código QR para fazer a leitura.',
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
                onPressed: () => _scannerController?.toggleTorch(),
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
