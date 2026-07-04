// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/booking_models.dart';
import '../../../models/wallet_models.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';

/// Staff refund management section.
///
/// Requirements:
/// - R12: Tra cứu vé thủ công bằng bookingId hoặc customerName
/// - R13 (Staff): Xem chính sách hoàn tiền và xác nhận hủy/hoàn vé cho khách
/// - Mới: Duyệt yêu cầu hoàn tiền từ khách hàng
class StaffRefundSection extends StatefulWidget {
  const StaffRefundSection({super.key});

  @override
  State<StaffRefundSection> createState() => _StaffRefundSectionState();
}

class _StaffRefundSectionState extends State<StaffRefundSection> {
  final _api = APIClient();
  final _searchCtrl = TextEditingController();

  // Mode: true = ds yêu cầu, false = tra cứu thủ công
  bool _showRequests = true;

  // Requests state
  bool _loadingRequests = true;
  String? _requestsError;
  List<RefundRequest> _pendingRequests = [];

  // Search state
  bool _searching = false;
  String? _searchError;
  List<BookingDetails> _results = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _loadingRequests = true;
      _requestsError = null;
    });
    try {
      final reqs = await _api.staffGetRefundRequests();
      if (mounted) {
        reqs.sort(
          (a, b) => _refundActivityTime(b).compareTo(_refundActivityTime(a)),
        );
        setState(() {
          _pendingRequests = reqs;
          _loadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _requestsError = 'Lỗi tải danh sách: ${e.toString()}';
          _loadingRequests = false;
        });
      }
    }
  }

  DateTime _refundActivityTime(RefundRequest request) {
    return request.processedAt ?? request.requestedAt;
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _searchError = null;
      _results = [];
      _hasSearched = false;
    });

    try {
      final isBookingId =
          query.toUpperCase().startsWith('BK-') || query.length > 20;

      final bookings = await _api.searchBookings(
        bookingId: isBookingId ? query : null,
        customerName: isBookingId ? null : query,
      );

      if (!mounted) return;
      setState(() {
        _results = bookings;
        _hasSearched = true;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = 'Không thể tìm kiếm: ${e.toString()}';
        _searching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.currency_exchange_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xử lý hoàn tiền',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Duyệt yêu cầu và hủy vé cho khách',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Mode Toggle ───────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Yêu cầu chờ duyệt'),
                icon: Icon(Icons.list_alt_rounded),
              ),
              ButtonSegment(
                value: false,
                label: Text('Tra cứu thủ công'),
                icon: Icon(Icons.search_rounded),
              ),
            ],
            selected: {_showRequests},
            onSelectionChanged: (set) {
              setState(() => _showRequests = set.first);
              if (set.first) _fetchRequests();
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.ink;
                return Colors.white;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return AppColors.ink;
              }),
            ),
          ),
        ),

        if (_showRequests) ...[
          // ── Pending Requests List ───────────────────────────────────────────
          if (_loadingRequests)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_requestsError != null)
            _ErrorBanner(message: _requestsError!)
          else if (_pendingRequests.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Không có yêu cầu hoàn tiền nào đang chờ duyệt',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            ..._pendingRequests.map(
              (req) => _RefundRequestCard(
                request: req,
                api: _api,
                onProcessed: _fetchRequests,
              ),
            ),
        ] else ...[
          // ── Search Mode ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Mã vé (BK-...) hoặc tên khách',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.pearl,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _searching ? null : _search,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Tìm'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Policy info ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: .3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 12),
                      children: [
                        TextSpan(
                          text: 'Chính sách hoàn tiền: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning,
                          ),
                        ),
                        const TextSpan(
                          text:
                              'Trước 2h → hoàn 100% | Trong 2h trước suất chiếu → hoàn 50% | Sau khi chiếu → không hoàn.',
                          style: TextStyle(color: Color(0xFF795548)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Results ───────────────────────────────────────────────────────────
          if (_searchError != null)
            _ErrorBanner(message: _searchError!)
          else if (_hasSearched && _results.isEmpty)
            const _EmptyResult()
          else
            ..._results.map(
              (booking) => _RefundBookingCard(
                booking: booking,
                api: _api,
                onRefunded: () {
                  _search();
                },
              ),
            ),
        ],
      ],
    );
  }
}

