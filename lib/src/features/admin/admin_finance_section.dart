import 'dart:async';
import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../../models/admin_models.dart';
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
    // Auto-refresh every 60 seconds — Requirement 25.6, 25.7
    // Default report range: last 30 days
    final now = DateTime.now();
    _reportEnd = DateTime(now.year, now.month, now.day);
    _reportStart = _reportEnd.subtract(const Duration(days: 30));
    // Default booking report range: last 30 days
    _bookingReportEnd = DateTime(now.year, now.month, now.day);
    _bookingReportStart = _bookingReportEnd.subtract(const Duration(days: 30));
    unawaited(_refreshFinanceDashboard());
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchMetrics();
    });
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

  Future<void> _refreshFinanceDashboard() async {
    await Future.wait([
      _fetchMetrics(),
      _fetchRevenueReport(),
      _fetchBookingReport(),
    ]);
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
      final report = await _api.getBookingReport(
        _bookingReportStart,
        _bookingReportEnd,
      );
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

    return _buildFinanceDashboard(
      context,
      bookings: bookings,
      soldByMovie: soldByMovie,
      todayRevenue: todayRevenue,
      todayBookings: todayBookings,
    );
    // ignore: dead_code
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                for (final pm in _revenueReport!.byPaymentMethod)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      pm.method.isEmpty
                          ? pm.method
                          : pm.method[0].toUpperCase() + pm.method.substring(1),
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final day in _revenueReport!.dailySeries.take(10))
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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

  Widget _buildFinanceDashboard(
    BuildContext context, {
    required List<Booking> bookings,
    required Map<String, int> soldByMovie,
    required int todayRevenue,
    required int todayBookings,
  }) {
    final reportRevenue = _revenueReport?.totalRevenue ?? todayRevenue;
    final reportBookings = _revenueReport?.totalBookings ?? todayBookings;
    final averageValue =
        _revenueReport?.averageBookingValue ??
        (reportBookings > 0 ? reportRevenue ~/ reportBookings : 0);
    final totalBookings =
        _bookingReport?.stats.total ?? widget.store.bookings.length;
    final activeBookings =
        _bookingReport?.stats.confirmed ??
        widget.store.bookings
            .where((item) => item.status == BookingStatus.active)
            .length;
    final refundedBookings =
        _bookingReport?.stats.refunded ??
        widget.store.bookings
            .where((item) => item.status == BookingStatus.refunded)
            .length;

    return RefreshIndicator(
      onRefresh: _refreshFinanceDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _FinanceHero(
            revenue: reportRevenue,
            bookings: reportBookings,
            lastRefreshed: _lastRefreshed,
            isLoading:
                _loadingMetrics || _loadingReport || _loadingBookingReport,
            onRefresh: _refreshFinanceDashboard,
          ),
          const SizedBox(height: 12),
          _DashboardGrid(
            children: [
              _FinanceKpiCard(
                label: 'Doanh thu kỳ này',
                value: money(reportRevenue),
                icon: Icons.payments_rounded,
                tone: AppColors.ink,
              ),
              _FinanceKpiCard(
                label: 'Booking kỳ này',
                value: '$reportBookings',
                icon: Icons.confirmation_number_rounded,
                tone: AppColors.success,
              ),
              _FinanceKpiCard(
                label: 'Giá trị TB',
                value: money(averageValue),
                icon: Icons.trending_up_rounded,
                tone: AppColors.warning,
              ),
              _FinanceKpiCard(
                label: 'Hôm nay',
                value: money(todayRevenue),
                footer: '$todayBookings booking',
                icon: Icons.today_rounded,
                tone: AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DashboardGrid(
            children: [
              _FinanceKpiCard(
                label: 'Tổng booking',
                value: '$totalBookings',
                icon: Icons.receipt_long_rounded,
                tone: AppColors.ink,
              ),
              _FinanceKpiCard(
                label: 'Chờ soát',
                value: '$activeBookings',
                icon: Icons.pending_actions_rounded,
                tone: AppColors.warning,
              ),
              _FinanceKpiCard(
                label: 'Hoàn tiền',
                value: '$refundedBookings',
                icon: Icons.currency_exchange_rounded,
                tone: AppColors.danger,
              ),
              _FinanceKpiCard(
                label: 'Người dùng online',
                value: '${_metrics?.concurrentUsers ?? 0}',
                footer: '${_metrics?.activeUsers ?? 0} active',
                icon: Icons.wifi_rounded,
                tone: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRevenuePanel(context),
          const SizedBox(height: 14),
          _buildBookingReportPanel(context),
          const SizedBox(height: 14),
          _buildOperationsPanel(context),
          const SizedBox(height: 14),
          _buildBookingAuditPanel(context, bookings),
          const SizedBox(height: 14),
          _buildExportPanel(),

        ],
      ),
    );
  }

  Widget _buildRevenuePanel(BuildContext context) {
    return _FinancePanel(
      title: 'Báo cáo doanh thu',
      icon: Icons.stacked_line_chart_rounded,
      trailing: _PanelRefreshButton(
        isLoading: _loadingReport,
        onPressed: _fetchRevenueReport,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateRangeToolbar(
            start: _reportStart,
            end: _reportEnd,
            onPickStart: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _reportStart,
                firstDate: DateTime(2020),
                lastDate: _reportEnd,
              );
              if (picked != null) setState(() => _reportStart = picked);
            },
            onPickEnd: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _reportEnd,
                firstDate: _reportStart,
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _reportEnd = picked);
            },
            onApply: _fetchRevenueReport,
          ),
          const SizedBox(height: 12),
          if (_loadingReport)
            const _PanelLoading()
          else if (_reportError != null)
            _PanelError(message: _reportError!, onRetry: _fetchRevenueReport)
          else if (_revenueReport == null)
            const _PanelEmpty(message: 'Chưa có dữ liệu doanh thu.')
          else ...[
            _DashboardGrid(
              children: [
                _CompactMetric(
                  label: 'Tổng doanh thu',
                  value: money(_revenueReport!.totalRevenue),
                ),
                _CompactMetric(
                  label: 'Tổng booking',
                  value: '${_revenueReport!.totalBookings}',
                ),
                _CompactMetric(
                  label: 'Giá trị TB',
                  value: money(_revenueReport!.averageBookingValue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SubsectionLabel(
              'Phương thức thanh toán',
              '${_revenueReport!.byPaymentMethod.length} kênh',
            ),
            const SizedBox(height: 6),
            for (final item in _revenueReport!.byPaymentMethod)
              _PaymentMethodRow(method: item),
            const SizedBox(height: 12),
            _SubsectionLabel(
              'Doanh thu theo ngày',
              '${shortDate(_revenueReport!.startDate)} - ${shortDate(_revenueReport!.endDate)}',
            ),
            const SizedBox(height: 8),
            for (final day in _revenueReport!.dailySeries.take(8))
              _DailyRevenueBar(day: day, maxRevenue: _maxDailyRevenue()),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingReportPanel(BuildContext context) {
    return _FinancePanel(
      title: 'Báo cáo booking',
      icon: Icons.analytics_rounded,
      trailing: _PanelRefreshButton(
        isLoading: _loadingBookingReport,
        onPressed: _fetchBookingReport,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateRangeToolbar(
            start: _bookingReportStart,
            end: _bookingReportEnd,
            onPickStart: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _bookingReportStart,
                firstDate: DateTime(2020),
                lastDate: _bookingReportEnd,
              );
              if (picked != null) setState(() => _bookingReportStart = picked);
            },
            onPickEnd: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _bookingReportEnd,
                firstDate: _bookingReportStart,
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _bookingReportEnd = picked);
            },
            onApply: _fetchBookingReport,
          ),
          const SizedBox(height: 12),
          if (_loadingBookingReport)
            const _PanelLoading()
          else if (_bookingReportError != null)
            _PanelError(
              message: _bookingReportError!,
              onRetry: _fetchBookingReport,
            )
          else if (_bookingReport == null)
            const _PanelEmpty(message: 'Chưa có dữ liệu booking.')
          else ...[
            _DashboardGrid(
              children: [
                _CompactMetric(
                  label: 'Tổng',
                  value: '${_bookingReport!.stats.total}',
                ),
                _CompactMetric(
                  label: 'Chờ soát',
                  value: '${_bookingReport!.stats.confirmed}',
                ),
                _CompactMetric(
                  label: 'Đã hủy',
                  value: '${_bookingReport!.stats.cancelled}',
                ),
                _CompactMetric(
                  label: 'Hoàn tiền',
                  value: '${_bookingReport!.stats.refunded}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _SubsectionLabel('Xếp hạng phim', 'theo doanh thu'),
            for (final ranking in _bookingReport!.movieRankings.take(5))
              _TopMovieRow(
                rank: ranking.rank,
                movie: MovieSales(
                  movieId: ranking.movieId,
                  title: ranking.title,
                  ticketsSold: ranking.ticketsSold,
                  revenue: ranking.revenue,
                ),
              ),
            const SizedBox(height: 8),
            const _SubsectionLabel('Tỷ lệ lấp đầy theo rạp', 'seat occupancy'),
            const SizedBox(height: 8),
            for (final item in _bookingReport!.theaterOccupancy.take(6))
              _OccupancyRow(item: item),
          ],
        ],
      ),
    );
  }

  Widget _buildOperationsPanel(BuildContext context) {
    return _FinancePanel(
      title: 'Hiệu suất vận hành',
      icon: Icons.insights_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_metrics != null && _metrics!.topMovies.isNotEmpty) ...[
            const _SubsectionLabel('Top phim hôm nay', 'API dashboard'),
            for (int i = 0; i < _metrics!.topMovies.take(5).length; i++)
              _TopMovieRow(rank: i + 1, movie: _metrics!.topMovies[i]),
          ] else
            const _PanelEmpty(message: 'Chưa có top phim từ API.'),
          if (_metrics != null && _metrics!.recentBookings.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _SubsectionLabel('Hoạt động gần đây', '10 booking mới nhất'),
            for (final item in _metrics!.recentBookings.take(6))
              _RecentBookingRow(booking: item),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingAuditPanel(BuildContext context, List<Booking> bookings) {
    return _FinancePanel(
      title: 'Booking và hoàn tiền',
      icon: Icons.receipt_long_rounded,
      trailing: TextButton.icon(
        onPressed: () => setState(() {
          _status = null;
          _date = null;
        }),
        icon: const Icon(Icons.filter_alt_off_outlined),
        label: const Text('Bỏ lọc'),
      ),
      child: Column(
        children: [
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
            const _PanelEmpty(message: 'Không có booking phù hợp.')
          else
            for (final booking in bookings.take(12))
              _BookingFinanceCard(
                booking: booking,
                store: widget.store,
                onRefund: () {
                  widget.store.cancelBooking(booking.id);
                  setState(() {});
                  _snack('Đã xử lý hoàn tiền VNPay Refund API demo.');
                },
              ),
        ],
      ),
    );
  }

  Widget _buildExportPanel() {
    return _FinancePanel(
      title: 'Tải xuống báo cáo',
      icon: Icons.download_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xuất toàn bộ dữ liệu đang có trên trang tài chính thành file Excel nhiều sheet.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _exportFinanceExcel,
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Tải xuống Excel .xlsx'),
            ),
          ),
        ],
      ),
    );
  }



  int _maxDailyRevenue() {
    final series = _revenueReport?.dailySeries ?? const <DailyRevenue>[];
    if (series.isEmpty) return 1;
    return series
        .map((item) => item.revenue)
        .reduce((value, item) => value > item ? value : item)
        .clamp(1, 1 << 62);
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

  Future<void> _exportFinanceExcel() async {
    try {
      if (_metrics == null ||
          _revenueReport == null ||
          _bookingReport == null) {
        await _refreshFinanceDashboard();
      }

      final excel = xls.Excel.createExcel();
      final now = DateTime.now();
      final bookings = widget.store.bookings;
      final soldByMovie = widget.store.soldTicketsByMovie();

      void addSheet(String name, List<List<Object?>> rows) {
        final sheet = excel[name];
        for (final row in rows) {
          sheet.appendRow(row.map(_excelCell).toList());
        }
      }

      addSheet('Tong quan', [
        ['Trường', 'Giá trị'],
        ['Ngày xuất', fullDateTime(now)],
        [
          'Khoảng doanh thu',
          '${shortDate(_reportStart)} - ${shortDate(_reportEnd)}',
        ],
        [
          'Khoảng booking',
          '${shortDate(_bookingReportStart)} - ${shortDate(_bookingReportEnd)}',
        ],
        [
          'Doanh thu hôm nay',
          _metrics?.todayRevenue ?? widget.store.revenueTotal(),
        ],
        ['Booking hôm nay', _metrics?.todayBookings ?? bookings.length],
        ['Active users', _metrics?.activeUsers ?? 0],
        ['Concurrent users', _metrics?.concurrentUsers ?? 0],
        ['Tổng doanh thu báo cáo', _revenueReport?.totalRevenue ?? 0],
        ['Tổng booking báo cáo', _revenueReport?.totalBookings ?? 0],
        ['Giá trị booking TB', _revenueReport?.averageBookingValue ?? 0],
        ['Booking tổng', _bookingReport?.stats.total ?? bookings.length],
        ['Booking chờ soát', _bookingReport?.stats.confirmed ?? 0],
        ['Booking đã hủy', _bookingReport?.stats.cancelled ?? 0],
        ['Booking hoàn tiền', _bookingReport?.stats.refunded ?? 0],
      ]);

      addSheet('Doanh thu ngay', [
        ['Ngày', 'Số booking', 'Doanh thu'],
        for (final day in _revenueReport?.dailySeries ?? const <DailyRevenue>[])
          [shortDate(day.date), day.bookings, day.revenue],
      ]);

      addSheet('Thanh toan', [
        ['Phương thức', 'Số giao dịch', 'Doanh thu'],
        for (final item
            in _revenueReport?.byPaymentMethod ??
                const <RevenueByPaymentMethod>[])
          [
            item.method.trim().isEmpty ? 'Khác' : item.method,
            item.count,
            item.amount,
          ],
      ]);

      addSheet('Booking report', [
        ['Chỉ số', 'Giá trị'],
        ['Tổng', _bookingReport?.stats.total ?? 0],
        ['Chờ soát', _bookingReport?.stats.confirmed ?? 0],
        ['Đã hủy', _bookingReport?.stats.cancelled ?? 0],
        ['Hoàn tiền', _bookingReport?.stats.refunded ?? 0],
      ]);

      addSheet('Xep hang phim', [
        ['Hạng', 'Movie ID', 'Tên phim', 'Vé bán', 'Doanh thu'],
        for (final item
            in _bookingReport?.movieRankings ?? const <MovieRanking>[])
          [item.rank, item.movieId, item.title, item.ticketsSold, item.revenue],
      ]);

      addSheet('Lap day rap', [
        ['Theater ID', 'Tên rạp', 'Tổng ghế', 'Ghế đã đặt', 'Tỷ lệ lấp đầy'],
        for (final item
            in _bookingReport?.theaterOccupancy ?? const <TheaterOccupancy>[])
          [
            item.theaterId,
            item.theaterName,
            item.totalSeats,
            item.bookedSeats,
            '${(item.occupancyRate * 100).toStringAsFixed(1)}%',
          ],
      ]);

      addSheet('Booking chi tiet', [
        [
          'Booking ID',
          'Khách hàng',
          'Phim',
          'Ngày tạo',
          'Trạng thái',
          'Thanh toán',
          'Số tiền',
        ],
        for (final booking in bookings)
          [
            booking.id,
            booking.customerName,
            booking.movieTitle,
            fullDateTime(booking.createdAt),
            bookingStatusLabel(booking.status),
            widget.store.paymentForBooking(booking.id)?.method.toUpperCase() ??
                '',
            booking.totalAmount,
          ],
      ]);



      excel.delete('Sheet1');
      final bytes = excel.save(
        fileName: 'cineluxe_finance_${_fileTimestamp(now)}.xlsx',
      );
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Không tạo được dữ liệu Excel.');
      }

      final dir = await _financeExportDirectory();
      await dir.create(recursive: true);
      final fileName = 'cineluxe_finance_${_fileTimestamp(now)}.xlsx';
      final file = File(p.join(dir.path, fileName));
      await file.writeAsBytes(bytes, flush: true);

      _snack('Đã tải file Excel: ${file.path}');
    } catch (e) {
      _snack('Không thể xuất Excel: ${_errorText(e)}');
    }
  }

  xls.CellValue? _excelCell(Object? value) {
    if (value == null) return null;
    if (value is int) return xls.IntCellValue(value);
    if (value is double) return xls.DoubleCellValue(value);
    if (value is bool) return xls.BoolCellValue(value);
    return xls.TextCellValue(value.toString());
  }

  String _fileTimestamp(DateTime value) {
    String two(int input) => input.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }

  Future<Directory> _financeExportDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    } catch (_) {}

    if (Platform.isAndroid) {
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) return downloads;
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
    }

    final home =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      final downloads = Directory(p.join(home, 'Downloads'));
      if (await downloads.exists()) return downloads;
    }

    return getApplicationDocumentsDirectory();
  }

  String _errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// ---------------------------------------------------------------------------
