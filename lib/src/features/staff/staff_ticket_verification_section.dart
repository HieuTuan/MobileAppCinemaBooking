import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class StaffTicketVerificationSection extends StatefulWidget {
  const StaffTicketVerificationSection({super.key, required this.store});

  final CinemaStore store;

  @override
  State<StaffTicketVerificationSection> createState() =>
      _StaffTicketVerificationSectionState();
}

class _StaffTicketVerificationSectionState
    extends State<StaffTicketVerificationSection> {
  final _code = TextEditingController(text: 'BK-DEMO01');
  String? _showtimeId;
  String _result = 'Sẵn sàng quét QR hoặc tra cứu thủ công bằng mã vé.';

  @override
  void initState() {
    super.initState();
    if (widget.store.showtimes.isNotEmpty) {
      _showtimeId = widget.store.showtimes.first.id;
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showtimes = widget.store.showtimes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Xác thực vé tại cổng'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _showtimeId,
                decoration: const InputDecoration(
                  labelText: 'Suất chiếu đang soát',
                  prefixIcon: Icon(Icons.event_seat_rounded),
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
              TextField(
                controller: _code,
                decoration: const InputDecoration(
                  labelText: 'Mã vé hoặc QR data',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _verify,
                      icon: const Icon(Icons.verified_rounded),
                      label: const Text('Xác thực'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _simulateQr,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Quét QR'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ResultBanner(message: _result),
            ],
          ),
        ),
      ],
    );
  }

  void _simulateQr() {
    final active = widget.store.bookings
        .where((item) => item.status == BookingStatus.active)
        .firstOrNull;
    if (active == null) {
      setState(() => _result = 'Không có vé active để quét thử.');
      return;
    }
    _code.text = active.qrCode;
    _verify();
  }

  void _verify() {
    setState(() {
      _result = widget.store.validateTicket(
        _code.text,
        expectedShowtimeId: _showtimeId,
      );
    });
  }

  String _showtimeLabel(Showtime showtime) {
    final movie = widget.store.movieById(showtime.movieId);
    return '${movie.title} • ${shortDate(showtime.startTime)} ${shortTime(showtime.startTime)}';
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final valid = message.startsWith('Hợp lệ');
    final warning = message.startsWith('Sai suất') || message.contains('đã');
    final color = valid
        ? AppColors.success
        : warning
        ? AppColors.warning
        : AppColors.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}
