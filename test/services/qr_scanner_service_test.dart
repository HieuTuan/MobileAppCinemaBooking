import 'package:cine_book/services/qr_scanner_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  test('configures QR-only scanner with explicit lifecycle', () {
    final service = QrScannerService();

    expect(service.controller.autoStart, isFalse);
    expect(service.controller.formats, [BarcodeFormat.qrCode]);
    expect(service.controller.detectionSpeed, DetectionSpeed.noDuplicates);
  });
}
