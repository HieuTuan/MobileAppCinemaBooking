import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../api/api_client.dart';
import '../../../models/booking_models.dart';
import '../../core/formatters.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  late final Future<BookingQr> _ticket = APIClient().getBookingQr(
    widget.bookingId,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vé của bạn')),
      body: FutureBuilder<BookingQr>(
        future: _ticket,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Không thể tải vé QR: ${snapshot.error}'),
            );
          }
          return _TicketContent(ticket: snapshot.requireData);
        },
      ),
    );
  }
}

class _TicketContent extends StatelessWidget {
  const _TicketContent({required this.ticket});

  final BookingQr ticket;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.2, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.elasticOut,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 72),
        ),
        const SizedBox(height: 12),
        Text(
          'Thanh toán thành công',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _FullScreenQr(ticket: ticket)),
            ),
            child: Hero(
              tag: ticket.bookingId,
              child: QrImageView(
                data: ticket.qrCode,
                size: 300,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          ticket.movieTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(
          '${shortDate(ticket.showtimeDateTime)} ${shortTime(ticket.showtimeDateTime)}',
        ),
        Text('${ticket.cinemaName} - ${ticket.roomName}'),
        Text('Ghế: ${ticket.seatCodes.join(', ')}'),
        Text('Mã booking: ${ticket.bookingId}'),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Hoàn tất'),
        ),
      ],
    );
  }
}

class _FullScreenQr extends StatelessWidget {
  const _FullScreenQr({required this.ticket});

  final BookingQr ticket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ticket.movieTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: ticket.bookingId,
                child: QrImageView(
                  data: ticket.qrCode,
                  size: 340,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text('${ticket.cinemaName} - ${ticket.roomName}'),
              Text('Ghế: ${ticket.seatCodes.join(', ')}'),
            ],
          ),
        ),
      ),
    );
  }
}