// Top movie row widget
// ---------------------------------------------------------------------------

class _FinanceHero extends StatelessWidget {
  const _FinanceHero({
    required this.revenue,
    required this.bookings,
    required this.lastRefreshed,
    required this.isLoading,
    required this.onRefresh,
  });

  final int revenue;
  final int bookings;
  final DateTime? lastRefreshed;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final updatedText = lastRefreshed == null
        ? 'Đang đồng bộ API'
        : 'Cập nhật ${shortTime(lastRefreshed!)}:${lastRefreshed!.second.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(10),
        boxShadow: softShadow(.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tổng quan tài chính',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Làm mới dữ liệu',
                onPressed: isLoading ? null : () => unawaited(onRefresh()),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            money(revenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _HeroPill(
                icon: Icons.receipt_rounded,
                label: '$bookings booking',
              ),
              _HeroPill(icon: Icons.cloud_done_rounded, label: updatedText),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _FinanceKpiCard extends StatelessWidget {
  const _FinanceKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    this.footer,
  });

  final String label;
  final String value;
  final String? footer;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: SizedBox(
        height: 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: tone),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 3),
              Text(
                footer!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinancePanel extends StatelessWidget {
  const _FinancePanel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.ink, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PanelRefreshButton extends StatelessWidget {
  const _PanelRefreshButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Tải lại báo cáo',
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded),
    );
  }
}

