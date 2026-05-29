part of '../../app.dart';

class _VerifyCard extends StatelessWidget {
  const _VerifyCard({required this.booking, required this.onVerify});

  final Booking booking;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final active = booking.status == BookingStatus.active;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusColor(booking.status).withValues(alpha: .16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _statusColor(booking.status)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.id,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(
                color: _statusColor(booking.status),
                textColor: Colors.white,
                label: booking.status.name.toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(label: 'Khach', value: booking.customerName),
          _InfoLine(label: 'Phim', value: booking.movieTitle),
          _InfoLine(
            label: 'Suat',
            value: '${booking.showtime.branch} - ${booking.showtime.time}',
          ),
          _InfoLine(label: 'Ghe', value: booking.seats.join(', ')),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: active ? onVerify : null,
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('XAC NHAN - CHO VAO XEM PHIM'),
          ),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withValues(alpha: .08)),
      ),
      leading: CircleAvatar(
        backgroundColor: _statusColor(booking.status),
        foregroundColor: Colors.white,
        child: const Icon(Icons.confirmation_number_outlined),
      ),
      title: Text(
        '${booking.id} - ${booking.movieTitle}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${booking.customerName} - ${booking.seats.join(', ')} - ${_currency.format(booking.total)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
