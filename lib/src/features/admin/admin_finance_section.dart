import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../models/admin_models.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';
import '../../../api/api_client.dart';

class AdminFinanceSection extends StatefulWidget {
  const AdminFinanceSection({super.key, required this.store});

  final CinemaStore store;

  @override
  State<AdminFinanceSection> createState() => _AdminFinanceSectionState();
}

class _AdminFinanceSectionState extends State<AdminFinanceSection> {
  BookingStatus? _status;
  DateTime? _date;

  // Dashboard metrics state
  DashboardMetrics? _metrics;
  bool _loadingMetrics = false;
  DateTime? _lastRefreshed;
  Timer? _refreshTimer;

  // Revenue report state — Requirements 24.1, 24.2, 24.3, 24.4
  RevenueReport? _revenueReport;
  bool _loadingReport = false;
  String? _reportError;
  late DateTime _reportStart;
  late DateTime _reportEnd;

  // Booking report state — Requirements 24.5, 24.6, 24.7, 24.8, 24.9
  BookingReport? _bookingReport;
  bool _loadingBookingReport = false;
  String? _bookingReportError;
  late DateTime _bookingReportStart;
  late DateTime _bookingReportEnd;

  final _api = APIClient();

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
    // Auto-refresh every 60 seconds — Requirement 25.6, 25.7
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchMetrics();
    });
    // Default report range: last 30 days
    final now = DateTime.now();
    _reportEnd = DateTime(now.year, now.month, now.day);
    _reportStart = _reportEnd.subtract(const Duration(days: 30));
    // Default booking report range: last 30 days
    _bookingReportEnd = DateTime(now.year, now.month, now.day);
    _bookingReportStart = _bookingReportEnd.subtract(const Duration(days: 30));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMetrics() async {
    if (!mounted) return;
    setState(() => _loadingMetrics = true);
    try {
      final metrics = await _api.getDashboardMetrics();
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _lastRefreshed = DateTime.now();
          _loadingMetrics = false;
        });
      }
    } catch (_) {
      // Fall back to local store data on error
      if (mounted) {
        setState(() => _loadingMetrics = false);
      }
    }
  }

  Future<void> _fetchRevenueReport() async {
    if (!mounted) return;
    setState(() {
      _loadingReport = true;
      _reportError = null;
    });
    try {
      final report = await _api.getRevenueReport(_reportStart, _reportEnd);
      if (mounted) {
        setState(() {
          _revenueReport = report;
          _loadingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reportError = e.toString();
          _loadingReport = false;
        });
      }
    }
  }

  Future<void> _fetchBookingReport() async {
    if (!mounted) return;
    setState(() {
      _loadingBookingReport = true;
      _bookingReportError = null;
    });
    try {
      final report =
          await _api.getBookingReport(_bookingReportStart, _bookingReportEnd);
      if (mounted) {
        setState(() {
          _bookingReport = report;
          _loadingBookingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookingReportError = e.toString();
          _loadingBookingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _filteredBookings();
    final soldByMovie = widget.store.soldTicketsByMovie();

    // Use API data if available, otherwise fall back to local store
    final todayRevenue = _metrics?.todayRevenue ?? widget.store.revenueTotal();
    final todayBookings =
        _metrics?.todayBookings ?? widget.store.bookings.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Last-updated timestamp — Requirement 25.7
        if (_lastRefreshed != null || _loadingMetrics)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_loadingMetrics)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                else
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 13,
                    color: AppColors.success,
                  ),
                const SizedBox(width: 4),
                Text(
                  _loadingMetrics
                      ? 'Đang cập nhật...'
                      : 'Cập nhật lần cuối: ${shortTime(_lastRefreshed!)}:${_lastRefreshed!.second.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

        // Metric cards row
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Doanh thu hôm nay',
                value: money(todayRevenue),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Booking hôm nay',
                value: '$todayBookings',
                icon: Icons.confirmation_number_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),

        // Extra metrics from API (active users, concurrent users)
        if (_metrics != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Người dùng hoạt động',
                  value: '${_metrics!.activeUsers}',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  label: 'Trực tuyến',
                  value: '${_metrics!.concurrentUsers}',
                  icon: Icons.wifi_rounded,
                  color: AppColors.platinum.withValues(alpha: 1),
                ),
              ),
            ],
          ),
        ],

        // Top 5 movies section — Requirement 25.4
        if (_metrics != null && _metrics!.topMovies.isNotEmpty) ...[
          const SectionTitle(title: 'Top 5 phim'),
          GlassCard(
            child: Column(
              children: [
                for (int i = 0; i < _metrics!.topMovies.length; i++)
                  _TopMovieRow(rank: i + 1, movie: _metrics!.topMovies[i]),
              ],
            ),
          ),
        ],

        // Recent activity section — Requirement 25.5
        if (_metrics != null && _metrics!.recentBookings.isNotEmpty) ...[
          const SectionTitle(title: 'Hoạt động gần đây'),
          GlassCard(
            child: Column(
              children: [
                for (final rb in _metrics!.recentBookings)
                  _RecentBookingRow(booking: rb),
              ],
            ),
          ),
        ],

        // ── Báo cáo doanh thu nâng cao — Requirements 24.1–24.4 ──────────────
        const SectionTitle(title: 'Báo cáo doanh thu nâng cao'),

        // Date range picker row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActionChip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text('Từ: ${shortDate(_reportStart)}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _reportStart,
                    firstDate: DateTime(2020),
                    lastDate: _reportEnd,
                  );
                  if (picked != null) setState(() => _reportStart = picked);
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.calendar_month_outlined, size: 16),
                label: Text('Đến: ${shortDate(_reportEnd)}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _reportEnd,
                    firstDate: _reportStart,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _reportEnd = picked);
                },
              ),
              FilledButton(
                onPressed: _fetchRevenueReport,
                child: const Text('Xem báo cáo'),
              ),
            ],
          ),
        ),

        // Loading / error / result
        if (_loadingReport)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_reportError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _reportError!,
                  style: const TextStyle(color: AppColors.danger),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _fetchRevenueReport,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          )
        else if (_revenueReport != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReportRow(
                  label: 'Tổng doanh thu',
                  value: money(_revenueReport!.totalRevenue),
                ),
                _ReportRow(
                  label: 'Tổng booking',
                  value: '${_revenueReport!.totalBookings}',
                ),
                _ReportRow(
                  label: 'Giá trị TB',
                  value: money(_revenueReport!.averageBookingValue),
                ),
                const Divider(height: 20),
                Text(
                  'Theo phương thức thanh toán',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final pm in _revenueReport!.byPaymentMethod)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      pm.method.isEmpty
                          ? pm.method
                          : pm.method[0].toUpperCase() +
                                pm.method.substring(1),
                    ),
                    subtitle: Text('${pm.count} giao dịch'),
                    trailing: Text(
                      money(pm.amount),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                const Divider(height: 20),
                Row(
                  children: [
                    Text(
                      'Doanh thu theo ngày',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${shortDate(_revenueReport!.startDate)} – ${shortDate(_revenueReport!.endDate)})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final day
                            in _revenueReport!.dailySeries.take(10))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(shortDate(day.date)),
                            subtitle: Text('${day.bookings} bookings'),
                            trailing: Text(
                              money(day.revenue),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Báo cáo booking — Requirements 24.5–24.9 ──────────────────────
        const SectionTitle(title: 'Báo cáo booking'),

        // Date range picker row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActionChip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text('Từ: ${shortDate(_bookingReportStart)}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _bookingReportStart,
                    firstDate: DateTime(2020),
                    lastDate: _bookingReportEnd,
                  );
                  if (picked != null) {
                    setState(() => _bookingReportStart = picked);
                  }
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.calendar_month_outlined, size: 16),
                label: Text('Đến: ${shortDate(_bookingReportEnd)}'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _bookingReportEnd,
                    firstDate: _bookingReportStart,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _bookingReportEnd = picked);
                  }
                },
              ),
              FilledButton(
                onPressed: _fetchBookingReport,
                child: const Text('Xem báo cáo'),
              ),
            ],
          ),
        ),

        // Loading / error / result
        if (_loadingBookingReport)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_bookingReportError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bookingReportError!,
                  style: const TextStyle(color: AppColors.danger),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _fetchBookingReport,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          )
        else if (_bookingReport != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 4-part stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Tổng',
                        value: '${_bookingReport!.stats.total}',
                        color: AppColors.ink,
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        label: 'Sắp chiếu',
                        value: '${_bookingReport!.stats.confirmed}',
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        label: 'Đã hủy',
                        value: '${_bookingReport!.stats.cancelled}',
                        color: AppColors.danger,
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        label: 'Hoàn tiền',
                        value: '${_bookingReport!.stats.refunded}',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'Xếp hạng phim',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final ranking in _bookingReport!.movieRankings)
                  _TopMovieRow(
                    rank: ranking.rank,
                    movie: MovieSales(
                      movieId: ranking.movieId,
                      title: ranking.title,
                      ticketsSold: ranking.ticketsSold,
                      revenue: ranking.revenue,
                    ),
                  ),
                const Divider(height: 20),
                Text(
                  'Tỷ lệ lấp đầy theo rạp',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final occ in _bookingReport!.theaterOccupancy)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                occ.theaterName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(occ.occupancyRate * 100).toStringAsFixed(1)}%'
                              '  (${occ.bookedSeats}/${occ.totalSeats})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: occ.occupancyRate.clamp(0.0, 1.0),
                          color: AppColors.gold,
                          backgroundColor: AppColors.line,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // Booking filter + list
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

