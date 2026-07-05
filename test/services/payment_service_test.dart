import 'package:cine_book/models/booking_models.dart';
import 'package:cine_book/services/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses successful payment return URL', () {
    final result = PaymentService.parseReturnUrl(
      'cineluxe://payment-return?bookingId=BK-1&status=success&responseCode=00',
    );

    expect(result, isNotNull);
    expect(result!.bookingId, 'BK-1');
    expect(result.status, ApiPaymentStatus.success);
    expect(result.isSuccess, isTrue);
  });

  test('ignores unrelated and incomplete URLs', () {
    expect(PaymentService.parseReturnUrl('https://example.com'), isNull);
    expect(PaymentService.parseReturnUrl('cineluxe://payment-return'), isNull);
  });

  test('recognizes backend VNPay return pages', () {
    expect(
      PaymentService.isBackendPaymentReturnUrl(
        'http://192.168.1.18:8080/api/payments/vnpay/return?vnp_ResponseCode=00',
      ),
      isTrue,
    );
    expect(
      PaymentService.isBackendPaymentReturnUrl(
        'https://example.com/v1/payments/vnpay/return?vnp_ResponseCode=24',
      ),
      isTrue,
    );
    expect(
      PaymentService.isBackendPaymentReturnUrl('https://example.com/other'),
      isFalse,
    );
  });
}
