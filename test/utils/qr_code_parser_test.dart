import 'package:cine_book/utils/qr_code_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses CineLuxe QR ticket format', () {
    final ticket = parseQrTicket('CINELUXE|BK-1|U-1|ST001|A1-A2');

    expect(ticket.bookingId, 'BK-1');
    expect(ticket.userId, 'U-1');
    expect(ticket.showtimeId, 'ST001');
    expect(ticket.seats, ['A1', 'A2']);
  });

  test('rejects malformed QR values', () {
    expect(
      () => parseQrTicket('OTHER|BK-1|U-1|ST001|A1'),
      throwsA(isA<QrCodeFormatException>()),
    );
    expect(
      () => parseQrTicket('CINELUXE|BK-1|U-1|ST001|bad-seat'),
      throwsA(isA<QrCodeFormatException>()),
    );
  });

  test('extracts booking id from QR data and pasted text', () {
    const bookingId = 'BK-448fd3bc-4a4b-4d03-8b6b-949377ad888a';

    expect(
      parseTicketBookingId('CINELUXE|$bookingId|U-1|ST001|A1-A2'),
      bookingId,
    );
    expect(parseTicketBookingId('Mã booking: $bookingId'), bookingId);
  });
}
