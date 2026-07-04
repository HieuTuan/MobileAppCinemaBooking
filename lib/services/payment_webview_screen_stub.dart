import 'package:flutter/material.dart';

class PaymentWebViewScreen extends StatelessWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.bookingId,
    required this.paymentUrl,
  });

  final String bookingId;
  final String paymentUrl;

  @override
  Widget build(BuildContext context) {
    throw UnsupportedError('Embedded payment WebView is not supported on web.');
  }
}
