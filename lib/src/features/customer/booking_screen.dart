import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../api/exceptions/api_exceptions.dart';
import '../../../services/analytics_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../websocket/websocket_client.dart' as realtime;
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../state/cinema_store.dart';
import 'combo_selection_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.store,
    required this.movie,
    required this.showtime,
  });

  final CinemaStore store;
  final Movie movie;
  final Showtime showtime;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final List<String> _selectedSeats = [];
  final APIClient _apiClient = APIClient();
  late final realtime.WebSocketClient _webSocketClient;
  StreamSubscription? _seatUpdateSubscription;
  StreamSubscription? _connectionSubscription;
  realtime.ConnectionState _connectionState =
      realtime.ConnectionState.disconnected;
  bool _loadingSeats = true;
  bool _holdingSeats = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    _webSocketClient = realtime.WebSocketClient(onStateSync: _syncSeatState);
    _seatUpdateSubscription = _webSocketClient.seatUpdateStream.listen((
      update,
    ) {
      widget.store.applySeatUpdate(widget.showtime.id, update);
      if (update.status.name != 'available' && !_holdingSeats) {
        _selectedSeats.remove(update.seatCode);
      }
    });
    _connectionSubscription = _webSocketClient.connectionStateStream.listen((
      state,
    ) {
      if (mounted) setState(() => _connectionState = state);
    });
    _initializeRealtimeSeats();

    // Track seat_selection_start (Req 41.1)
    AnalyticsService.instance.trackSeatSelectionStart(
      showtimeId: widget.showtime.id,
      movieId: widget.movie.id,
    );
    // Track screen view (Req 41.4)
    AnalyticsService.instance.trackScreenView(screenName: 'seat_selection');
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _seatUpdateSubscription?.cancel();
    _connectionSubscription?.cancel();
    _webSocketClient.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeRealtimeSeats() async {
    try {
      await _syncSeatState(widget.showtime.id);
      if (mounted) setState(() => _loadError = null);

      final token = await SecureStorageService().getAccessToken();
      if (token == null) {
        return;
      }

      try {
        await _webSocketClient.connect(widget.showtime.id, token);
      } catch (_) {
        // The REST seat map is enough to let customers select seats; realtime
        // updates are a best-effort enhancement in local/web runs.
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _loadError = 'Không thể tải trạng thái ghế. Nhấn để thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingSeats = false);
    }
  }

  Future<void> _syncSeatState(String showtimeId) async {
    widget.store.applySeatMap(await _apiClient.getSeats(showtimeId));
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.store.roomById(widget.showtime.roomId);
    final cinema = widget.store.cinemaForRoom(widget.showtime.roomId);
    final total = widget.store.calculateTotal(
      widget.showtime,
      _selectedSeats,
      const [],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _cinemaName(cinema),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Rạp hiện tại',
                    onPressed: () {},
                    icon: const Icon(Icons.directions_bus_filled_outlined),
                  ),
                  Container(width: 1, height: 22, color: AppColors.line),
                  IconButton(
                    tooltip: 'Trang chủ',
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _SeatCheckoutBar(
        movie: widget.movie,
        showtime: widget.showtime,
        room: room,
        total: total,
        loading: _holdingSeats,
        selectedSeats: _selectedSeats,
        onContinue: _holdAndContinue,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _CinemaAddressBanner(address: _cinemaAddress(cinema)),
          _ConnectionBanner(
            state: _connectionState,
            error: _loadError,
            onRetry: _initializeRealtimeSeats,
          ),
          _SeatCounter(
            selected: _selectedSeats.length,
            maxSeats: 8,
          ),
          const SizedBox(height: 10),
          const _ScreenCurve(),
          const SizedBox(height: 10),
          if (_loadingSeats)
            const Center(child: CircularProgressIndicator())
          else
            _SeatMap(
              store: widget.store,
              showtime: widget.showtime,
              selectedSeats: _selectedSeats,
              onChanged: () => setState(() {}),
            ),
          const SizedBox(height: 22),
          const _SeatLegend(),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Xem chi tiết hình ảnh và thông tin ghế',
                style: TextStyle(
                  color: AppColors.ink,
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 12, color: AppColors.pearl),
        ],
      ),
    );
  }

  Future<void> _holdAndContinue() async {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần chọn ít nhất 1 ghế.')),
      );
      return;
    }

    setState(() => _holdingSeats = true);
    try {
      final hold = await _apiClient.holdSeats(
        widget.showtime.id,
        _selectedSeats,
        userId: widget.store.currentUser?.id,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ComboSelectionScreen(
            store: widget.store,
            movie: widget.movie,
            showtime: widget.showtime,
            selectedSeats: List.unmodifiable(_selectedSeats),
            hold: hold,
          ),
        ),
      );
    } on DioException catch (error) {
      final conflict = error.error;
      if (conflict is ApiConflictException) {
        _selectedSeats.removeWhere(conflict.unavailableSeats.contains);
        await _showSeatConflict(conflict.unavailableSeats);
        await _syncSeatState(widget.showtime.id);
      } else if (conflict is ApiAuthorizationException) {
        if (mounted) _showAgeVerificationRequired();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể giữ ghế. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _holdingSeats = false);
    }
  }

  void _showAgeVerificationRequired() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác minh độ tuổi yêu cầu'),
        content: const Text(
          'Phim này yêu cầu xác minh độ tuổi 18+. '
          'Vui lòng cập nhật ngày sinh trong hồ sơ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSeatConflict(List<String> seats) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ghế vừa được người khác chọn'),
        content: Text(
          seats.isEmpty
              ? 'Một số ghế không còn khả dụng.'
              : 'Ghế ${seats.join(', ')} không còn khả dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Thử lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chọn ghế khác'),
          ),
        ],
      ),
    );
  }

  String _cinemaName(Cinema cinema) {
    return cinema.name.contains('Ã') || cinema.name.contains('á')
        ? 'CineLuxe Tràng Tiền'
        : cinema.name;
  }

  String _cinemaAddress(Cinema cinema) {
    return cinema.address.contains('Ã') || cinema.address.contains('Æ')
        ? '24 Hai Bà Trưng, Hoàn Kiếm, Hà Nội'
        : '${cinema.address}, ${cinema.city}';
  }
}

