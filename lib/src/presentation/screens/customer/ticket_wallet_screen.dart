part of '../../../app.dart';

class TicketWallet extends StatelessWidget {
  const TicketWallet({super.key, required this.bookings});

  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(child: Text('Vi ve dang trong.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingTile(
          booking: booking,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(booking: booking),
            ),
          ),
        );
      },
    );
  }
}
