part of '../../../app.dart';

class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final qrData =
        '${booking.id}|${booking.customerName}|${booking.movieTitle}|${booking.status.name.toUpperCase()}';
    return Scaffold(
      appBar: AppBar(title: Text(booking.id), backgroundColor: _surface),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _gold.withValues(alpha: .24)),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 18),
                Text(
                  booking.movieTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusPill(
                  color: _statusColor(booking.status),
                  textColor: Colors.white,
                  label: booking.status.name.toUpperCase(),
                ),
                const Divider(height: 34),
                _InfoLine(label: 'Ma ve', value: booking.id),
                _InfoLine(label: 'Khach', value: booking.customerName),
                _InfoLine(label: 'Rap', value: booking.showtime.branch),
                _InfoLine(label: 'Phong', value: booking.showtime.hall),
                _InfoLine(
                  label: 'Suat',
                  value: '${booking.showtime.date} - ${booking.showtime.time}',
                ),
                _InfoLine(label: 'Ghe', value: booking.seats.join(', ')),
                _InfoLine(
                  label: 'Tong',
                  value: _currency.format(booking.total),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
