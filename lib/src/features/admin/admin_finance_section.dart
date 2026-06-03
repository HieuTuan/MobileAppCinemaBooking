import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class AdminFinanceSection extends StatefulWidget {
  const AdminFinanceSection({super.key, required this.store});

  final CinemaStore store;

  @override
  State<AdminFinanceSection> createState() => _AdminFinanceSectionState();
}

class _AdminFinanceSectionState extends State<AdminFinanceSection> {
  BookingStatus? _status;
  DateTime? _date;

  @override
  Widget build(BuildContext context) {
    final bookings = _filteredBookings();
    final soldByMovie = widget.store.soldTicketsByMovie();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Doanh thu',
                value: money(widget.store.revenueTotal()),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Booking',
                value: '${widget.store.bookings.length}',
                icon: Icons.confirmation_number_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        SectionTitle(
          title: 'Booking và hoàn tiền',
          action: TextButton.icon(
            onPressed: () => setState(() {
              _status = null;
              _date = null;
            }),
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Bỏ lọc'),
          ),
        ),
        _BookingFilters(
          status: _status,
          date: _date,
          onStatusChanged: (value) => setState(() => _status = value),
          onToday: () => setState(() {
            final now = DateTime.now();
            _date = DateTime(now.year, now.month, now.day);
          }),
        ),
        const SizedBox(height: 10),
        if (bookings.isEmpty)
          const GlassCard(child: Text('Không có booking phù hợp.'))
        else
          ...bookings.map(
            (booking) => _BookingFinanceCard(
              booking: booking,
              store: widget.store,
              onRefund: () {
                widget.store.cancelBooking(booking.id);
                setState(() {});
                _snack('Đã xử lý hoàn tiền VNPay Refund API demo.');
              },
            ),
          ),
        const SectionTitle(title: 'Thống kê vé đã bán theo phim'),
        GlassCard(
          child: Column(
            children: [
              for (final entry in soldByMovie.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  subtitle: LinearProgressIndicator(
                    value: (entry.value / 20).clamp(0, 1),
                    color: AppColors.ink,
                  ),
                  trailing: Text('${entry.value} vé'),
                ),
            ],
          ),
        ),
        const SectionTitle(title: 'Báo cáo doanh thu'),
        GlassCard(
          child: Column(
            children: [
              _ReportRow(
                label: 'Theo ngày',
                value: money(widget.store.revenueTotal()),
              ),
              _ReportRow(
                label: 'Theo tuần',
                value: money(widget.store.revenueTotal()),
              ),
              _ReportRow(
                label: 'Theo tháng',
                value: money(widget.store.revenueTotal()),
              ),
              _ReportRow(
                label: 'Theo rạp',
                value: '${widget.store.cinemas.length} rạp',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _snack('Đã tạo file Excel .xlsx demo.'),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Excel .xlsx'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _snack('Đã tạo file PDF demo.'),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Booking> _filteredBookings() {
    return widget.store.bookings.where((booking) {
      final matchesStatus = _status == null || booking.status == _status;
      final matchesDate =
          _date == null ||
          (booking.createdAt.year == _date!.year &&
              booking.createdAt.month == _date!.month &&
              booking.createdAt.day == _date!.day);
      return matchesStatus && matchesDate;
    }).toList();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BookingFilters extends StatelessWidget {
  const _BookingFilters({
    required this.status,
    required this.date,
    required this.onStatusChanged,
    required this.onToday,
  });

  final BookingStatus? status;
  final DateTime? date;
  final ValueChanged<BookingStatus?> onStatusChanged;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            selected: status == null,
            label: const Text('Tất cả trạng thái'),
            onSelected: (_) => onStatusChanged(null),
          ),
          for (final item in BookingStatus.values)
            ChoiceChip(
              selected: status == item,
              label: Text(bookingStatusLabel(item)),
              onSelected: (_) => onStatusChanged(item),
            ),
          ActionChip(
            avatar: const Icon(Icons.today_rounded),
            label: Text(date == null ? 'Lọc hôm nay' : shortDate(date!)),
            onPressed: onToday,
          ),
        ],
      ),
    );
  }
}

class _BookingFinanceCard extends StatelessWidget {
  const _BookingFinanceCard({
    required this.booking,
    required this.store,
    required this.onRefund,
  });

  final Booking booking;
  final CinemaStore store;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    final payment = store.paymentForBooking(booking.id);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('${booking.id} • ${booking.customerName}'),
        subtitle: Text(
          '${booking.movieTitle} • ${bookingStatusLabel(booking.status)}'
          '${payment == null ? '' : ' • ${payment.method.toUpperCase()}'}',
        ),
        trailing: Wrap(
          spacing: 6,
          children: [
            Text(money(booking.totalAmount)),
            IconButton(
              tooltip: 'Refund VNPay',
              onPressed: booking.status == BookingStatus.active
                  ? onRefund
                  : null,
              icon: const Icon(Icons.undo_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
