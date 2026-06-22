/// Payment gateway fallback service.
///
/// Requirements: 49.3
/// When VNPay is unreachable (CircuitOpenException or network error),
/// offer "Pay at counter" option with a booking reference code.
class PaymentGatewayFallback {
  PaymentGatewayFallback._();
  static final PaymentGatewayFallback instance = PaymentGatewayFallback._();

  /// Returns a booking reference code for counter payment.
  ///
  /// The reference code is derived from the [bookingId] for easy lookup.
  String generateCounterPaymentReference(String bookingId) {
    // Use last 8 chars of booking ID as counter reference for readability.
    final ref = bookingId.replaceAll('-', '').toUpperCase();
    return ref.length > 8 ? ref.substring(ref.length - 8) : ref;
  }

  /// Formats the pay-at-counter message for the user.
  ///
  /// Returns a [PayAtCounterInfo] with a reference code and instructions.
  PayAtCounterInfo buildPayAtCounterInfo(String bookingId) {
    final ref = generateCounterPaymentReference(bookingId);
    return PayAtCounterInfo(
      referenceCode: ref,
      bookingId: bookingId,
      message:
          'Không thể kết nối cổng thanh toán VNPay. '
          'Vui lòng đến quầy và đưa mã đặt vé cho nhân viên để thanh toán.',
      instructions: [
        'Đến quầy vé trong vòng 30 phút.',
        'Cung cấp mã đặt vé: $ref',
        'Thanh toán tại quầy bằng tiền mặt hoặc thẻ.',
      ],
    );
  }
}

/// Information for pay-at-counter fallback.
class PayAtCounterInfo {
  const PayAtCounterInfo({
    required this.referenceCode,
    required this.bookingId,
    required this.message,
    required this.instructions,
  });

  /// Short reference code for counter staff lookup.
  final String referenceCode;

  /// Full booking ID for backend lookup.
  final String bookingId;

  /// User-facing message explaining why the fallback was triggered.
  final String message;

  /// Step-by-step instructions for the customer.
  final List<String> instructions;
}
