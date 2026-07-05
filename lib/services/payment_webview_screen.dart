import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../api/api_client.dart';
import '../models/booking_models.dart';
import 'payment_service.dart';

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
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (url) {
            final result = PaymentService.parseReturnUrl(url);
            if (result != null) {
              _complete(result);
            }
          },
          onPageFinished: (url) {
            if (PaymentService.isBackendPaymentReturnUrl(url)) {
              _completeFromCurrentStatus();
            }
          },
          onUrlChange: (change) {
            if (change.url != null) {
              final result = PaymentService.parseReturnUrl(change.url!);
              if (result != null) {
                _complete(result);
              }
            }
          },
          onNavigationRequest: (request) {
            final result = PaymentService.parseReturnUrl(request.url);
            if (result != null) {
              _complete(result);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
    _timeoutTimer = Timer(const Duration(minutes: 15), () {
      if (!mounted) return;
      _complete(
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

  void _complete(PaymentResult? result) {
    if (_completed || !mounted) return;
    _completed = true;
    Navigator.of(context).pop(result);
  }

  Future<void> _completeFromCurrentStatus() async {
    if (_completed) return;
    try {
      final status = await APIClient().getPaymentStatus(widget.bookingId);
      _complete(
        PaymentResult(
          bookingId: widget.bookingId,
          status: status.paymentStatus,
          responseCode: status.responseCode,
        ),
      );
    } catch (_) {
      _complete(null);
    }
  }

  Future<void> _handleBackPressed() async {
    if (_completed || !mounted) return;
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    _complete(null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPressed();
      },
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
              onPressed: () => _complete(null),
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
