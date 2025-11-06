import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// This screen is responsible for scanning QR codes.
/// It uses the mobile_scanner package to provide a camera view
/// and detect QR codes from the stream.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back, // Changed to back camera for better UX
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  /// Handles the detection of a barcode.
  void _onBarcodeDetected(BarcodeCapture capture) {
    // Avoid processing multiple times for the same QR code.
    if (_isProcessing) {
      return;
    }

    // A capture can contain multiple barcodes, we only need the first one.
    final Barcode? barcode = capture.barcodes.firstOrNull;

    if (barcode != null && barcode.rawValue != null) {
      setState(() {
        _isProcessing = true;
      });

      final String scannedCode = barcode.rawValue!;
      debugPrint('QR Code Detected: $scannedCode');

      // Pop the screen and return the scanned code to the previous screen.
      if (mounted) {
        Navigator.of(context).pop(scannedCode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Define the scan window area.
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
          // The main camera scanner view.
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetected,
            scanWindow: scanWindow,
            errorBuilder: (context, error) {
              // CORRECTED: The errorBuilder signature now only has two parameters.
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Ocorreu um erro ao iniciar a câmara: ${error.toString()}',
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          // A custom painter to draw an overlay over the camera view.
          CustomPaint(
            painter: _ScannerOverlayPainter(scanWindow: scanWindow),
          ),
          // A simple instruction text for the user.
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.black.withAlpha(102), // ~40% opacity
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

/// This painter is used to create a visual overlay for the QR scanner.
/// It darkens the area outside the [scanWindow] and draws a border around it.
class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  _ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()..addRect(scanWindow);

    // Create a path that is the difference between the full screen and the scan window.
    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    // Paint for the dark overlay.
    final overlayPaint = Paint()
      ..color = Colors.black.withAlpha(153) // ~60% opacity
      ..style = PaintingStyle.fill;
      
    // Paint for the border around the scan window.
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
