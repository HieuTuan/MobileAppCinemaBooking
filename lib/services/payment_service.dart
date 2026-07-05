import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../models/booking_models.dart';
import 'payment_webview_screen_stub.dart'
    if (dart.library.io) 'payment_webview_screen.dart';

class PaymentResult {
  const PaymentResult({
    required this.bookingId,
    required this.status,
    this.responseCode,
    this.message,
  });

  final String bookingId;
  final ApiPaymentStatus status;
  final String? responseCode;
  final String? message;

  bool get isSuccess => status == ApiPaymentStatus.success;
}

class PaymentService {
  PaymentService({APIClient? apiClient})
    : _apiClient = apiClient ?? APIClient();

  final APIClient _apiClient;

  Future<PaymentResult> processPayment(
    BuildContext context,
    String bookingId,
    String paymentUrl,
  ) async {
    // On Flutter Web, webview_flutter is not supported.
    // Open URL in a new browser tab and poll for payment status.
    if (kIsWeb) {
      return _processPaymentWeb(context, bookingId, paymentUrl);
    }
    // On mobile (Android/iOS) use the embedded WebView.
    final webResult = await Navigator.of(context).push<PaymentResult>(
      MaterialPageRoute(
        builder: (_) =>
            PaymentWebViewScreen(bookingId: bookingId, paymentUrl: paymentUrl),
      ),
    );
    return webResult ?? pollPaymentStatus(bookingId);
  }

  /// Web fallback: launch payment URL in browser tab, then poll backend.
  Future<PaymentResult> _processPaymentWeb(
    BuildContext context,
    String bookingId,
    String paymentUrl,
  ) async {
    final uri = Uri.parse(paymentUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      return PaymentResult(
        bookingId: bookingId,
        status: ApiPaymentStatus.failed,
        message: 'Could not open payment page',
      );
    }
    if (!context.mounted) {
      return pollPaymentStatus(bookingId);
    }
    // Show dialog so user knows to return here after completing payment
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn tất thanh toán'),
        content: const Text(
          'Trang thanh toán VNPay đã mở trong trình duyệt.\n\n'
          'Sau khi hoàn tất, nhấn "Đã thanh toán" để xác nhận.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đã thanh toán'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return PaymentResult(
        bookingId: bookingId,
        status: ApiPaymentStatus.failed,
        message: 'User cancelled',
      );
    }
    return pollPaymentStatus(bookingId, timeout: const Duration(seconds: 60));
  }

  Future<PaymentResult> pollPaymentStatus(
    String bookingId, {
    Duration interval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    do {
      final result = await _apiClient.getPaymentStatus(bookingId);
      if (result.paymentStatus != ApiPaymentStatus.pending &&
          result.paymentStatus != ApiPaymentStatus.processing) {
        return PaymentResult(
          bookingId: bookingId,
          status: result.paymentStatus,
          responseCode: result.responseCode,
        );
      }
      await Future<void>.delayed(interval);
    } while (DateTime.now().isBefore(deadline));
    return PaymentResult(
      bookingId: bookingId,
      status: ApiPaymentStatus.timeout,
      message: 'Payment status confirmation timed out',
    );
  }

  static PaymentResult? parseReturnUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !isAppPaymentReturnUrl(uri)) {
      return null;
    }
    final bookingId = uri.queryParameters['bookingId'];
    final statusText = uri.queryParameters['status'];
    if (bookingId == null || statusText == null) return null;
    final status = ApiPaymentStatus.values
        .where((item) => item.name == statusText)
        .firstOrNull;
    if (status == null) return null;
    return PaymentResult(
      bookingId: bookingId,
      status: status,
      responseCode: uri.queryParameters['responseCode'],
    );
  }

  static bool isAppPaymentReturnUrl(Uri uri) {
    return (uri.scheme == 'cineluxe' || uri.scheme == 'cinema') &&
        uri.host == 'payment-return';
  }

  static bool isBackendPaymentReturnUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }
    final normalizedPath = uri.path.replaceFirst(RegExp(r'/+$'), '');
    return normalizedPath == '/api/payments/vnpay/return' ||
        normalizedPath == '/v1/payments/vnpay/return';
  }
}