// ─── Refund Request Card ──────────────────────────────────────────────────────

class _RefundRequestCard extends StatefulWidget {
  const _RefundRequestCard({
    required this.request,
    required this.api,
    required this.onProcessed,
  });

  final RefundRequest request;
  final APIClient api;
  final Future<void> Function() onProcessed;

  @override
  State<_RefundRequestCard> createState() => _RefundRequestCardState();
}

class _RefundRequestCardState extends State<_RefundRequestCard> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final isPending = req.status == 'PENDING';
    final statusColor = switch (req.status) {
      'APPROVED' => AppColors.success,
      'REJECTED' => AppColors.danger,
      _ => AppColors.warning,
    };
    final statusLabel = switch (req.status) {
      'APPROVED' => 'Đã hoàn tiền',
      'REJECTED' => 'Đã từ chối',
      'PENDING' => 'Đang chờ duyệt',
      _ => req.status,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: softShadow(.03),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã vé: ${req.bookingId.substring(0, 12)}...',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.muted,
                ),
              ),
              Text(
                shortDate(req.processedAt ?? req.requestedAt),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            req.movieTitle ?? 'Unknown Movie',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text('Khách: ${req.userId}', style: const TextStyle(fontSize: 13)),
          if (req.seatCodes != null)
            Text('Ghế: ${req.seatCodes}', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hoàn tiền dự kiến:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  money(req.refundAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.danger,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!isPending) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            if (req.reason != null && req.reason!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Lý do: ${req.reason}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _processing || !isPending
                      ? null
                      : () => _reject(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    side: BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _processing || !isPending
                      ? null
                      : () => _approve(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Duyệt & Hoàn tiền'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    setState(() => _processing = true);
    try {
      await widget.api
          .staffApproveRefund(widget.request.id)
          .timeout(const Duration(seconds: 15));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã duyệt yêu cầu hoàn tiền'),
          backgroundColor: AppColors.success,
        ),
      );
      await widget.onProcessed();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
    if (mounted) setState(() => _processing = false);
  }

  Future<void> _reject(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: 'Lý do từ chối (tùy chọn)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) {
      reasonCtrl.dispose();
      return;
    }

    setState(() => _processing = true);
    try {
      await widget.api
          .staffRejectRefund(widget.request.id, reasonCtrl.text.trim())
          .timeout(const Duration(seconds: 15));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã từ chối yêu cầu'),
          backgroundColor: AppColors.success,
        ),
      );
      await widget.onProcessed();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
    reasonCtrl.dispose();
    if (mounted) setState(() => _processing = false);
  }
}

// ─── Booking card for manual refund ───────────────────────────────────────────

class _RefundBookingCard extends StatefulWidget {
  const _RefundBookingCard({
    required this.booking,
    required this.api,
    required this.onRefunded,
  });

  final BookingDetails booking;
  final APIClient api;
  final VoidCallback onRefunded;

  @override
  State<_RefundBookingCard> createState() => _RefundBookingCardState();
}

class _RefundBookingCardState extends State<_RefundBookingCard> {
  bool _processing = false;

  bool get _canCancel => widget.booking.status == 'active';

  bool get _isAfterShowtime =>
      widget.booking.showtimeDateTime.isBefore(DateTime.now());

  bool get _isWithinTwoHours =>
      !_isAfterShowtime &&
      widget.booking.showtimeDateTime.isBefore(
        DateTime.now().add(const Duration(hours: 2)),
      );

