import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../models/booking_models.dart';
import '../../../repositories/booking_repository.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final BookingRepository _repo = BookingRepository();

  /// Cached QR bytes loaded as a fallback when the network call fails.
  Uint8List? _cachedBytes;
  late Future<BookingQr?> _ticket;

  Future<BookingQr?> _loadWithFallback() async {
    final ticket = await _repo.getBookingQr(widget.bookingId);
    if (ticket == null) {
      _cachedBytes = await _repo.getCachedQRCode(widget.bookingId);
    }
    return ticket;
  }

  @override
  void initState() {
    super.initState();
    _ticket = _loadWithFallback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vé của bạn')),
      body: FutureBuilder<BookingQr?>(
        future: _ticket,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final ticket = snapshot.data;
          if (ticket != null) {
            return _TicketContent(ticket: ticket);
          }
          // Network failed — show cached QR (if any).
          if (_cachedBytes != null) {
            return _CachedTicketContent(
              bookingId: widget.bookingId,
              imageBytes: _cachedBytes!,
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Không thể tải vé QR: ${snapshot.error ?? "mất kết nối"}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TicketContent extends StatelessWidget {
  const _TicketContent({required this.ticket});

  final BookingQr ticket;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.2, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.elasticOut,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 72),
        ),
        const SizedBox(height: 12),
        Text(
          'Thanh toán thành công',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _FullScreenQr(ticket: ticket)),
            ),
            child: Hero(
              tag: ticket.bookingId,
              child: ticket.qrCodeUrl != null && ticket.qrCodeUrl!.isNotEmpty
                  ? Image.network(
                      ticket.qrCodeUrl!,
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return QrImageView(
                          data: ticket.qrCode,
                          size: 300,
                          backgroundColor: Colors.white,
                        );
                      },
                    )
                  : QrImageView(
                      data: ticket.qrCode,
                      size: 300,
                      backgroundColor: Colors.white,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          ticket.movieTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(
          '${shortDate(ticket.showtimeDateTime)} ${shortTime(ticket.showtimeDateTime)}',
        ),
        Text('${ticket.cinemaName} - ${ticket.roomName}'),
        Text('Ghế: ${ticket.seatCodes.join(', ')}'),
        Text('Mã booking: ${ticket.bookingId}'),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Hoàn tất'),
        ),
      ],
    );
  }
}

class _CachedTicketContent extends StatelessWidget {
  const _CachedTicketContent({
    required this.bookingId,
    required this.imageBytes,
  });

  final String bookingId;
  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _OfflineBadge(),
        const SizedBox(height: 16),
        Center(
          child: Image.memory(
            imageBytes,
            width: 300,
            height: 300,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Mã booking: $bookingId',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Hoàn tất'),
        ),
      ],
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.warning.withValues(alpha: .45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.warning),
            SizedBox(width: 6),
            Text(
              'Offline — hiển thị QR đã lưu cục bộ',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenQr extends StatelessWidget {
  const _FullScreenQr({required this.ticket});

  final BookingQr ticket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ticket.movieTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: ticket.bookingId,
                child: ticket.qrCodeUrl != null && ticket.qrCodeUrl!.isNotEmpty
                    ? Image.network(
                        ticket.qrCodeUrl!,
                        width: 340,
                        height: 340,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return QrImageView(
                            data: ticket.qrCode,
                            size: 340,
                            backgroundColor: Colors.white,
                          );
                        },
                      )
                    : QrImageView(
                        data: ticket.qrCode,
                        size: 340,
                        backgroundColor: Colors.white,
                      ),
              ),
              const SizedBox(height: 20),
              Text('${ticket.cinemaName} - ${ticket.roomName}'),
              Text('Ghế: ${ticket.seatCodes.join(', ')}'),
            ],
          ),
        ),
      ),
    );
  }
}
