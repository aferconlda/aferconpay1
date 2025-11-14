
import 'dart:convert';
import 'package:afercon_pay/screens/qr_code/pay_with_qr_screen.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import for platform checking
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  // Controller is nullable to handle the web platform case
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _isWebUnsupported = false;


  @override
  void initState() {
    super.initState();
    // Conditionally initialize the scanner only on non-web platforms.
    if (kIsWeb) {
      setState(() {
        _isWebUnsupported = true;
      });
    } else {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back, 
      );
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  
  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) {
      return;
    }

    final Barcode? barcode = capture.barcodes.firstOrNull;

    if (barcode != null && barcode.rawValue != null) {
      setState(() {
        _isProcessing = true;
      });

      final String scannedCode = barcode.rawValue!;
      debugPrint('QR Code Detected: $scannedCode');

      try {
        final data = jsonDecode(scannedCode);
        final recipientId = data['uid'];
        final amount = data['amount'] as double?;

        if (recipientId != null) {
          // Navigate to the payment screen with the recipient's UID and amount.
          if (mounted) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => PayWithQrScreen(
                recipientId: recipientId,
                amount: amount, // Pass the amount to the next screen
              ),
            ));
          }
        } else {
          throw Exception('QR code inválido: UID em falta.');
        }
      } catch (e) {
        // Handle invalid QR code format
        setState(() {
          _isProcessing = false; // Allow scanning again
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Código QR inválido ou ilegível. Tente novamente.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        debugPrint('Error processing QR Code: $e');
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

    // This part will only build if not on the web
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 250,
      height: 250,
    );

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Ler Código QR')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController!, // Controller is guaranteed to be non-null here
            onDetect: _onBarcodeDetected,
            scanWindow: scanWindow,
            // CORRECTED: The errorBuilder function signature now has only two parameters as expected.
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
            painter: _ScannerOverlayPainter(scanWindow: scanWindow),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.black.withAlpha(102), 
              child: const Text(
                'Aponte a câmara para o código QR para fazer a leitura.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  _ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()..addRect(scanWindow);
    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final overlayPaint = Paint()
      ..color = Colors.black.withAlpha(153) 
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(overlayPath, overlayPaint);
    canvas.drawRect(scanWindow, borderPaint);
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}
