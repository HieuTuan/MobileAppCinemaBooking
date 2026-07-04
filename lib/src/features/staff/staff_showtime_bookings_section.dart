import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class StaffShowtimeBookingsSection extends StatefulWidget {
  const StaffShowtimeBookingsSection({
    super.key,
    required this.store,
    this.showTitle = true,
  });

  final CinemaStore store;
  final bool showTitle;

  @override
  State<StaffShowtimeBookingsSection> createState() =>
      _StaffShowtimeBookingsSectionState();
}

class _StaffShowtimeBookingsSectionState
    extends State<StaffShowtimeBookingsSection> {
  String? _showtimeId;

  @override
  void initState() {
    super.initState();
    if (widget.store.showtimes.isNotEmpty) {
      _showtimeId = widget.store.showtimes.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showtimes = widget.store.showtimes;
    final selected = showtimes
        .where((showtime) => showtime.id == _showtimeId)
        .firstOrNull;
    final bookings = selected == null
        ? <Booking>[]
        : widget.store.bookings
              .where((booking) => booking.showtimeId == selected.id)
              .toList();
    final seatCount = bookings.fold<int>(
      0,
      (sum, booking) => sum + booking.seats.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          const SectionTitle(title: 'Danh sách đặt vé theo suất'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _showtimeId,
                decoration: const InputDecoration(
                  labelText: 'Chọn suất chiếu cần chuẩn bị',
                  prefixIcon: Icon(Icons.event_available_rounded),
                ),
                items: [
                  for (final showtime in showtimes)
                    DropdownMenuItem(
                      value: showtime.id,
                      child: Text(_showtimeLabel(showtime)),
                    ),
                ],
                onChanged: (value) => setState(() => _showtimeId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PrepMetric(
                      label: 'Booking',
                      value: '${bookings.length}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PrepMetric(label: 'Ghế', value: '$seatCount'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (bookings.isEmpty)
                const Text('Chưa có đặt vé cho suất này.')
              else
                ...bookings.map((booking) => _BookingLine(booking: booking)),
            ],
          ),
        ),
      ],
    );
  }

  String _showtimeLabel(Showtime showtime) {
    final movie = widget.store.movieById(showtime.movieId);
    final room = widget.store.roomById(showtime.roomId);
    return '${movie.title} • ${shortDate(showtime.startTime)} ${shortTime(showtime.startTime)} • ${room.name}';
  }
}

class _PrepMetric extends StatelessWidget {
  const _PrepMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _BookingLine extends StatelessWidget {
  const _BookingLine({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.id} • ${booking.customerName}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ghế ${booking.seats.join(', ')} • ${bookingStatusLabel(booking.status)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
