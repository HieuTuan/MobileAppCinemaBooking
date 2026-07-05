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
import 'write_review_sheet.dart';

// ── Cinema colour tokens ──────────────────────────────────────────────────────
const _kDark = Color(0xFF0F172A);
const _kGold = Color(0xFFC9A44C);
const _kRed = Color(0xFFE53935);
const _kGreen = Color(0xFF1B8A5A);
const _kAmber = Color(0xFFF59E0B);
const _kPurple = Color(0xFF7C3AED);

// ── Status helpers ────────────────────────────────────────────────────────────
({Color color, IconData icon, String label}) _statusMeta(String status) =>
    switch (status) {
      'active' => (
        color: _kGreen,
        icon: Icons.check_circle_rounded,
        label: 'Đã xác nhận',
      ),
      'pendingPayment' => (
        color: _kAmber,
        icon: Icons.hourglass_top_rounded,
        label: 'Chờ thanh toán',
      ),
      'pendingRefund' => (
        color: _kAmber,
        icon: Icons.access_time_rounded,
        label: 'Chờ duyệt hoàn',
      ),
      'used' => (
        color: AppColors.muted,
        icon: Icons.done_all_rounded,
        label: 'Đã sử dụng',
      ),
      'cancelled' => (
        color: _kRed,
        icon: Icons.cancel_rounded,
        label: 'Đã hủy',
      ),
      'refunded' => (
        color: _kPurple,
        icon: Icons.currency_exchange_rounded,
        label: 'Đã hoàn tiền',
      ),
      _ => (
        color: AppColors.muted,
        icon: Icons.info_outline_rounded,
        label: status,
      ),
    };

// ═════════════════════════════════════════════════════════════════════════════
// ApiTicketsScreen
// ═════════════════════════════════════════════════════════════════════════════

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

