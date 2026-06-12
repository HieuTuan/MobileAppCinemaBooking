import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/booking_models.dart' as api_models;
import '../../../services/payment_service.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../state/cinema_store.dart';
import 'booking_confirmation_screen.dart';

enum _PaymentMethod { vnpay, bank }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.store,
    required this.movie,
    required this.showtime,
    required this.selectedSeats,
    required this.total,
    required this.hold,
    required this.comboSelections,
  });

  final CinemaStore store;
  final Movie movie;
  final Showtime showtime;
  final List<String> selectedSeats;
  final int total;
  final api_models.HoldResponse hold;
  final List<api_models.ComboSelection> comboSelections;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final APIClient _apiClient = APIClient();
  final PaymentService _paymentService = PaymentService();
  _PaymentMethod _method = _PaymentMethod.vnpay;
  String _bank = 'VCB';
  bool _processing = false;
  Timer? _holdTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _holdTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final remaining = widget.hold.expiresAt.difference(DateTime.now());
    if (mounted) {
      setState(
        () => _remaining = remaining.isNegative ? Duration.zero : remaining,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.store.roomById(widget.showtime.roomId);
    final cinema = widget.store.cinemaForRoom(widget.showtime.roomId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Thanh toán • ${_formatDuration(_remaining)}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      bottomNavigationBar: _PaymentBottomBar(
        total: widget.total,
        processing: _processing,
        onPay: _remaining == Duration.zero ? null : _payWithVnpay,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          _OrderSummary(
            movie: widget.movie,
            showtime: widget.showtime,
            room: room,
            cinemaName: _cinemaName(cinema),
            seats: widget.selectedSeats,
            total: widget.total,
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Phương thức thanh toán'),
          const SizedBox(height: 10),
          _MethodTile(
            icon: Icons.qr_code_2_rounded,
            title: 'VNPay giả lập',
            subtitle: 'Tạo giao dịch sandbox và trả kết quả thành công.',
            selected: _method == _PaymentMethod.vnpay,
            onTap: () => setState(() => _method = _PaymentMethod.vnpay),
          ),
          const SizedBox(height: 10),
          _MethodTile(
            icon: Icons.account_balance_rounded,
            title: 'Ngân hàng nội địa',
            subtitle: 'Chọn ngân hàng demo để mô phỏng thanh toán.',
            selected: _method == _PaymentMethod.bank,
            onTap: () => setState(() => _method = _PaymentMethod.bank),
          ),
          if (_method == _PaymentMethod.bank) ...[
            const SizedBox(height: 12),
            _BankSelector(selectedBank: _bank, onChanged: _selectBank),
          ],
          const SizedBox(height: 18),
          _SandboxNotice(method: _method, bank: _bank),
        ],
      ),
    );
  }

  void _selectBank(String bank) {
    setState(() {
      _method = _PaymentMethod.bank;
      _bank = bank;
    });
  }

  Future<void> _payWithVnpay() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final booking = await _apiClient.createBooking(
        api_models.CreateBookingRequest(
          holdId: widget.hold.holdId,
          combos: widget.comboSelections,
          userId: widget.store.currentUser?.id,
        ),
      );
      if (!mounted) return;
      final result = await _paymentService.processPayment(
        context,
        booking.bookingId,
        booking.paymentUrl,
      );
      if (!mounted) return;
      setState(() => _processing = false);
      if (result.isSuccess) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                BookingConfirmationScreen(bookingId: booking.bookingId),
          ),
        );
        return;
      }
      await _showPaymentFailure(result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xử lý thanh toán. Vui lòng thử lại.'),
        ),
      );
    }
  }

  Future<void> _showPaymentFailure(PaymentResult result) {
    final isTimeout = result.status == api_models.ApiPaymentStatus.timeout;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTimeout ? 'Thanh toán hết hạn' : 'Thanh toán thất bại'),
        content: Text(
          isTimeout
              ? 'Phiên thanh toán đã hết hạn. Ghế sẽ được tự động giải phóng.'
              : 'Giao dịch chưa thành công. Bạn có thể thử lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          if (!isTimeout)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Đặt lại'),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _cinemaName(Cinema cinema) {
    return cinema.name.contains('Ã') || cinema.name.contains('á')
        ? 'CineLuxe Tràng Tiền'
        : cinema.name;
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.movie,
    required this.showtime,
    required this.room,
    required this.cinemaName,
    required this.seats,
    required this.total,
  });

  final Movie movie;
  final Showtime showtime;
  final Room room;
  final String cinemaName;
  final List<String> seats;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  movie.posterUrl,
                  width: 62,
                  height: 86,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 62,
                    height: 86,
                    color: AppColors.pearl,
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$cinemaName • ${room.screenType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${shortTime(showtime.startTime)} • ${shortDate(showtime.startTime)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Ghế', value: seats.join(', ')),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Tạm tính', value: money(total)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.black, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: selected ? Colors.white70 : AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

class _BankSelector extends StatelessWidget {
  const _BankSelector({required this.selectedBank, required this.onChanged});

  final String selectedBank;
  final ValueChanged<String> onChanged;

  static const banks = ['VCB', 'BIDV', 'TCB', 'MB', 'ACB', 'VPBank'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final bank in banks)
          ChoiceChip(
            selected: bank == selectedBank,
            label: Text(bank),
            onSelected: (_) => onChanged(bank),
            selectedColor: Colors.black,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.black),
            labelStyle: TextStyle(
              color: bank == selectedBank ? Colors.white : Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}

class _SandboxNotice extends StatelessWidget {
  const _SandboxNotice({required this.method, required this.bank});

  final _PaymentMethod method;
  final String bank;

  @override
  Widget build(BuildContext context) {
    final methodName = method == _PaymentMethod.vnpay
        ? 'VNPay sandbox'
        : 'ngân hàng $bank';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đây là thanh toán giả lập bằng $methodName. App sẽ tạo giao dịch thành công để bạn kiểm thử luồng đặt vé.',
              style: const TextStyle(height: 1.4, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBottomBar extends StatelessWidget {
  const _PaymentBottomBar({
    required this.total,
    required this.processing,
    required this.onPay,
  });

  final int total;
  final bool processing;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.line)),
          boxShadow: softShadow(.08),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    money(total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: processing ? null : onPay,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Thanh toán',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
