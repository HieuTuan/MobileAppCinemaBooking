import 'package:cine_book/core/constants/app_colors.dart';
import 'package:cine_book/features/ticket/data/models/ticket_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketDetailScreen extends StatelessWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    // Consistent image URL
    const String imgBase = 'https://picsum.photos/seed';

    // In a real app, fetch ticket by ID. Using mock for now.
    final ticket = TicketModel(
      id: ticketId,
      movieTitle: 'Avengers: Endgame',
      posterUrl: '$imgBase/avengers/600/900',
      cinemaName: 'CGV Vincom Center',
      startTime: DateTime.now().add(const Duration(hours: 5)),
      seats: ['G5', 'G6'],
      bookingCode: 'BK123456',
      totalAmount: 180000,
      status: 'UPCOMING',
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Chi tiết vé'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          ticket.movieTitle.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(ticket.cinemaName, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoCol('Ngày', DateFormat('dd/MM').format(ticket.startTime)),
                            _buildInfoCol('Giờ', DateFormat('HH:mm').format(ticket.startTime)),
                            _buildInfoCol('Ghế', ticket.seats.join(', ')),
                          ],
                        ),
                        const SizedBox(height: 32),
                        QrImageView(
                          data: 'TICKET_${ticket.bookingCode}',
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ticket.bookingCode,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                  _buildTicketDivider(),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng thanh toán', style: TextStyle(color: Colors.grey)),
                        Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(ticket.totalAmount),
                          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Vui lòng đưa mã này cho nhân viên tại rạp để nhận vé cứng.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildTicketDivider() {
    return Stack(
      children: [
        const Divider(color: Colors.grey, height: 1, thickness: 1),
        Positioned(
          left: -15,
          top: -15,
          child: Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.backgroundDark, shape: BoxShape.circle)),
        ),
        Positioned(
          right: -15,
          top: -15,
          child: Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.backgroundDark, shape: BoxShape.circle)),
        ),
      ],
    );
  }
}
