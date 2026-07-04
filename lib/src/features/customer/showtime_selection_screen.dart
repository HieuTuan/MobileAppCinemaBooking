import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api_client.dart';
import '../../../models/booking_models.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../state/cinema_store.dart';
import 'age_gate_modal.dart';
import 'booking_screen.dart';

class ShowtimeSelectionScreen extends StatefulWidget {
  const ShowtimeSelectionScreen({
    super.key,
    required this.store,
    required this.movie,
  });

  final CinemaStore store;
  final Movie movie;

  @override
  State<ShowtimeSelectionScreen> createState() =>
      _ShowtimeSelectionScreenState();
}

class _ShowtimeSelectionScreenState extends State<ShowtimeSelectionScreen> {
  final _api = APIClient();
  int _dateIndex = 0;
  int _timeIndex = 0;
  bool _loadingShowtimes = true;
  String? _loadError;
  final Map<String, String> _availabilityLabels = {};

  static const _timeSlots = [
    _TimeSlot('Tất cả', null, null),
    _TimeSlot('9:00 - 12:00', 9, 12),
    _TimeSlot('12:00 - 15:00', 12, 15),
    _TimeSlot('15:00 - 18:00', 15, 18),
    _TimeSlot('18:00 - 23:00', 18, 23),
  ];

  @override
  void initState() {
    super.initState();
    _loadShowtimeData();
  }

  Future<void> _loadShowtimeData() async {
    setState(() {
      _loadingShowtimes = true;
      _loadError = null;
    });
    try {
      final showtimes = await _api.getShowtimes(widget.movie.id);
      widget.store.replaceShowtimesFromApi(showtimes);
      await _loadAvailabilityLabels(
        showtimes
            .where((showtime) => showtime.isScheduled)
            .map((item) => item.id)
            .toList(),
      );
      if (!mounted) return;
      setState(() {
        _dateIndex = 0;
        _loadingShowtimes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingShowtimes = false;
        _loadError = 'Không thể tải suất chiếu từ API.';
      });
    }
  }