/// Widget hiển thị counter số ghế đã chọn (R5 Bước 1 — tối đa 8 ghế).
class _SeatCounter extends StatelessWidget {
  const _SeatCounter({required this.selected, required this.maxSeats});

  final int selected;
  final int maxSeats;

  @override
  Widget build(BuildContext context) {
    if (selected == 0) return const SizedBox.shrink();
    final ratio = selected / maxSeats;
    final color = ratio >= 1.0
        ? const Color(0xFFE53935) // đỏ khi đạt max
        : ratio >= 0.75
            ? const Color(0xFFF57C00) // cam khi gần max
            : const Color(0xFF388E3C); // xanh bình thường
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_seat_rounded, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                'Đã chọn $selected / $maxSeats ghế',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (selected >= maxSeats) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Đã đủ 8 ghế',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.pearl,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({
    required this.state,
    required this.error,
    required this.onRetry,
  });

  final realtime.ConnectionState state;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state == realtime.ConnectionState.connected && error == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Material(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.sync_rounded),
          title: Text(error ?? 'Đang kết nối cập nhật ghế thời gian thực...'),
          trailing: error == null
              ? null
              : TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ),
      ),
    );
  }
}

class _CinemaAddressBanner extends StatelessWidget {
  const _CinemaAddressBanner({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppColors.ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Chi tiết',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenCurve extends StatelessWidget {
  const _ScreenCurve();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: CustomPaint(
        painter: _ScreenPainter(),
        child: const Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            'M À N  H Ì N H',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 18,
              letterSpacing: 0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .1, size.height * .48)
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .2,
        size.width * .9,
        size.height * .48,
      );
    canvas.drawPath(path, shadow);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeatMap extends StatelessWidget {
  const _SeatMap({
    required this.store,
    required this.showtime,
    required this.selectedSeats,
    required this.onChanged,
  });

  final CinemaStore store;
  final Showtime showtime;
  final List<String> selectedSeats;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final booked = store.bookedSeats(showtime.id);
    final held = store.heldSeats(showtime.id);
    final rows = _seatRows(store.seats);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in rows.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  for (final seat in row.value)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _SeatTile(
                        seat: seat,
                        selected: selectedSeats.contains(seat.code),
                        booked: booked.contains(seat.code),
                        held: held.contains(seat.code),
                        onTap: () => _toggleSeat(context, seat, booked, held),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Map<String, List<SeatSpot>> _seatRows(List<SeatSpot> seats) {
    final rows = <String, List<SeatSpot>>{};
    for (final seat in seats) {
      rows.putIfAbsent(seat.row, () => []).add(seat);
    }
    for (final rowSeats in rows.values) {
      rowSeats.sort((a, b) => b.column.compareTo(a.column));
    }
    return Map.fromEntries(
      rows.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  void _toggleSeat(
    BuildContext context,
    SeatSpot seat,
    Set<String> booked,
    Set<String> held,
  ) {
    if (booked.contains(seat.code) || held.contains(seat.code)) return;
    if (selectedSeats.contains(seat.code)) {
      selectedSeats.remove(seat.code);
    } else if (selectedSeats.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mỗi lần đặt tối đa 8 ghế.')),
      );
      return;
    } else {
      selectedSeats.add(seat.code);
    }
    onChanged();
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.seat,
    required this.selected,
    required this.booked,
    required this.held,
    required this.onTap,
  });

  final SeatSpot seat;
  final bool selected;
  final bool booked;
  final bool held;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = booked || held;
    final colors = _seatColors(seat.type, selected, disabled);
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 54,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Colors.black : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: disabled
            ? const Icon(Icons.close_rounded, color: AppColors.muted, size: 18)
            : Text(
                seat.code,
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  _SeatColors _seatColors(SeatType type, bool selected, bool disabled) {
    if (disabled) {
      return const _SeatColors(
        background: Colors.white,
        text: AppColors.muted,
        border: AppColors.line,
      );
    }
    if (selected) {
      return const _SeatColors(
        background: Colors.black,
        text: Colors.white,
        border: Colors.black,
      );
    }
    return switch (type) {
      SeatType.standard => const _SeatColors(
        background: Color(0xFFE8E8E8),
        text: Colors.black,
        border: Color(0xFFE8E8E8),
      ),
      SeatType.vip => const _SeatColors(
        background: Color(0xFFD4D4D4),
        text: Colors.black,
        border: Color(0xFFD4D4D4),
      ),
      SeatType.couple => const _SeatColors(
        background: Color(0xFFF4F4F4),
        text: Colors.black,
        border: Color(0xFFF4F4F4),
      ),
    };
  }
}

class _SeatColors {
  const _SeatColors({
    required this.background,
    required this.text,
    required this.border,
  });

  final Color background;
  final Color text;
  final Color border;
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _LegendItem(
            color: Colors.white,
            border: AppColors.line,
            label: 'Đã đặt',
          ),
          _LegendItem(color: Colors.black, label: 'Ghế bạn chọn'),
          _LegendItem(color: Color(0xFFE8E8E8), label: 'Ghế thường'),
          _LegendItem(color: Color(0xFFD4D4D4), label: 'Ghế VIP'),
          _LegendItem(color: Color(0xFFF4F4F4), label: 'Ghế đôi'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, this.border});

  final Color color;
  final String label;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: border ?? color, width: 2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SeatCheckoutBar extends StatelessWidget {
  const _SeatCheckoutBar({
    required this.movie,
    required this.showtime,
    required this.room,
    required this.total,
    required this.loading,
    required this.selectedSeats,
    required this.onContinue,
  });

  final Movie movie;
  final Showtime showtime;
  final Room room;
  final int total;
  final bool loading;
  final List<String> selectedSeats;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.line)),
          boxShadow: softShadow(.08),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AgeBadge(label: movie.ageRating),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Đổi suất',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${shortTime(showtime.startTime)}~${shortTime(showtime.endTime)} | ${DateFormatLite.weekday(showtime.startTime)}, ${shortDate(showtime.startTime)} | ${room.screenType} Phụ đề',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Tạm tính',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  total == 0 ? '0đ' : money(total),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Hiển thị ghế đã chọn (R5 bước 1)
            if (selectedSeats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_seat_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ghế: ${selectedSeats.join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${selectedSeats.length}/8',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 58,
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        selectedSeats.isEmpty
                            ? 'Chọn ghế để tiếp tục'
                            : 'Tiếp tục  →  Chọn Combo',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeBadge extends StatelessWidget {
  const _AgeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class DateFormatLite {
  static String weekday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'Hôm nay';
    return switch (date.weekday) {
      DateTime.monday => 'Thứ 2',
      DateTime.tuesday => 'Thứ 3',
      DateTime.wednesday => 'Thứ 4',
      DateTime.thursday => 'Thứ 5',
      DateTime.friday => 'Thứ 6',
      DateTime.saturday => 'Thứ 7',
      _ => 'Chủ nhật',
    };
  }
}
