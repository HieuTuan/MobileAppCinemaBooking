import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/booking_models.dart';
import '../../../repositories/booking_repository.dart';
import '../../../utils/connectivity_service.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../shared/widgets/cache_banner.dart';
import '../../state/cinema_store.dart';
import 'booking_confirmation_screen.dart';

class ApiTicketsScreen extends StatefulWidget {
  const ApiTicketsScreen({super.key, required this.store});

  final CinemaStore store;

  @override
  State<ApiTicketsScreen> createState() => _ApiTicketsScreenState();
}

class _ApiTicketsScreenState extends State<ApiTicketsScreen> {
  static const _statusAll = 'all';
  static const List<_StatusOption> _statusOptions = [
    _StatusOption(value: _statusAll, label: 'Tất cả'),
    _StatusOption(value: 'active', label: 'Đang hoạt động'),
    _StatusOption(value: 'cancelled', label: 'Đã hủy'),
  ];

  final BookingRepository _repo = BookingRepository();
  final ConnectivityService _connectivity = ConnectivityService();

  String _status = _statusAll;
  late Future<BookingResult> _bookings = _load();

  StreamSubscription? _changesSub;
  StreamSubscription? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _repo.startAutoSync();
    _changesSub = _repo.changes.listen((_) {
      if (!mounted) return;
      _refresh();
    });
    _connectivitySub = _connectivity.connectivityStream.listen((_) {
      if (!mounted) return;
      // Banners listen to connectivity live; no-op for the data fetch.
      setState(() {});
    });
  }

  @override
  void dispose() {
    _changesSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<BookingResult> _load() async {
    final userId = widget.store.currentUser!.id;
    final result = await _repo.getUserBookings(
      userId,
      status: _status == _statusAll ? null : _status,
    );
    return result;
  }

  void _refresh() {
    setState(() {
      _bookings = _load();
    });
  }

  Future<void> _pullRefresh() async {
    final userId = widget.store.currentUser!.id;
    final result = await _repo.getUserBookings(
      userId,
      status: _status == _statusAll ? null : _status,
      forceRefresh: true,
    );
    if (!mounted) return;
    setState(() {
      _bookings = Future.value(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Trạng thái'),
              items: _statusOptions
                  .map((opt) => DropdownMenuItem(
                        value: opt.value,
                        child: Text(opt.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _status = value);
                _refresh();
              },
            ),
        ),
        FutureBuilder<BookingResult>(
          future: _bookings,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Expanded(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Expanded(
                child: Center(
                  child: FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại lịch sử đặt vé'),
                  ),
                ),
              );
            }
            final result = snapshot.requireData;
            final bookings = result.items;
            return Expanded(
              child: Column(
                children: [
                  CacheBanner(
                    fromCache: result.fromCache,
                    cachedAt: result.cachedAt,
                  ),
                  Expanded(
                    child: bookings.isEmpty
                        ? const Center(
                            child: Text('Bạn chưa có booking nào.'),
                          )
                        : RefreshIndicator(
                            onRefresh: _pullRefresh,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              itemCount: bookings.length,
                              itemBuilder: (_, index) => _BookingCard(
                                booking: bookings[index],
                                userId: widget.store.currentUser!.id,
                                fromCache: result.fromCache,
                                onChanged: _refresh,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatusOption {
  const _StatusOption({required this.value, required this.label});
  final String value;
  final String label;
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.userId,
    required this.fromCache,
    required this.onChanged,
  });

  final BookingDetails booking;
  final String userId;
  final bool fromCache;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.movieTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (fromCache) const _CachedChip(),
              ],
            ),
            Text(
              '${shortDate(booking.showtimeDateTime)} ${shortTime(booking.showtimeDateTime)}',
            ),
            Text('${booking.cinemaName} - ${booking.roomName}'),
            Text('Ghế: ${booking.seatCodes.join(', ')}'),
            Text('Tổng tiền: ${money(booking.totalAmount)}'),
            Text('Trạng thái: ${booking.status} / ${booking.paymentStatus}'),
            const SizedBox(height: 10),
            if (booking.status == 'active')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookingConfirmationScreen(
                            bookingId: booking.bookingId,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Xem QR'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _cancel(context),
                      child: const Text('Hủy vé'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final beforeTwoHours = booking.showtimeDateTime.isAfter(
      DateTime.now().add(const Duration(hours: 2)),
    );
    final estimatedRefund =
        beforeTwoHours ? booking.totalAmount : booking.totalAmount ~/ 2;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy vé'),
        content: Text('Số tiền dự kiến hoàn: ${money(estimatedRefund)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ vé'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await APIClient().cancelBooking(
      booking.bookingId,
      userId: userId,
    );
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đã hủy vé, hoàn ${money(result.refundAmount)}'),
      ),
    );
    onChanged();
  }
}

class _CachedChip extends StatelessWidget {
  const _CachedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warning.withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.cached_rounded, size: 12, color: AppColors.warning),
          SizedBox(width: 4),
          Text(
            'Cached',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