class _DateRangeToolbar extends StatelessWidget {
  const _DateRangeToolbar({
    required this.start,
    required this.end,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onApply,
  });

  final DateTime start;
  final DateTime end;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ActionChip(
          avatar: const Icon(Icons.calendar_today_outlined, size: 16),
          label: Text('Từ ${shortDate(start)}'),
          onPressed: onPickStart,
        ),
        ActionChip(
          avatar: const Icon(Icons.calendar_month_outlined, size: 16),
          label: Text('Đến ${shortDate(end)}'),
          onPressed: onPickEnd,
        ),
        FilledButton.icon(
          onPressed: onApply,
          icon: const Icon(Icons.manage_search_rounded),
          label: const Text('Xem báo cáo'),
        ),
      ],
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({required this.method});

  final RevenueByPaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final label = method.method.trim().isEmpty
        ? 'Khác'
        : method.method[0].toUpperCase() + method.method.substring(1);
    return _ReportRow(
      label: '$label (${method.count})',
      value: money(method.amount),
    );
  }
}

class _DailyRevenueBar extends StatelessWidget {
  const _DailyRevenueBar({required this.day, required this.maxRevenue});

  final DailyRevenue day;
  final int maxRevenue;

  @override
  Widget build(BuildContext context) {
    final progress = maxRevenue <= 0 ? 0.0 : day.revenue / maxRevenue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shortDate(day.date),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${day.bookings} booking',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                money(day.revenue),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 7,
            color: AppColors.ink,
            backgroundColor: AppColors.line,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }
}

