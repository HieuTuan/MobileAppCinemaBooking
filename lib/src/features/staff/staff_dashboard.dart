import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/labels.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/luxury_scaffold.dart';
import '../../state/cinema_store.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key, required this.store});

  final CinemaStore store;

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final _code = TextEditingController(text: 'BK-DEMO01');
  final _search = TextEditingController();
  final _issue = TextEditingController();
  String _scanResult = 'Sẵn sàng quét QR hoặc nhập mã vé.';

  @override
  void dispose() {
    _code.dispose();
    _search.dispose();
    _issue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final query = _search.text.toLowerCase();
    final results = store.bookings.where((booking) {
      return query.isEmpty ||
          booking.id.toLowerCase().contains(query) ||
          booking.customerName.toLowerCase().contains(query);
    }).toList();

    return LuxuryScaffold(
      title: 'Bảng nhân viên',
      actions: [
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: store.logout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Vé chờ soát',
                  value: store.bookings
                      .where((item) => item.status == BookingStatus.active)
                      .length
                      .toString(),
                  icon: Icons.qr_code_scanner_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  label: 'Phòng sẵn sàng',
                  value: store.rooms
                      .where((room) => room.status == RoomStatus.ready)
                      .length
                      .toString(),
                  icon: Icons.meeting_room_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SectionTitle(title: 'Xác thực vé tại cổng'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _code,
                  decoration: const InputDecoration(
                    labelText: 'Mã vé hoặc QR data',
                    prefixIcon: Icon(Icons.qr_code_2_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                ShimmerButton(
                  label: 'Quét / xác thực',
                  icon: Icons.verified_rounded,
                  onPressed: () {
                    setState(() {
                      _scanResult = store.validateTicket(_code.text);
                    });
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  _scanResult,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SectionTitle(title: 'Hỗ trợ khách tại quầy'),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Tra cứu theo tên khách, số điện thoại hoặc mã vé',
              prefixIcon: Icon(Icons.support_agent_rounded),
            ),
          ),
          const SizedBox(height: 10),
          ...results.map(
            (booking) => GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${booking.id} - ${booking.customerName}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${booking.movieTitle} - ghế ${booking.seats.join(', ')}',
                  ),
                  Text(
                    'Trạng thái: ${bookingStatusLabel(booking.status)} - ${money(booking.totalAmount)}',
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: booking.status == BookingStatus.active
                            ? () => store.cancelBooking(booking.id)
                            : null,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Đổi/Hủy'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showMessage('Đã gửi lại vé qua email demo.'),
                        icon: const Icon(Icons.mail_outline_rounded),
                        label: const Text('Gửi email'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showMessage('Lệnh in vé giấy đã được tạo.'),
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('In vé'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SectionTitle(title: 'Phòng chiếu và sự cố'),
          ...store.rooms.map(
            (room) => GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${room.name} - ${room.screenType}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Switch(
                        value: room.status == RoomStatus.ready,
                        onChanged: (_) => store.toggleRoomStatus(room.id),
                      ),
                    ],
                  ),
                  Text(
                    'Sức chứa ${room.capacity} - ${roomStatusLabel(room.status)}',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _issue,
                    decoration: const InputDecoration(
                      hintText: 'Mô tả sự cố kỹ thuật',
                      prefixIcon: Icon(Icons.report_problem_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      store.reportIssue(
                        room.id,
                        _issue.text.trim().isEmpty
                            ? 'Cần kiểm tra phòng ${room.name}'
                            : _issue.text.trim(),
                      );
                      _issue.clear();
                    },
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Báo cáo Admin'),
                  ),
                ],
              ),
            ),
          ),
          const SectionTitle(title: 'Danh sách đặt vé theo suất'),
          ...store.showtimes.map((showtime) {
            final count = store.bookings
                .where((booking) => booking.showtimeId == showtime.id)
                .fold<int>(0, (sum, booking) => sum + booking.seats.length);
            final movie = store.movieById(showtime.movieId);
            return ListTile(
              leading: const Icon(Icons.event_available_rounded),
              title: Text(movie.title),
              subtitle: Text(
                '${shortDate(showtime.startTime)} ${shortTime(showtime.startTime)}',
              ),
              trailing: Text('$count ghế'),
            );
          }),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
