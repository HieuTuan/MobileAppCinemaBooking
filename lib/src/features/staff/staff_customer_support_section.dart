import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class StaffCustomerSupportSection extends StatefulWidget {
  const StaffCustomerSupportSection({super.key, required this.store});

  final CinemaStore store;

  @override
  State<StaffCustomerSupportSection> createState() =>
      _StaffCustomerSupportSectionState();
}

class _StaffCustomerSupportSectionState
    extends State<StaffCustomerSupportSection> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Hỗ trợ khách hàng tại quầy'),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Tìm theo tên, số điện thoại hoặc mã vé',
            prefixIcon: Icon(Icons.support_agent_rounded),
          ),
        ),
        const SizedBox(height: 10),
        if (results.isEmpty)
          const GlassCard(child: Text('Không tìm thấy đặt vé phù hợp.'))
        else
          ...results.map(
            (booking) => _BookingSupportCard(
              booking: booking,
              user: _userFor(booking),
              onCancel: () {
                widget.store.cancelBooking(booking.id);
                setState(() {});
                _showMessage('Đã hủy/hoàn vé ${booking.id}.');
              },
              onPrint: () => _showMessage('Đã tạo lệnh in vé giấy.'),
              onEmail: () => _showMessage('Đã gửi lại vé qua email demo.'),
            ),
          ),
      ],
    );
  }

  List<Booking> _results() {
    final query = _search.text.trim().toLowerCase();
    return widget.store.bookings.where((booking) {
      final user = _userFor(booking);
      return query.isEmpty ||
          booking.id.toLowerCase().contains(query) ||
          booking.customerName.toLowerCase().contains(query) ||
          user?.phone.toLowerCase().contains(query) == true;
    }).toList();
  }

  AppUser? _userFor(Booking booking) {
    return widget.store.users
        .where((user) => user.id == booking.userId)
        .firstOrNull;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BookingSupportCard extends StatelessWidget {
  const _BookingSupportCard({
    required this.booking,
    required this.user,
    required this.onCancel,
    required this.onPrint,
    required this.onEmail,
  });

  final Booking booking;
  final AppUser? user;
  final VoidCallback onCancel;
  final VoidCallback onPrint;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    final canCancel = booking.status == BookingStatus.active;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${booking.id} • ${booking.customerName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            booking.movieTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Ghế ${booking.seats.join(', ')} • ${money(booking.totalAmount)}',
          ),
          if (user != null) ...[
            const SizedBox(height: 4),
            Text(
              '${user!.phone} • ${user!.email}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: canCancel ? onCancel : null,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Đổi/Hủy'),
              ),
              OutlinedButton.icon(
                onPressed: onEmail,
                icon: const Icon(Icons.mail_outline_rounded),
                label: const Text('Gửi email'),
              ),
              OutlinedButton.icon(
                onPressed: onPrint,
                icon: const Icon(Icons.print_outlined),
                label: const Text('In vé'),
              ),
            ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          bookingStatusLabel(status),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
