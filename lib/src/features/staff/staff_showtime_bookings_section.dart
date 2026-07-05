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
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PrepMetric(
                      label: 'Số ghế',
                      value: '$seatCount',
                      icon: Icons.airline_seat_recline_normal_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (bookings.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Chưa có đặt vé cho suất này.',
                      style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
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
  const _PrepMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingStatusBadge extends StatelessWidget {
  const _BookingStatusBadge({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case BookingStatus.active:
        bgColor = const Color(0xFFF59E0B).withOpacity(0.12);
        textColor = const Color(0xFFB45309);
        label = 'Chờ soát';
        break;
      case BookingStatus.used:
        bgColor = const Color(0xFF10B981).withOpacity(0.12);
        textColor = const Color(0xFF047857);
        label = 'Đã soát';
        break;
      case BookingStatus.cancelled:
        bgColor = const Color(0xFFEF4444).withOpacity(0.12);
        textColor = const Color(0xFFB91C1C);
        label = 'Đã hủy';
        break;
      case BookingStatus.refunded:
        bgColor = const Color(0xFF3B82F6).withOpacity(0.12);
        textColor = const Color(0xFF1D4ED8);
        label = 'Đã hoàn';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.pearl,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.confirmation_number_rounded,
              color: Color(0xFFF59E0B),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.airline_seat_recline_normal_rounded,
                      size: 13,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ghế: ${booking.seats.join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Mã: ${booking.id}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          _BookingStatusBadge(status: booking.status),
        ],
      ),
    );
  }
}