class _ApiTicketsScreenState extends State<ApiTicketsScreen>
    with SingleTickerProviderStateMixin {
  static const _kAll = 'all';
  static const List<_StatusOption> _statusOptions = [
    _StatusOption(value: _kAll, label: 'Tất cả', icon: Icons.all_inbox_rounded),
    _StatusOption(
      value: 'active',
      label: 'Đang chiếu',
      icon: Icons.local_movies_rounded,
    ),
    _StatusOption(value: 'used', label: 'Đã xem', icon: Icons.done_all_rounded),
    _StatusOption(
      value: 'cancelled',
      label: 'Đã hủy',
      icon: Icons.cancel_rounded,
    ),
    _StatusOption(
      value: 'pendingPayment',
      label: 'Chờ thanh toán',
      icon: Icons.hourglass_top_rounded,
    ),
  ];

  final BookingRepository _repo = BookingRepository();
  final ConnectivityService _connectivity = ConnectivityService();

  String _status = _kAll;
  late Future<BookingResult> _bookings;
  BookingResult? _lastGoodResult;
  String? _lastGoodStatus;
  Timer? _errorRevealTimer;
  Timer? _transientRetryTimer;
  int _transientRetryCount = 0;
  bool _showErrorState = false;

  StreamSubscription? _changesSub;
  StreamSubscription? _connectivitySub;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _bookings = _load();
    _trackResult(_bookings);
    _tabCtrl = TabController(length: _statusOptions.length, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) return;
      final sel = _statusOptions[_tabCtrl.index].value;
      if (sel == _status) return;
      setState(() => _status = sel);
      _refresh();
    });

    _repo.startAutoSync();
    _changesSub = _repo.changes.listen((_) {
      if (!mounted) return;
      _refresh();
    });
    _connectivitySub = _connectivity.connectivityStream.listen((_) {
      if (!mounted) return;
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
    _errorRevealTimer?.cancel();
    _transientRetryTimer?.cancel();
    _tabCtrl.dispose();
    _changesSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<BookingResult> _load({bool forceRefresh = false}) async {
    final userId = widget.store.currentUser!.id;
    return _repo.getUserBookings(
      userId,
      status: _status == _kAll ? null : _status,
      forceRefresh: forceRefresh,
    );
  }

  void _refresh({bool forceRefresh = false}) {
    final next = _load(forceRefresh: forceRefresh);
    _errorRevealTimer?.cancel();
    _transientRetryTimer?.cancel();
    setState(() {
      _showErrorState = false;
      _transientRetryCount = 0;
      _bookings = next;
    });
    _trackResult(next);
  }

  Future<void> _pullRefresh() async {
    final f = _load(forceRefresh: true);
    _errorRevealTimer?.cancel();
    _transientRetryTimer?.cancel();
    setState(() {
      _showErrorState = false;
      _transientRetryCount = 0;
      _bookings = f;
    });
    _trackResult(f);
    await f;
  }

  void _trackResult(Future<BookingResult> future) {
    future.then((result) {
      if (!mounted || !identical(future, _bookings)) return;
      if (result.items.isNotEmpty || result.errorMessage == null) {
        _errorRevealTimer?.cancel();
        _transientRetryTimer?.cancel();
        _transientRetryCount = 0;
        _lastGoodResult = result;
        _lastGoodStatus = _status;
      }
    }, onError: (_) {});
  }

  void _scheduleErrorReveal() {
    if (_showErrorState || _errorRevealTimer?.isActive == true) return;
    _errorRevealTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _showErrorState = true);
    });
  }

  void _scheduleTransientRetry() {
    if (_transientRetryTimer?.isActive == true) return;
    if (_transientRetryCount >= 3) {
      _scheduleErrorReveal();
      return;
    }
    _transientRetryTimer = Timer(
      Duration(milliseconds: 650 + (_transientRetryCount * 450)),
      () {
        if (!mounted) return;
        _transientRetryCount++;
        final next = _load(forceRefresh: true);
        setState(() {
          _showErrorState = false;
          _bookings = next;
        });
        _trackResult(next);
      },
    );
  }

  String _errorMsg(Object? error) {
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

  // ── build ──────────────────────────────────────────────────────────────────

  Widget _loadingState() {
    final previous = _lastGoodStatus == _status ? _lastGoodResult : null;
    if (previous != null) {
      return _ticketsResult(previous);
    }
    return const Expanded(
      child: Center(child: CircularProgressIndicator(color: _kGold)),
    );
  }

  Widget _ticketsResult(BookingResult result) {
    final bookings = result.items;
    return Expanded(
      child: Column(
        children: [
          CacheBanner(fromCache: result.fromCache, cachedAt: result.cachedAt),
          Expanded(
            child: bookings.isEmpty
                ? _EmptyState(status: _status)
                : RefreshIndicator(
                    color: _kGold,
                    onRefresh: _pullRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: bookings.length,
                      itemBuilder: (_, i) => _TicketCard(
                        store: widget.store,
                        booking: bookings[i],
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
  }

  Widget _deferredErrorState(String message) {
    final previous = _lastGoodStatus == _status ? _lastGoodResult : null;
    if (previous != null) {
      return _ticketsResult(previous);
    }
    if (!_showErrorState) {
      _scheduleTransientRetry();
      return previous == null ? _loadingState() : _ticketsResult(previous);
    }
    return Expanded(
      child: _ErrorState(message: message, onRetry: _refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Dark header with tab bar ─────────────────────────────────────
        _TicketsHeader(tabCtrl: _tabCtrl, options: _statusOptions),

        // ── Content ──────────────────────────────────────────────────────
        FutureBuilder<BookingResult>(
          future: _bookings,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _loadingState();
            }

            if (snapshot.hasError) {
              return _deferredErrorState(_errorMsg(snapshot.error));
            }

            final result = snapshot.requireData;
            final bookings = result.items;

            if (bookings.isEmpty && result.errorMessage != null) {
              return _deferredErrorState(result.errorMessage!);
            }

            return _ticketsResult(result);
          },
        ),
      ],
    );
  }
}

class _StatusOption {
  const _StatusOption({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;
}

// ═════════════════════════════════════════════════════════════════════════════
// DARK HEADER + TAB BAR
// ═════════════════════════════════════════════════════════════════════════════

class _TicketsHeader extends StatelessWidget {
  const _TicketsHeader({required this.tabCtrl, required this.options});

  final TabController tabCtrl;
  final List<_StatusOption> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: [
                Icon(
                  Icons.confirmation_number_rounded,
                  color: _kGold,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Vé của tôi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Tab bar
          TabBar(
            controller: tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: _kGold,
            indicatorWeight: 2.5,
            labelColor: _kGold,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: options
                .map(
                  (o) => Tab(
                    height: 40,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(o.icon, size: 14),
                        const SizedBox(width: 6),
                        Text(o.label),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TICKET CARD  (cinema-ticket shape)
// ═════════════════════════════════════════════════════════════════════════════

class _TicketCard extends StatefulWidget {
  const _TicketCard({
    required this.store,
    required this.booking,
    required this.userId,
    required this.fromCache,
    required this.onChanged,
  });

  final CinemaStore store;
  final BookingDetails booking;
  final String userId;
  final bool fromCache;
  final VoidCallback onChanged;

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  final _api = APIClient();
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final meta = _statusMeta(b.status);
    final isActive = b.status == 'active';
    final isPending = b.status == 'pendingPayment';
    final isCancelled = b.status == 'cancelled' || b.status == 'refunded';
    final isUsed = b.status == 'used';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipPath(
        clipper: _TicketClipper(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: softShadow(.06),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Dark cinema header ───────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kDark, Color(0xFF1A2744)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status pill
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: meta.color.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: meta.color.withValues(alpha: .55),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(meta.icon, size: 12, color: meta.color),
                              const SizedBox(width: 5),
                              Text(
                                meta.label,
                                style: TextStyle(
                                  color: meta.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (widget.fromCache) const _CachedChip(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Movie title
                    Text(
                      b.movieTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Date + time
                    Row(
                      children: [
                        const Icon(
                          Icons.event_rounded,
                          size: 13,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${shortDate(b.showtimeDateTime)}  ${shortTime(b.showtimeDateTime)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Ticket tear-line ─────────────────────────────────────
              _TearLine(),

              // ── Body info ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Two-column grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DataCell(
                                icon: Icons.location_on_rounded,
                                label: 'Rạp chiếu',
                                value: b.cinemaName.isNotEmpty
                                    ? b.cinemaName
                                    : b.roomName,
                              ),
                              const SizedBox(height: 10),
                              _DataCell(
                                icon: Icons.meeting_room_rounded,
                                label: 'Phòng',
                                value: b.roomName,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 70,
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                          color: AppColors.line,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DataCell(
                                icon: Icons.chair_rounded,
                                label: 'Ghế',
                                value: b.seatCodes.join(', '),
                              ),
                              const SizedBox(height: 10),
                              _DataCell(
                                icon: Icons.payments_rounded,
                                label: 'Tổng tiền',
                                value: money(b.totalAmount),
                                valueColor: _kDark,
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (b.combos.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _DataCell(
                        icon: Icons.fastfood_rounded,
                        label: 'Combo',
                        value: '${b.combos.length} phần bắp nước',
                      ),
                    ],

                    const SizedBox(height: 10),
                    // Booking ID
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pearl,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tag_rounded,
                            size: 13,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              b.bookingId,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Action buttons ────────────────────────────────
                    if (isActive) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // QR button
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.qr_code_2_rounded,
                              label: 'Xem QR',
                              dark: true,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BookingConfirmationScreen(
                                    bookingId: b.bookingId,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Cancel button
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.cancel_outlined,
                              label: _cancelling ? 'Đang hủy...' : 'Hủy vé',
                              danger: true,
                              loading: _cancelling,
                              onTap: _cancelling
                                  ? null
                                  : () => _cancel(context),
                            ),
                          ),
                        ],
                      ),
                    ] else if (isPending) ...[
                      const SizedBox(height: 12),
                      const _InfoBanner(
                        icon: Icons.hourglass_top_rounded,
                        message:
                            'Đơn đang chờ thanh toán. Hoàn tất trong thời gian quy định.',
                        color: _kAmber,
                      ),
                    ] else if (isCancelled) ...[
                      const SizedBox(height: 10),
                      _InfoBanner(
                        icon: b.status == 'refunded'
                            ? Icons.currency_exchange_rounded
                            : Icons.cancel_rounded,
                        message: b.status == 'refunded'
                            ? 'Đã hoàn tiền thành công'
                            : 'Vé đã bị hủy',
                        color: b.status == 'refunded' ? _kPurple : _kRed,
                      ),
                    ] else if (isUsed) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _reviewMovie(context),
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: const Text('Đánh giá phim'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String? _movieIdForBooking() {
    final direct = widget.booking.movieId;
    if (direct != null && direct.isNotEmpty) return direct;
    for (final s in widget.store.showtimes) {
      if (s.id == widget.booking.showtimeId) return s.movieId;
    }
    return null;
  }

  Future<void> _reviewMovie(BuildContext context) async {
    final movieId = _movieIdForBooking();
    if (movieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa xác định được phim của vé này.')),
      );
      return;
    }
    final submitted = await showWriteReviewSheet(
      context: context,
      api: _api,
      userId: widget.userId,
      movieId: movieId,
      movieTitle: widget.booking.movieTitle,
    );
    if (!context.mounted || submitted != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã gửi đánh giá phim.')));
  }

  Future<void> _cancel(BuildContext context) async {
    final b = widget.booking;
    final beforeTwoHours = b.showtimeDateTime.isAfter(
      DateTime.now().add(const Duration(hours: 2)),
    );
    final estimatedRefund = beforeTwoHours ? b.totalAmount : b.totalAmount ~/ 2;
    final refundPercent = beforeTwoHours ? '100%' : '50%';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        title: const Text(
          'Xác nhận hủy vé',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              b.movieTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.pearl,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RefundRow(label: 'Tiền vé gốc', value: money(b.totalAmount)),
                  const SizedBox(height: 6),
                  _RefundRow(
                    label: 'Chính sách hoàn',
                    value: beforeTwoHours
                        ? 'Trước 2h → $refundPercent'
                        : 'Trong 2h → $refundPercent',
                    isPolicy: true,
                  ),
                  const Divider(height: 16),
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
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ vé'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _kRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    setState(() => _cancelling = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await APIClient().requestCancelBooking(
        b.bookingId,
        userId: widget.userId,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('Đã hủy · Hoàn ${money(result.refundAmount)}'),
            ],
          ),
          backgroundColor: _kGreen,
        ),
      );
      widget.onChanged();
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể hủy vé: ${_cancelMsg(e)}'),
          backgroundColor: _kRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  String _cancelMsg(Object error) {
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

// ═════════════════════════════════════════════════════════════════════════════
// TICKET TEAR LINE (răng cưa)
// ═════════════════════════════════════════════════════════════════════════════

class _TearLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          // Left notch
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: AppColors.ivory,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
          ),
          // Dashed line
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dashCount = (constraints.maxWidth / 10).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    dashCount,
                    (_) => const SizedBox(
                      width: 6,
                      height: 1.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: AppColors.line),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Right notch
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: AppColors.ivory,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TICKET CLIPPER
// ═════════════════════════════════════════════════════════════════════════════

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = 16.0; // corner radius
    const nr = 8.0; // notch radius
    // The notch sits at ~40% height (after dark header section)
    final ny = size.height * 0.40;

    final path = Path();
    // Top-left corner
    path.moveTo(r, 0);
    path.lineTo(size.width - r, 0);
    path.arcToPoint(Offset(size.width, r), radius: const Radius.circular(r));
    // Right side down to notch
    path.lineTo(size.width, ny - nr);
    // Right notch (inward)
    path.arcToPoint(
      Offset(size.width, ny + nr),
      radius: const Radius.circular(nr),
      clockwise: false,
    );
    // Continue right side
    path.lineTo(size.width, size.height - r);
    path.arcToPoint(
      Offset(size.width - r, size.height),
      radius: const Radius.circular(r),
    );
    path.lineTo(r, size.height);
    path.arcToPoint(
      Offset(0, size.height - r),
      radius: const Radius.circular(r),
    );
    // Left side up to notch
    path.lineTo(0, ny + nr);
    // Left notch (inward)
    path.arcToPoint(
      Offset(0, ny - nr),
      radius: const Radius.circular(nr),
      clockwise: false,
    );
    path.lineTo(0, r);
    path.arcToPoint(const Offset(r, 0), radius: const Radius.circular(r));
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_TicketClipper old) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _DataCell extends StatelessWidget {
  const _DataCell({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.muted),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: valueColor ?? AppColors.ink,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    this.dark = false,
    this.danger = false,
    this.loading = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool dark;
  final bool danger;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = danger ? _kRed : (dark ? _kDark : AppColors.pearl);
    final fg = (danger || dark) ? Colors.white : AppColors.ink;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CachedChip extends StatelessWidget {
  const _CachedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kAmber.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kAmber.withValues(alpha: .45)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cached_rounded, size: 12, color: _kAmber),
          SizedBox(width: 4),
          Text(
            'Cached',
            style: TextStyle(
              color: _kAmber,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY & ERROR STATES
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kDark.withValues(alpha: .06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 48,
                color: AppColors.muted.withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              status == 'all'
                  ? 'Bạn chưa có vé nào'
                  : 'Không có vé trong mục này',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đặt vé để tận hưởng trải nghiệm điện ảnh!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: _kRed,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Không thể tải vé từ API',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REFUND ROW (trong dialog xác nhận hủy)
// ═════════════════════════════════════════════════════════════════════════════

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
            color: highlight ? _kGreen : (isPolicy ? _kAmber : AppColors.ink),
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
