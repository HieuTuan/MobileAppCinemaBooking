import 'package:cine_book/models/booking_models.dart';
import 'package:cine_book/src/state/cinema_store.dart';
import 'package:cine_book/websocket/seat_update.dart' as realtime;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies REST snapshot and WebSocket seat updates', () {
    final store = CinemaStore();
    store.applySeatMap(
      const SeatMap(
        showtimeId: 'ST001',
        seats: [
          ApiSeat(
            code: 'A1',
            row: 'A',
            column: 1,
            type: 'standard',
            status: ApiSeatStatus.held,
          ),
          ApiSeat(
            code: 'A2',
            row: 'A',
            column: 2,
            type: 'standard',
            status: ApiSeatStatus.available,
          ),
        ],
      ),
    );
    expect(store.heldSeats('ST001'), contains('A1'));

    store.applySeatUpdate(
      'ST001',
      const realtime.SeatUpdate(
        seatCode: 'A1',
        status: realtime.SeatStatus.available,
      ),
    );
    store.applySeatUpdate(
      'ST001',
      const realtime.SeatUpdate(
        seatCode: 'A2',
        status: realtime.SeatStatus.booked,
      ),
    );

    expect(store.heldSeats('ST001'), isNot(contains('A1')));
    expect(store.bookedSeats('ST001'), contains('A2'));
  });
}
