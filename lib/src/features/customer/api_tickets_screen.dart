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
  DateTime? _startDate;
  DateTime? _endDate;
  int _currentPage = 1;
  static const int _pageSize = 10;

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
      startDate: _startDate != null ? _startDate!.toIso8601String() : null,
      endDate: _endDate != null ? _endDate!.toIso8601String() : null,
      page: _currentPage,
      pageSize: _pageSize,
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
      startDate: _startDate != null ? _startDate!.toIso8601String() : null,
      endDate: _endDate != null ? _endDate!.toIso8601String() : null,
      page: _currentPage,
      pageSize: _pageSize,
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
                setState(() {
                  _status = value;
                  _currentPage = 1;
                });
                _refresh();
              },
            ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                        _currentPage = 1;
                      });
                      _refresh();
                    }
                  },
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(_startDate == null ? 'Từ ngày' : shortDate(_startDate!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
                        _currentPage = 1;
                      });
                      _refresh();
                    }
                  },
                  icon: const Icon(Icons.date_range_rounded),
                  label: Text(_endDate == null ? 'Đến ngày' : shortDate(_endDate!)),
                ),
              ),
              if (_startDate != null || _endDate != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _currentPage = 1;
                    });
                    _refresh();
                  },
                  icon: const Icon(Icons.clear_rounded),
                ),
            ],
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
                                  const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: bookings.length,
                              itemBuilder: (_, index) => _BookingCard(
                                booking: bookings[index],
                                store: widget.store,
                                fromCache: result.fromCache,
                                onChanged: _refresh,
                              ),
                            ),
                          ),
                  ),
                  if (!result.fromCache && result.totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: result.hasPrevious
                                ? () {
                                    setState(() {
                                      _currentPage--;
                                    });
                                    _refresh();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          Text(
                            'Trang ${result.page} / ${result.totalPages}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: result.hasNext
                                ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                    _refresh();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
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
    required this.store,
    required this.fromCache,
    required this.onChanged,
  });

  final BookingDetails booking;
  final CinemaStore store;
  final bool fromCache;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (booking.posterUrl != null && booking.posterUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  booking.posterUrl!,
                  width: 70,
                  height: 105,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 105,
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.movie_rounded, color: Colors.white54),
                  ),
                ),
              )
            else
              Container(
                width: 70,
                height: 105,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.movie_rounded, color: Colors.white54),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.movieTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (fromCache) const _CachedChip(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${shortDate(booking.showtimeDateTime)} ${shortTime(booking.showtimeDateTime)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '${booking.cinemaName} - ${booking.roomName}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Ghế: ${booking.seatCodes.join(', ')}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Tổng tiền: ${money(booking.totalAmount)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Trạng thái: ${booking.status} / ${booking.paymentStatus}',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
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
                            icon: const Icon(Icons.qr_code, size: 16),
                            label: const Text('Xem QR', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () => _cancel(context),
                            child: const Text('Hủy vé', style: TextStyle(fontSize: 12)),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
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
    final userId = store.currentUser!.id;
    final result = await APIClient().cancelBooking(
      booking.bookingId,
      userId: userId,
    );
    try {
      final updatedProfile = await APIClient().getProfile(userId);
      store.setCurrentUserFromProfile(updatedProfile);
    } catch (_) {}
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
