import 'dart:async';

import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerService {
  QrScannerService()
    : controller = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
      );

  final MobileScannerController controller;
  StreamSubscription<BarcodeCapture>? _subscription;
  final StreamController<String> _codes = StreamController.broadcast();

  Stream<String> get codes => _codes.stream;

  Future<void> startScanning() async {
    _subscription ??= controller.barcodes.listen((capture) {
      for (final barcode in capture.barcodes) {
        final value = barcode.rawValue;
        if (value != null && value.trim().isNotEmpty) {
          _codes.add(value);
          break;
        }
      }
    });
    await controller.start();
  }

  Future<void> stopScanning() async {
    await controller.stop();
  }

  Future<void> toggleTorch() => controller.toggleTorch();

  Future<void> dispose({bool disposeController = true}) async {
    await _subscription?.cancel();
    if (disposeController) controller.dispose();
    await _codes.close();
  }
}
