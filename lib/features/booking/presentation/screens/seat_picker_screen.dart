import 'package:cine_book/core/constants/app_colors.dart';
import 'package:cine_book/features/booking/data/models/seat_model.dart';
import 'package:cine_book/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SeatPickerScreen extends StatefulWidget {
  final String showtimeId;

  const SeatPickerScreen({super.key, required this.showtimeId});

  @override
  State<SeatPickerScreen> createState() => _SeatPickerScreenState();
}

class _SeatPickerScreenState extends State<SeatPickerScreen> {
  final List<SeatModel> _seats = [];
  final List<String> _selectedSeatIds = [];

  @override
  void initState() {
    super.initState();
    _generateMockSeats();
  }

  void _generateMockSeats() {
    for (int row = 0; row < 8; row++) {
      String rowLabel = String.fromCharCode(65 + row);
      for (int col = 1; col <= 10; col++) {
        SeatType type = SeatType.regular;
        if (row >= 5) type = SeatType.vip;
        if (row == 7 && (col == 1 || col == 2 || col == 9 || col == 10)) type = SeatType.sweetbox;
        
        // Randomly mark some as taken
        if ((row + col) % 7 == 0) type = SeatType.taken;

        _seats.add(SeatModel(
          id: '$rowLabel$col',
          label: '$rowLabel$col',
          type: type,
        ));
      }
    }
  }

  void _toggleSeat(SeatModel seat) {
    if (seat.type == SeatType.taken) return;
    
    setState(() {
      if (seat.isSelected) {
        seat.isSelected = false;
        _selectedSeatIds.remove(seat.id);
      } else {
        if (_selectedSeatIds.length < 8) {
          seat.isSelected = true;
          _selectedSeatIds.add(seat.id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn chỉ có thể chọn tối đa 8 ghế')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Chọn ghế'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildScreenIndicator(),
          const SizedBox(height: 40),
          Expanded(child: _buildSeatGrid()),
          _buildLegend(),
          _buildBottomSummary(),
        ],
      ),
    );
  }

  Widget _buildScreenIndicator() {
    return Column(
      children: [
        Container(
          width: 300,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Màn hình', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSeatGrid() {
    return InteractiveViewer(
      maxScale: 2.0,
      minScale: 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GridView.builder(
          itemCount: _seats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 10,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final seat = _seats[index];
            return GestureDetector(
              onTap: () => _toggleSeat(seat),
              child: Container(
                decoration: BoxDecoration(
                  color: _getSeatColor(seat),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    seat.label,
                    style: TextStyle(
                      color: seat.type == SeatType.taken ? Colors.white24 : Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getSeatColor(SeatModel seat) {
    if (seat.isSelected) return AppColors.primary;
    switch (seat.type) {
      case SeatType.taken:
        return Colors.white12;
      case SeatType.vip:
        return Colors.amber.withValues(alpha: 0.3);
      case SeatType.sweetbox:
        return Colors.pink.withValues(alpha: 0.3);
      case SeatType.regular:
        return Colors.white24;
    }
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem(Colors.white24, 'Trống'),
          _legendItem(Colors.white12, 'Đã đặt'),
          _legendItem(AppColors.primary, 'Đang chọn'),
          _legendItem(Colors.amber.withValues(alpha: 0.3), 'VIP'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedSeatIds.length} ghế đã chọn',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(
                  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0)
                      .format(_selectedSeatIds.length * 90000),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _selectedSeatIds.isEmpty ? null : () {
              GoRouter.of(context).push(
                '${AppRouter.orderSummary}?showtimeId=${widget.showtimeId}&seatIds=${_selectedSeatIds.join(',')}',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('TIẾP TỤC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
