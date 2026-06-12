import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/booking_models.dart';
import '../../core/formatters.dart';
import '../../state/cinema_store.dart';
import 'booking_confirmation_screen.dart';

class ApiTicketsScreen extends StatefulWidget {
  const ApiTicketsScreen({super.key, required this.store});

  final CinemaStore store;

  @override
  State<ApiTicketsScreen> createState() => _ApiTicketsScreenState();
}

class _ApiTicketsScreenState extends State<ApiTicketsScreen> {
  final APIClient _apiClient = APIClient();
  String? _status;
  late Future<List<BookingDetails>> _bookings = _load();

  Future<List<BookingDetails>> _load() {
    return _apiClient.getUserBookings(
      widget.store.currentUser!.id,
      status: _status,
    );
  }

  void _refresh() {
    setState(() => _bookings = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: DropdownButtonFormField<String?>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Trạng thái'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả')),
              DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
              DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
            ],
            onChanged: (value) {
              _status = value;
              _refresh();
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<BookingDetails>>(
            future: _bookings,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại lịch sử đặt vé'),
                  ),
                );
              }
              final bookings = snapshot.requireData;
              if (bookings.isEmpty) {
                return const Center(child: Text('Bạn chưa có booking nào.'));
              }
              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: bookings.length,
                  itemBuilder: (_, index) => _BookingCard(
                    booking: bookings[index],
                    userId: widget.store.currentUser!.id,
                    onChanged: _refresh,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.userId,
    required this.onChanged,
  });

  final BookingDetails booking;
  final String userId;
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
            Text(
              booking.movieTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
    final estimatedRefund = beforeTwoHours
        ? booking.totalAmount
        : booking.totalAmount ~/ 2;
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
    final result = await APIClient().cancelBooking(
      booking.bookingId,
      userId: userId,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã hủy vé, hoàn ${money(result.refundAmount)}')),
    );
    onChanged();
  }
}