  int get _estimatedRefund {
    if (_isAfterShowtime) return 0;
    if (_isWithinTwoHours) return widget.booking.totalAmount ~/ 2;
    return widget.booking.totalAmount;
  }

  String get _refundPercent {
    if (_isAfterShowtime) return '0%';
    if (_isWithinTwoHours) return '50%';
    return '100%';
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final statusColor = switch (booking.status) {
      'active' => AppColors.success,
      'cancelled' || 'refunded' => AppColors.danger,
      'used' => AppColors.muted,
      _ => AppColors.muted,
    };
    final statusLabel = switch (booking.status) {
      'active' => 'Đã xác nhận',
      'cancelled' => 'Đã hủy',
      'refunded' => 'Đã hoàn tiền',
      'used' => 'Đã sử dụng',
      _ => booking.status,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: softShadow(.03),
      ),
      child: Column(
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  booking.bookingId,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.movieTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _Row(
                  icon: Icons.event_rounded,
                  text:
                      '${shortDate(booking.showtimeDateTime)} ${shortTime(booking.showtimeDateTime)}',
                ),
                const SizedBox(height: 4),
                _Row(
                  icon: Icons.location_on_rounded,
                  text: booking.cinemaName.isNotEmpty
                      ? '${booking.cinemaName} · ${booking.roomName}'
                      : booking.roomName,
                ),
                const SizedBox(height: 4),
                _Row(
                  icon: Icons.chair_rounded,
                  text: 'Ghế: ${booking.seatCodes.join(', ')}',
                ),
                const SizedBox(height: 4),
                _Row(
                  icon: Icons.payments_rounded,
                  text: money(booking.totalAmount),
                  bold: true,
                ),

                if (_canCancel) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.pearl,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dự tính hoàn tiền',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isAfterShowtime
                                  ? 'Sau giờ chiếu → không hoàn'
                                  : _isWithinTwoHours
                                  ? 'Trong 2h trước chiếu → $_refundPercent'
                                  : 'Trước 2h → hoàn $_refundPercent',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              money(_estimatedRefund),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isAfterShowtime)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.block_rounded,
                            size: 14,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Không thể hủy sau giờ chiếu bắt đầu.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _processing
                            ? null
                            : () => _confirmRefund(context),
                        icon: _processing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.currency_exchange_rounded,
                                size: 18,
                              ),
                        label: Text(
                          _processing ? 'Đang xử lý...' : 'Hủy vé & Hoàn tiền',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ] else ...[
                  const SizedBox(height: 10),
                  Text(
                    booking.status == 'used'
                        ? 'Vé này đã được sử dụng, không thể hủy.'
                        : 'Vé đã bị hủy hoặc đã hoàn tiền.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRefund(BuildContext context) async {
    final booking = widget.booking;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'Xác nhận hủy vé',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.movieTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Khách: ${booking.movieTitle}',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pearl,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _DialogRow(
                    label: 'Tổng tiền',
                    value: money(booking.totalAmount),
                  ),
                  const Divider(height: 12),
                  _DialogRow(
                    label: 'Hoàn lại',
                    value: money(_estimatedRefund),
                    valueColor: AppColors.success,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hành động này không thể hoàn tác.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy bỏ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text('Xác nhận hủy & Hoàn tiền'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    setState(() => _processing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await widget.api.cancelBooking(
        booking.bookingId,
        userId: booking.userId,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đã hủy vé ${booking.bookingId.substring(0, 12)}... · Hoàn ${money(result.refundAmount)}',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      widget.onRefunded();
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      if (mounted) setState(() => _processing = false);
    }
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text, this.bold = false});
  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogRow extends StatelessWidget {
  const _DialogRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor ?? AppColors.ink,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 42, color: AppColors.muted),
          const SizedBox(height: 10),
          const Text(
            'Không tìm thấy vé phù hợp',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Thử tìm bằng mã vé (BK-...) hoặc tên khách hàng',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
