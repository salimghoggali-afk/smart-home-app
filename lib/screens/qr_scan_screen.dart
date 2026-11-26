import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/firebase_link_config.dart';

/// Camera screen that reads a link QR code and returns the config.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  String? _error;
  bool _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (raw == null) continue;
      try {
        final config = FirebaseLinkConfig.parse(raw,
            androidPackage: 'com.ghoggalisalim.smarthome');
        _done = true;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(config);
        return;
      } on FormatException catch (e) {
        setState(() => _error = e.message);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final box = size.width * 0.7;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Scan link code',
            style: TextStyle(color: Colors.white)),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (_, state, _) => IconButton(
              tooltip: 'Flashlight',
              icon: Icon(state.torchState == TorchState.on
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded),
              onPressed: _controller.toggleTorch,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(error: error),
          ),
          IgnorePointer(
            child: CustomPaint(painter: _FramePainter(box)),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey(_error),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: _error == null
                      ? Colors.black.withValues(alpha: 0.55)
                      : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _error ?? 'Point the camera at the QR code of your home.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _error == null
                        ? Colors.white
                        : Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});
  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.no_photography_outlined,
              color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Text(
            denied
                ? 'The app needs the camera to scan the code. Allow it in the phone settings, or enter the details by hand.'
                : 'The camera could not start. You can enter the details by hand instead.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ]),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.box);
  final double box;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
        center: size.center(Offset.zero), width: box, height: box);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    final shade = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rr)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(shade, Paint()..color = Colors.black.withValues(alpha: 0.5));

    final p = Paint()
      ..color = const Color(0xFF3FE0C5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const l = 34.0;
    final r = rect;
    for (final (o, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      final path = Path()
        ..moveTo(o.dx, o.dy + dy * l)
        ..lineTo(o.dx, o.dy + dy * 14)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + dx * 14, o.dy)
        ..lineTo(o.dx + dx * l, o.dy);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.box != box;
}
