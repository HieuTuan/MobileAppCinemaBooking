import 'package:cine_book/core/constants/app_colors.dart';
import 'package:cine_book/core/utils/injection.dart';
import 'package:cine_book/features/booking/data/models/showtime_model.dart';
import 'package:cine_book/features/booking/domain/repositories/booking_repository.dart';
import 'package:cine_book/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ShowtimeScreen extends StatefulWidget {
  final String movieId;

  const ShowtimeScreen({super.key, required this.movieId});

  @override
  State<ShowtimeScreen> createState() => _ShowtimeScreenState();
}

class _ShowtimeScreenState extends State<ShowtimeScreen> {
  DateTime _selectedDate = DateTime.now();
  late Future<List<ShowtimeModel>> _showtimesFuture;

  @override
  void initState() {
    super.initState();
    _loadShowtimes();
  }

  void _loadShowtimes() {
    _showtimesFuture = getIt<BookingRepository>().getShowtimes(widget.movieId, _selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Chọn suất chiếu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          const Divider(color: Colors.white10),
          Expanded(
            child: FutureBuilder<List<ShowtimeModel>>(
              future: _showtimesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                final showtimes = snapshot.data ?? [];
                if (showtimes.isEmpty) {
                  return const Center(child: Text('Không có suất chiếu cho ngày này', style: TextStyle(color: Colors.grey)));
                }

                // Group showtimes by cinema
                final Map<String, List<ShowtimeModel>> grouped = {};
                for (var st in showtimes) {
                  grouped.putIfAbsent(st.cinemaName, () => []).add(st);
                }

                return ListView.builder(
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final cinemaName = grouped.keys.elementAt(index);
                    final cinemaShowtimes = grouped[cinemaName]!;
                    return _buildCinemaSection(cinemaName, cinemaShowtimes);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _loadShowtimes();
              });
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12, top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCinemaSection(String cinemaName, List<ShowtimeModel> showtimes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            cinemaName,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: showtimes.map((st) => _buildTimeSlot(st)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlot(ShowtimeModel st) {
    return GestureDetector(
      onTap: () {
        context.push('${AppRouter.seatPicker}?showtimeId=${st.id}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(
              DateFormat('HH:mm').format(st.startTime),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              st.format,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