// ---------------------------------------------------------------------------
// Top movie row widget
// ---------------------------------------------------------------------------

class _TopMovieRow extends StatelessWidget {
  const _TopMovieRow({required this.rank, required this.movie});

  final int rank;
  final MovieSales movie;

  @override
  Widget build(BuildContext context) {
    final rankColors = [
      AppColors.gold,
      AppColors.muted,
      const Color(0xFFCD7F32), // bronze
    ];
    final color = rank <= 3 ? rankColors[rank - 1] : AppColors.muted;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: color.withValues(alpha: .15),
        child: Text(
          '$rank',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        movie.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${movie.ticketsSold} vé'),
      trailing: Text(
        money(movie.revenue),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent booking row widget
// ---------------------------------------------------------------------------

class _RecentBookingRow extends StatelessWidget {
  const _RecentBookingRow({required this.booking});

  final RecentBooking booking;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status.toLowerCase()) {
      'active' || 'confirmed' => AppColors.success,
      'cancelled' || 'refunded' => AppColors.danger,
      _ => AppColors.muted,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${booking.customerName} • ${booking.movieTitle}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(fullDateTime(booking.createdAt)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            money(booking.totalAmount),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              booking.status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Existing private widgets (unchanged)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Small stat tile used inside booking report summary row
// ---------------------------------------------------------------------------

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
