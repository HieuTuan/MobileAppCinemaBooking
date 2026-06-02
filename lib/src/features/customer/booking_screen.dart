import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.store,
    required this.movie,
    required this.showtime,
  });

  final CinemaStore store;
  final Movie movie;
  final Showtime showtime;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final List<String> _selectedSeats = [];
  final Map<String, int> _comboQuantities = {};
  late final Timer _timer;
  int _remainingSeconds = 600;
  PaymentStatus _paymentStatus = PaymentStatus.success;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remainingSeconds = (_remainingSeconds - 1).clamp(0, 600));
      if (_remainingSeconds == 0) _selectedSeats.clear();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final room = store.roomById(widget.showtime.roomId);
    final cinema = store.cinemaForRoom(widget.showtime.roomId);
    final selectedCombos = _expandedComboIds();
    final total = store.calculateTotal(
      widget.showtime,
      _selectedSeats,
      selectedCombos,
    );

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text(
          'Chọn ghế & bắp nước',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _CountdownPill(seconds: _remainingSeconds)),
          ),
        ],
      ),
      bottomNavigationBar: _InvoiceBar(
        total: total,
        onConfirm: () => _confirm(total),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
        children: [
          _BookingSummary(
            movie: widget.movie,
            showtime: widget.showtime,
            room: room,
            cinema: cinema,
          ),
          const SizedBox(height: 14),
          _SeatSelector(
            store: store,
            showtime: widget.showtime,
            selectedSeats: _selectedSeats,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: _SectionHeading('Combo bắp & nước uống')),
              Text(
                'Đi kèm tiện lợi',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...store.combos.map(
            (combo) => _ComboTile(
              combo: combo,
              quantity: _comboQuantities[combo.id] ?? 0,
              onChanged: (value) {
                setState(() {
                  if (value <= 0) {
                    _comboQuantities.remove(combo.id);
                  } else {
                    _comboQuantities[combo.id] = value;
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 14),
          _PaymentCard(
            total: total,
            status: _paymentStatus,
            onChanged: (status) => setState(() => _paymentStatus = status),
          ),
        ],
      ),
    );
  }

  List<String> _expandedComboIds() {
    return [
      for (final entry in _comboQuantities.entries)
        for (var i = 0; i < entry.value; i++) entry.key,
    ];
  }

  void _confirm(int total) {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần chọn ít nhất 1 ghế.')),
      );
      return;
    }
    if (_paymentStatus != PaymentStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'VNPay đang ở trạng thái ${paymentStatusLabel(_paymentStatus)}.',
          ),
        ),
      );
      return;
    }

    final booking = widget.store.createBooking(
      showtime: widget.showtime,
      selectedSeats: _selectedSeats,
      selectedCombos: _expandedComboIds(),
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt vé thành công'),
        content: Text(
          'Mã vé ${booking.id} đã được tạo.\nTổng thanh toán: ${money(total)}\nVé QR đã nằm trong ví vé.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.movie,
    required this.showtime,
    required this.room,
    required this.cinema,
  });

  final Movie movie;
  final Showtime showtime;
  final Room room;
  final Cinema cinema;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              movie.posterUrl,
              width: 64,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 84,
                color: AppColors.goldSoft,
                child: const Icon(Icons.local_movies_rounded),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '${room.screenType} • ${room.name}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Suất chiếu: ${shortTime(showtime.startTime)} • ${shortDate(showtime.startTime)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  cinema.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatSelector extends StatelessWidget {
  const _SeatSelector({
    required this.store,
    required this.showtime,
    required this.selectedSeats,
    required this.onChanged,
  });

  final CinemaStore store;
  final Showtime showtime;
  final List<String> selectedSeats;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final booked = store.bookedSeats(showtime.id);
    final held = store.heldSeats(showtime.id);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: .1),
                  AppColors.gold.withValues(alpha: .75),
                  AppColors.gold.withValues(alpha: .1),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                'MÀN HÌNH CHIẾU • PHÒNG VIP',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: store.seats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final seat = store.seats[index];
              final selected = selectedSeats.contains(seat.code);
              final isBooked = booked.contains(seat.code);
              final isHeld = held.contains(seat.code);
              final disabled = isBooked || isHeld;
              final color = _seatColor(seat.type, selected, isBooked, isHeld);
              return Tooltip(
                message:
                    '${seat.code} - ${seatTypeLabel(seat.type)} - ${money(store.seatPrice(seat, showtime))}',
                child: InkWell(
                  onTap: disabled
                      ? null
                      : () {
                          if (selected) {
                            selectedSeats.remove(seat.code);
                          } else if (selectedSeats.length >= 8) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mỗi lần đặt tối đa 8 ghế.'),
                              ),
                            );
                          } else {
                            selectedSeats.add(seat.code);
                          }
                          onChanged();
                        },
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected ? AppColors.ink : Colors.white,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected ? softShadow(.12) : null,
                    ),
                    child: Text(
                      seat.code,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: disabled || selected
                            ? Colors.white
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.line),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 14,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _LegendDot(
                color: Color(0xFF2F80ED),
                label: 'Standard\n(60.000đ)',
              ),
              _LegendDot(color: Color(0xFFFFB000), label: 'VIP\n(90.000đ)'),
              _LegendDot(color: Color(0xFFE91E63), label: 'Couple\n(140.000đ)'),
              _LegendDot(color: Color(0xFF223046), label: 'Đã bán/giữ'),
            ],
          ),
        ],
      ),
    );
  }

  Color _seatColor(SeatType type, bool selected, bool booked, bool held) {
    if (selected) return AppColors.ink;
    if (booked || held) return const Color(0xFF223046);
    return switch (type) {
      SeatType.standard => const Color(0xFF2F80ED),
      SeatType.vip => const Color(0xFFFFB000),
      SeatType.couple => const Color(0xFFE91E63),
    };
  }
}

class _ComboTile extends StatelessWidget {
  const _ComboTile({
    required this.combo,
    required this.quantity,
    required this.onChanged,
  });

  final FoodCombo combo;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fastfood_rounded, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  combo.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  combo.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  money(combo.price),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _QuantityStepper(quantity: quantity, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: quantity == 0 ? null : () => onChanged(quantity - 1),
            icon: const Icon(Icons.remove_rounded),
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(quantity + 1),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.total,
    required this.status,
    required this.onChanged,
  });

  final int total;
  final PaymentStatus status;
  final ValueChanged<PaymentStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading('Thanh toán VNPay'),
          const SizedBox(height: 8),
          Text('Tổng tiền gửi sang VNPay sandbox: ${money(total)}'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                selected: status == PaymentStatus.success,
                label: const Text('Thành công'),
                onSelected: (_) => onChanged(PaymentStatus.success),
              ),
              ChoiceChip(
                selected: status == PaymentStatus.processing,
                label: const Text('Đang xử lý'),
                onSelected: (_) => onChanged(PaymentStatus.processing),
              ),
              ChoiceChip(
                selected: status == PaymentStatus.failed,
                label: const Text('Thất bại'),
                onSelected: (_) => onChanged(PaymentStatus.failed),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceBar extends StatelessWidget {
  const _InvoiceBar({required this.total, required this.onConfirm});

  final int total;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.line)),
          boxShadow: softShadow(.1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng hóa đơn'.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    money(total),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Xác nhận'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: AppColors.ink,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          '${(seconds ~/ 60).toString().padLeft(1, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}