class _OccupancyRow extends StatelessWidget {
  const _OccupancyRow({required this.item});

  final TheaterOccupancy item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.theaterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${(item.occupancyRate * 100).toStringAsFixed(1)}% (${item.bookedSeats}/${item.totalSeats})',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: item.occupancyRate.clamp(0.0, 1.0),
            minHeight: 7,
            color: AppColors.ink,
            backgroundColor: AppColors.line,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }
}

class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel(this.title, this.detail);

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelEmpty extends StatelessWidget {
  const _PanelEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}



class _PanelLoading extends StatelessWidget {
  const _PanelLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PanelError extends StatelessWidget {
  const _PanelError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: .20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

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
      title: Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final active = booking.status == BookingStatus.active;

    Color statusColor;
    Color statusBg;
    String statusLabel;
    switch (booking.status) {
      case BookingStatus.active:
        statusColor = const Color(0xFFB45309);
        statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        statusLabel = 'Chờ soát';
        break;
      case BookingStatus.used:
        statusColor = const Color(0xFF047857);
        statusBg = const Color(0xFF10B981).withValues(alpha: 0.12);
        statusLabel = 'Đã soát';
        break;
      case BookingStatus.cancelled:
        statusColor = const Color(0xFFB91C1C);
        statusBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        statusLabel = 'Đã hủy';
        break;
      case BookingStatus.refunded:
        statusColor = const Color(0xFF1D4ED8);
        statusBg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        statusLabel = 'Đã hoàn';
        break;
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.pearl,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${booking.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(booking.totalAmount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (payment != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pearl,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        payment.method.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.movieTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.muted,
                  ),
                ),
              ),
              if (active)
                TextButton.icon(
                  onPressed: onRefund,
                  icon: const Icon(Icons.undo_rounded, size: 14),
                  label: const Text('Hoàn tiền'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
