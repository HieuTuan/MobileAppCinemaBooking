import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key, required this.store});

  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    final user = store.currentUser!;
    final tickets = store.bookingsForUser(user.id);
    if (tickets.isEmpty) {
      return const Center(
        child: GlassCard(
          child: Text('Bạn chưa có vé nào. Hãy chọn phim và đặt vé.'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final booking = tickets[index];
        return _TicketCard(store: store, booking: booking);
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.store, required this.booking});

  final CinemaStore store;
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final payment = store.paymentForBooking(booking.id);
    final showtime = store.showtimes.firstWhere(
      (item) => item.id == booking.showtimeId,
    );
    final room = store.roomById(showtime.roomId);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.movieTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${shortDate(showtime.startTime)} ${shortTime(showtime.startTime)} - ${room.name}',
          ),
          Text('Ghế: ${booking.seats.join(', ')}'),
          Text('Tổng tiền: ${money(booking.totalAmount)}'),
          if (payment != null)
            Text(
              'VNPay: ${paymentStatusLabel(payment.status)} - ${payment.vnpayTransactionId} - response ${payment.vnpayResponseCode}',
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showQr(context),
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Mã QR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showInvoice(context),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Hóa đơn'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (booking.status == BookingStatus.active)
            FilledButton.tonalIcon(
              onPressed: () => _confirmCancel(context),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Hủy vé / hoàn tiền'),
            ),
        ],
      ),
    );
  }

  void _showQr(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR vé ${booking.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: booking.qrCode,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            SelectableText(booking.qrCode),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showInvoice(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hóa đơn điện tử'),
        content: Text(
          'Mã booking: ${booking.id}\nTổng tiền: ${money(booking.totalAmount)}\n'
          'Trạng thái: ${bookingStatusLabel(booking.status)}\nTải hóa đơn PDF/Excel: mô phỏng FE.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy vé'),
        content: const Text(
          'Chính sách demo: hoàn 100% nếu trước 2 giờ, 50% trong 2 giờ, không hoàn sau giờ chiếu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bỏ qua'),
          ),
          FilledButton(
            onPressed: () {
              store.cancelBooking(booking.id);
              Navigator.pop(context);
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.active => AppColors.success,
      BookingStatus.used => AppColors.muted,
      BookingStatus.cancelled || BookingStatus.refunded => AppColors.danger,
    };
    final label = bookingStatusLabel(status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
