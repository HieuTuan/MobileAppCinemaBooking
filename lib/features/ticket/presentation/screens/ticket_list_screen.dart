import 'package:cine_book/core/constants/app_colors.dart';
import 'package:cine_book/features/ticket/data/models/ticket_model.dart';
import 'package:cine_book/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TicketListScreen extends StatelessWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reliable image URLs from a CDN
    const String imgBase = 'https://picsum.photos/seed';

    // Mock tickets with updated URLs
    final List<TicketModel> mockTickets = [
      TicketModel(
        id: 't1',
        movieTitle: 'Avengers: Endgame',
        posterUrl: '$imgBase/avengers/600/900',
        cinemaName: 'CGV Vincom Center',
        startTime: DateTime.now().add(const Duration(hours: 5)),
        seats: ['G5', 'G6'],
        bookingCode: 'BK123456',
        totalAmount: 180000,
        status: 'UPCOMING',
      ),
      TicketModel(
        id: 't2',
        movieTitle: 'Spider-Man: No Way Home',
        posterUrl: '$imgBase/spiderman/600/900',
        cinemaName: 'Lotte Cinema Landmark',
        startTime: DateTime.now().subtract(const Duration(days: 2)),
        seats: ['H1', 'H2'],
        bookingCode: 'BK789012',
        totalAmount: 170000,
        status: 'USED',
      ),
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Vé của tôi'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Sắp xem'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTicketList(mockTickets.where((t) => t.status == 'UPCOMING').toList()),
            _buildTicketList(mockTickets.where((t) => t.status != 'UPCOMING').toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(List<TicketModel> tickets) {
    if (tickets.isEmpty) {
      return const Center(child: Text('Không có vé nào', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return GestureDetector(
          onTap: () => context.push('${AppRouter.ticketDetail}?id=${ticket.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ticket.posterUrl,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey[800],
                      child: const Icon(Icons.broken_image, color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.movieTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(ticket.cinemaName, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm - dd/MM').format(ticket.startTime),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Ghế: ${ticket.seats.join(", ")}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.qr_code_2, color: Colors.white24, size: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
