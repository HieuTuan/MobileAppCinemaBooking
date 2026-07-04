import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../api/exceptions/api_exceptions.dart';
import '../../../models/booking_models.dart';
import '../../../repositories/booking_repository.dart';
import '../../../utils/connectivity_service.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../shared/widgets/cache_banner.dart';
import '../../state/cinema_store.dart';
import 'booking_confirmation_screen.dart';

class ApiTicketsScreen extends StatefulWidget {
  const ApiTicketsScreen({
    super.key,
    required this.store,
    this.refreshToken = 0,
  });

  final CinemaStore store;
  final int refreshToken;

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
  void didUpdateWidget(covariant ApiTicketsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _refresh(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _changesSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<BookingResult> _load({bool forceRefresh = false}) async {
    final userId = widget.store.currentUser!.id;
    final result = await _repo.getUserBookings(
      userId,
      status: _status == _statusAll ? null : _status,
      forceRefresh: forceRefresh,
    );
    return result;
  }

  void _refresh({bool forceRefresh = false}) {
    setState(() {
      _bookings = _load(forceRefresh: forceRefresh);
    });
  }

  Future<void> _pullRefresh() async {
    final future = _load(forceRefresh: true);
    setState(() {
      _bookings = future;
    });
    await future;
  }

  String _loadErrorMessage(Object? error) {
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiException) return inner.error.message;
      if (inner is ApiNetworkException) return inner.message;
      if (inner is ApiTimeoutException) return inner.message;
      return error.message ?? 'Không thể gọi API tải vé.';
    }
    if (error is ApiException) return error.error.message;
    if (error is ApiNetworkException) return error.message;
    if (error is ApiTimeoutException) return error.message;
    return error?.toString() ?? 'Không thể gọi API tải vé.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Trạng thái'),
            items: _statusOptions
                .map(
                  (opt) => DropdownMenuItem(
                    value: opt.value,
                    child: Text(opt.label),
                  ),
                )
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 52,
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không thể tải vé từ API',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _loadErrorMessage(snapshot.error),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tải lại lịch sử đặt vé'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final result = snapshot.requireData;
            final bookings = result.items;
            if (bookings.isEmpty && result.errorMessage != null) {
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 52,
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không thể tải vé từ API',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tải lại lịch sử đặt vé'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Expanded(
              child: Column(
                children: [
                  CacheBanner(
                    fromCache: result.fromCache,
                    cachedAt: result.cachedAt,
                  ),
                  Expanded(
                    child: bookings.isEmpty
                        ? const Center(child: Text('Bạn chưa có booking nào.'))
                        : RefreshIndicator(
                            onRefresh: _pullRefresh,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                100,
                              ),
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

// ─── Premium Booking Card ─────────────────────────────────────────────────────

class _BookingCard extends StatefulWidget {
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
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isActive = booking.status == 'active';
    final isPending = booking.status == 'pendingPayment';
    final isCancelled =
        booking.status == 'cancelled' || booking.status == 'refunded';
    final isUsed = booking.status == 'used';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status header bar ──────────────────────────────────────────────
          _BookingStatusBar(status: booking.status),

          // ── Content ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Movie title + cache chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        booking.movieTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (widget.fromCache) ...[
                      const SizedBox(width: 8),
                      const _CachedChip(),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Info grid
                _InfoRow(
                  icon: Icons.event_rounded,
                  label:
                      '${shortDate(booking.showtimeDateTime)}  ${shortTime(booking.showtimeDateTime)}',
                ),
                const SizedBox(height: 5),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  label: booking.cinemaName.isNotEmpty
                      ? '${booking.cinemaName} · ${booking.roomName}'
                      : booking.roomName,
                ),
                const SizedBox(height: 5),
                _InfoRow(
                  icon: Icons.chair_rounded,
                  label: 'Ghế: ${booking.seatCodes.join(', ')}',
                ),
                if (booking.combos.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _InfoRow(
                    icon: Icons.fastfood_rounded,
                    label: 'Combo: ${booking.combos.length} phần',
                  ),
                ],
                const SizedBox(height: 5),
                _InfoRow(
                  icon: Icons.payments_rounded,
                  label: money(booking.totalAmount),
                  bold: true,
                ),
                const SizedBox(height: 5),
                _InfoRow(
                  icon: Icons.tag_rounded,
                  label: booking.bookingId,
                  muted: true,
                  small: true,
                ),

                // ── Actions ────────────────────────────────────────────────
                if (isActive) ...[
                  const SizedBox(height: 14),
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
                          icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                          label: const Text('Xem vé QR'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: AppColors.line),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _cancelling
                              ? null
                              : () => _cancel(context),
                          icon: _cancelling
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cancel_outlined, size: 18),
                          label: Text(_cancelling ? 'Đang hủy...' : 'Hủy vé'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (isPending) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: .3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          size: 15,
                          color: AppColors.warning,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đơn đang chờ thanh toán. Vui lòng hoàn tất trong thời gian quy định.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isCancelled) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        booking.status == 'refunded'
                            ? 'Đã hoàn tiền'
                            : 'Vé đã bị hủy',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else if (isUsed) ...[
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Đã sử dụng vé',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final booking = widget.booking;
    final beforeTwoHours = booking.showtimeDateTime.isAfter(
      DateTime.now().add(const Duration(hours: 2)),
    );
    final estimatedRefund = beforeTwoHours
        ? booking.totalAmount
        : booking.totalAmount ~/ 2;
    final refundPercent = beforeTwoHours ? '100%' : '50%';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận hủy vé',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.movieTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pearl,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RefundRow(
                    label: 'Tiền vé gốc',
                    value: money(booking.totalAmount),
                  ),
                  const SizedBox(height: 4),
                  _RefundRow(
                    label: 'Chính sách hoàn',
                    value: beforeTwoHours
                        ? 'Trước 2h → hoàn $refundPercent'
                        : 'Trong 2h → hoàn $refundPercent',
                    isPolicy: true,
                  ),
                  const Divider(height: 14),
                  _RefundRow(
                    label: 'Hoàn lại ước tính',
                    value: money(estimatedRefund),
                    highlight: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ vé'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text('Xác nhận yêu cầu hủy'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    setState(() => _cancelling = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await APIClient().requestCancelBooking(
        booking.bookingId,
        userId: widget.userId,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Yêu cầu hủy vé đã được gửi · Hoàn ${money(result.refundAmount)}',
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      widget.onChanged();
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Không thể gửi yêu cầu hủy vé: ${_cancelErrorMessage(e)}',
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  String _cancelErrorMessage(Object error) {
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiException) return inner.error.message;
      if (inner is ApiNetworkException) return inner.message;
      if (inner is ApiTimeoutException) return inner.message;
      return error.message ?? 'Vui lòng thử lại.';
    }
    if (error is ApiException) return error.error.message;
    if (error is ApiNetworkException) return error.message;
    if (error is ApiTimeoutException) return error.message;
    return 'Vui lòng thử lại.';
  }
}

// ─── Status bar at top of card ────────────────────────────────────────────────

class _BookingStatusBar extends StatelessWidget {
  const _BookingStatusBar({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'active' => (
        'Đã xác nhận',
        AppColors.success,
        Icons.check_circle_rounded,
      ),
      'pendingPayment' => (
        'Chờ thanh toán',
        AppColors.warning,
        Icons.hourglass_top_rounded,
      ),
      'pendingRefund' => (
        'Đang chờ duyệt hoàn tiền',
        AppColors.warning,
        Icons.access_time_rounded,
      ),
      'used' => ('Đã sử dụng', AppColors.muted, Icons.done_all_rounded),
      'cancelled' => ('Đã hủy', AppColors.danger, Icons.cancel_rounded),
      'refunded' => (
        'Đã hoàn tiền',
        AppColors.danger,
        Icons.currency_exchange_rounded,
      ),
      _ => (status, AppColors.muted, Icons.info_outline_rounded),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      color: color.withValues(alpha: .09),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.bold = false,
    this.muted = false,
    this.small = false,
  });

  final IconData icon;
  final String label;
  final bool bold;
  final bool muted;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.muted : AppColors.ink;
    final size = small ? 11.0 : 13.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: muted ? AppColors.muted : AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: size,
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Refund Row in dialog ─────────────────────────────────────────────────────

class _RefundRow extends StatelessWidget {
  const _RefundRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.isPolicy = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool isPolicy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: highlight ? AppColors.ink : AppColors.muted,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: highlight
                ? AppColors.success
                : (isPolicy ? AppColors.warning : AppColors.ink),
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Cached Chip ──────────────────────────────────────────────────────────────

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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
