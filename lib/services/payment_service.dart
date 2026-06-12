import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../api/api_client.dart';
import '../models/booking_models.dart';

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
    final webResult = await Navigator.of(context).push<PaymentResult>(
      MaterialPageRoute(
        builder: (_) =>
            PaymentWebViewScreen(bookingId: bookingId, paymentUrl: paymentUrl),
      ),
    );
    return webResult ?? pollPaymentStatus(bookingId);
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
    if (uri == null ||
        uri.scheme != 'cineluxe' ||
        uri.host != 'payment-return') {
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
}

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.bookingId,
    required this.paymentUrl,
  });

  final String bookingId;
  final String paymentUrl;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  Timer? _timeoutTimer;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress),
          onNavigationRequest: (request) {
            final result = PaymentService.parseReturnUrl(request.url);
            if (result != null) {
              Navigator.of(context).pop(result);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
    _timeoutTimer = Timer(const Duration(minutes: 15), () {
      if (!mounted) return;
      Navigator.of(context).pop(
        PaymentResult(
          bookingId: widget.bookingId,
          status: ApiPaymentStatus.timeout,
          message: 'Payment expired after 15 minutes',
        ),
      );
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('VNPay'),
          actions: [
            IconButton(
              tooltip: 'Reload',
              onPressed: _controller.reload,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Close and verify status',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(value: _progress / 100),
                )
              : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