  Future<void> _loadAvailabilityLabels(List<String> showtimeIds) async {
    final entries = await Future.wait(
      showtimeIds.map((id) async {
        try {
          final seatMap = await _api.getSeats(id);
          final total = seatMap.seats.length;
          final available = seatMap.seats
              .where((seat) => seat.status == ApiSeatStatus.available)
              .length;
          return MapEntry(id, 'Còn $available/$total');
        } catch (_) {
          return MapEntry(id, 'Đang cập nhật');
        }
      }),
    );
    if (!mounted) return;
    _availabilityLabels
      ..clear()
      ..addEntries(entries);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final showtimes = store
        .showtimesForMovie(widget.movie.id)
        .where((showtime) => showtime.isScheduled)
        .toList();
    final dates = _datesFrom(showtimes);
    final selectedDate = dates[_dateIndex.clamp(0, dates.length - 1)];
    final selectedSlot = _timeSlots[_timeIndex];
    final visibleShowtimes = showtimes.where((showtime) {
      final sameDate =
          showtime.startTime.year == selectedDate.year &&
          showtime.startTime.month == selectedDate.month &&
          showtime.startTime.day == selectedDate.day;
      return sameDate && selectedSlot.matches(showtime.startTime);
    }).toList();
    final cinema = store.cinemas.isNotEmpty
        ? store.cinemas.first
        : const Cinema(
            id: 'cinema-api',
            name: 'CineLuxe',
            address: '',
            city: '',
            latitude: 0,
            longitude: 0,
            phone: '',
          );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.movie.title,
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
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 0, 12),
            child: SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _DateCard(
                    date: dates[index],
                    selected: index == _dateIndex,
                    onTap: () => setState(() => _dateIndex = index),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 14),
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _timeSlots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _TimePill(
                    label: _timeSlots[index].label,
                    selected: index == _timeIndex,
                    onTap: () => setState(() => _timeIndex = index),
                  );
                },
              ),
            ),
          ),
          const _SectionDivider(),
          if (_loadingShowtimes)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Material(
                color: AppColors.pearl,
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: Text(_loadError!),
                  trailing: TextButton(
                    onPressed: _loadShowtimeData,
                    child: const Text('Thử lại'),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Rạp CineLuxe',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                  ),
                  child: const Text('Hà Nội'),
                ),
              ],
            ),
          ),
          _CinemaShowtimeCard(
            cinemaName: _cinemaName(cinema),
            address: _cinemaAddress(cinema),
            movie: widget.movie,
            showtimes: visibleShowtimes,
            store: store,
            availabilityLabels: _availabilityLabels,
          ),
        ],
      ),
    );
  }

  List<DateTime> _datesFrom(List<Showtime> showtimes) {
    final dates = <DateTime>[];
    for (final showtime in showtimes) {
      final date = DateTime(
        showtime.startTime.year,
        showtime.startTime.month,
        showtime.startTime.day,
      );
      if (!dates.any((item) => item.isAtSameMomentAs(date))) {
        dates.add(date);
      }
    }
    if (dates.isEmpty) {
      final now = DateTime.now();
      dates.add(DateTime(now.year, now.month, now.day));
    }
    return dates..sort();
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

class _CinemaShowtimeCard extends StatelessWidget {
  const _CinemaShowtimeCard({
    required this.cinemaName,
    required this.address,
    required this.movie,
    required this.showtimes,
    required this.store,
    required this.availabilityLabels,
  });

  final String cinemaName;
  final String address;
  final Movie movie;
  final List<Showtime> showtimes;
  final CinemaStore store;
  final Map<String, String> availabilityLabels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.pearl,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(
                  Icons.local_movies_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cinemaName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Bạn vừa chọn rạp này',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.muted),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Tìm đường',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '2D Phụ đề',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          if (showtimes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.pearl,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Không có suất chiếu trong khung giờ này.'),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 620 ? 4 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: showtimes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.64,
                  ),
                  itemBuilder: (context, index) {
                    final showtime = showtimes[index];
                    return _ShowtimeCard(
                      showtime: showtime,
                      movie: movie,
                      availabilityLabel:
                          availabilityLabels[showtime.id] ?? 'Đang cập nhật',
                      onTap: () => _navigateToBooking(
                        context,
                        store: store,
                        movie: movie,
                        showtime: showtime,
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ShowtimeCard extends StatelessWidget {
  const _ShowtimeCard({
    required this.showtime,
    required this.movie,
    required this.availabilityLabel,
    required this.onTap,
  });

  final Showtime showtime;
  final Movie movie;
  final String availabilityLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: shortTime(showtime.startTime),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: '~${shortTime(showtime.endTime)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Text(
                availabilityLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 92,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.black : AppColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  DateFormatLite.dayMonth(date),
                  style: TextStyle(
                    color: selected ? Colors.black : AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Container(
              height: 34,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.black : AppColors.pearl,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Text(
                DateFormatLite.weekday(date),
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
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

class _TimePill extends StatelessWidget {
  const _TimePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.black : AppColors.pearl,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TimeSlot {
  const _TimeSlot(this.label, this.startHour, this.endHour);

  final String label;
  final int? startHour;
  final int? endHour;

  bool matches(DateTime time) {
    if (startHour == null || endHour == null) return true;
    return time.hour >= startHour! && time.hour < endHour!;
  }
}

class DateFormatLite {
  static String dayMonth(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  static String weekday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'H.nay';
    return switch (date.weekday) {
      DateTime.monday => 'Thứ 2',
      DateTime.tuesday => 'Thứ 3',
      DateTime.wednesday => 'Thứ 4',
      DateTime.thursday => 'Thứ 5',
      DateTime.friday => 'Thứ 6',
      DateTime.saturday => 'Thứ 7',
      _ => 'C.Nhật',
    };
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 12, color: AppColors.pearl);
  }
}

/// Navigates to [BookingScreen], showing the age gate first when the movie
/// has an ageRating of 'T18' and the user hasn't confirmed in this session.
Future<void> _navigateToBooking(
  BuildContext context, {
  required CinemaStore store,
  required Movie movie,
  required Showtime showtime,
}) async {
  if (!store.isLoggedIn) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt vé.')),
      );
    context.go('/auth');
    return;
  }

  if (movie.ageRating == 'T18' && !AgeGateSession.isConfirmed(movie.id)) {
    final confirmed = await showAgeGate(context, movie.id);
    if (!confirmed) return; // user dismissed or underage — stay on this screen
  }
  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          BookingScreen(store: store, movie: movie, showtime: showtime),
    ),
  );
}
