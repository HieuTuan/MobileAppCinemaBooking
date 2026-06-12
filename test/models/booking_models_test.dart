import 'package:cine_book/models/booking_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses seat map and hold response', () {
    final seatMap = SeatMap.fromJson({
      'showtimeId': 'ST001',
      'seats': [
        {
          'code': 'A1',
          'row': 'A',
          'column': 1,
          'type': 'standard',
          'status': 'held',
        },
      ],
    });
    final hold = HoldResponse.fromJson({
      'holdId': 'HOLD-1',
      'showtimeId': 'ST001',
      'seatCodes': ['A1'],
      'expiresAt': '2026-06-11T16:00:00Z',
    });

    expect(seatMap.seats.single.status, ApiSeatStatus.held);
    expect(hold.seatCodes, ['A1']);
  });

  test('serializes combo selection and create booking request', () {
    const request = CreateBookingRequest(
      holdId: 'HOLD-1',
      userId: 'U1',
      combos: [ComboSelection(comboId: 'CB01', quantity: 2)],
    );

    expect(request.toJson(), {
      'holdId': 'HOLD-1',
      'userId': 'U1',
      'combos': [
        {'comboId': 'CB01', 'quantity': 2},
      ],
    });
  });

  test('parses ticket validation result', () {
    final result = ValidationResult.fromJson({
      'success': true,
      'status': 'used',
      'message': 'Ticket validated successfully',
      'bookingId': 'BK-1',
      'customerName': 'U-1',
      'movieTitle': 'CineLuxe Premiere',
      'showtimeId': 'ST001',
      'showtimeDateTime': '2026-06-12T12:00:00Z',
      'seatCodes': ['A1'],
      'validatedAt': '2026-06-12T11:00:00Z',
    });

    expect(result.success, isTrue);
    expect(result.status, 'used');
    expect(result.seatCodes, ['A1']);
  });
}
