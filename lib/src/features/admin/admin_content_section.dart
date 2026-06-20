import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class AdminContentSection extends StatelessWidget {
  const AdminContentSection({super.key, required this.store});

  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Phim',
                value: '${store.movies.length}',
                icon: Icons.local_movies_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                label: 'Suất chiếu',
                value: '${store.showtimes.length}',
                icon: Icons.event_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        SectionTitle(
          title: 'Quản lý phim',
          action: FilledButton.icon(
            onPressed: () => _movieDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm'),
          ),
        ),
        ...store.movies.map(
          (movie) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl,
                  width: 48,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 48,
                    height: 64,
                    color: AppColors.pearl,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 48,
                    height: 64,
                    color: AppColors.pearl,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              title: Text(
                movie.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${movie.genres.join(', ')} • ${movie.ageRating} • ${movie.director}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Sửa phim',
                    onPressed: () => _movieDialog(context, movie: movie),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Xóa phim',
                    onPressed: () => store.deleteMovie(movie.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
        SectionTitle(
          title: 'Danh mục thể loại',
          action: TextButton.icon(
            onPressed: () => _genreDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm'),
          ),
        ),
        GlassCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final genre in store.genres.skip(1))
                InputChip(
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: Text(genre),
                  onDeleted: () => store.deleteGenre(genre),
                ),
            ],
          ),
        ),
        SectionTitle(
          title: 'Rạp và phòng chiếu',
          action: FilledButton.icon(
            onPressed: () => _roomDialog(context),
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('Phòng'),
          ),
        ),
        ...store.rooms.map(
          (room) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.meeting_room_rounded),
              title: Text('${room.name} • ${room.screenType}'),
              subtitle: Text(
                'Sức chứa ${room.capacity} • Ghế: thường, VIP, đôi',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Sửa phòng',
                    onPressed: () => _roomDialog(context, room: room),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  Switch(
                    value: room.status == RoomStatus.ready,
                    onChanged: (_) => store.toggleRoomStatus(room.id),
                  ),
                ],
              ),
            ),
          ),
        ),
        SectionTitle(
          title: 'Lịch chiếu',
          action: FilledButton.icon(
            onPressed: () => _showtimeDialog(context),
            icon: const Icon(Icons.add_alarm_rounded),
            label: const Text('Tạo suất'),
          ),
        ),
        ...store.showtimes.map((showtime) {
          final movie = store.movieById(showtime.movieId);
          final room = store.roomById(showtime.roomId);
          return GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_rounded),
              title: Text(movie.title),
              subtitle: Text(
                '${room.name} • ${shortDate(showtime.startTime)} ${shortTime(showtime.startTime)}',
              ),
              trailing: Wrap(
                spacing: 6,
                children: [
                  Text(money(showtime.basePrice)),
                  IconButton(
                    tooltip: 'Xóa suất',
                    onPressed: () => store.deleteShowtime(showtime.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _movieDialog(BuildContext context, {Movie? movie}) {
    final now = DateTime.now();
    final title = TextEditingController(text: movie?.title ?? 'Phim mới');
    final poster = TextEditingController(text: movie?.posterUrl ?? '');
    final trailer = TextEditingController(text: movie?.trailerUrl ?? '');
    final description = TextEditingController(
      text: movie?.description ?? 'Mô tả phim mới từ Admin Panel.',
    );
    final genres = TextEditingController(
      text: movie?.genres.join(', ') ?? 'Hành động',
    );
    final director = TextEditingController(
      text: movie?.director ?? 'Đang cập nhật',
    );
    final cast = TextEditingController(
      text: movie?.cast.join(', ') ?? 'Đang cập nhật',
    );
    final age = TextEditingController(text: movie?.ageRating ?? 'T13');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(movie == null ? 'Thêm phim' : 'Sửa phim'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(title, 'Tên phim'),
                _dialogField(poster, 'Poster URL'),
                _dialogField(trailer, 'Trailer URL'),
                _dialogField(description, 'Mô tả', maxLines: 3),
                _dialogField(genres, 'Thể loại, cách nhau bằng dấu phẩy'),
                _dialogField(director, 'Đạo diễn'),
                _dialogField(cast, 'Diễn viên, cách nhau bằng dấu phẩy'),
                _dialogField(age, 'Xếp hạng tuổi'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              store.saveMovie(
                Movie(
                  id: movie?.id ?? 'M${compactId(now)}',
                  title: title.text.trim(),
                  description: description.text.trim(),
                  genres: genres.text
                      .split(',')
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .toList(),
                  durationMinutes: movie?.durationMinutes ?? 110,
                  director: director.text.trim(),
                  cast: cast.text
                      .split(',')
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .toList(),
                  posterUrl: poster.text.trim().isEmpty
                      ? 'https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg'
                      : poster.text.trim(),
                  trailerUrl: trailer.text.trim().isEmpty
                      ? 'https://youtu.be/demo'
                      : trailer.text.trim(),
                  rating: movie?.rating ?? 7.5,
                  ageRating: age.text.trim(),
                  releaseDate: movie?.releaseDate ?? now,
                  status: movie?.status ?? MovieStatus.comingSoon,
                  heroColor: movie?.heroColor ?? 0xFFC9A44C,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _showtimeDialog(BuildContext context) {
    var movieId = store.movies.first.id;
    var roomId = store.rooms.first.id;
    final price = TextEditingController(text: '120000');
    final date = DateTime.now().add(const Duration(days: 1));
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo suất chiếu'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: movieId,
                decoration: const InputDecoration(labelText: 'Phim'),
                items: [
                  for (final movie in store.movies)
                    DropdownMenuItem(value: movie.id, child: Text(movie.title)),
                ],
                onChanged: (value) => setDialogState(() => movieId = value!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: roomId,
                decoration: const InputDecoration(labelText: 'Phòng'),
                items: [
                  for (final room in store.rooms)
                    DropdownMenuItem(value: room.id, child: Text(room.name)),
                ],
                onChanged: (value) => setDialogState(() => roomId = value!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá vé cơ bản'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final start = DateTime(date.year, date.month, date.day, 19);
              store.saveShowtime(
                Showtime(
                  id: 'ST${compactId(DateTime.now())}',
                  movieId: movieId,
                  roomId: roomId,
                  startTime: start,
                  endTime: start.add(const Duration(minutes: 110)),
                  basePrice: int.tryParse(price.text) ?? 120000,
                  status: 'Đang mở',
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _genreDialog(BuildContext context) {
    final genre = TextEditingController(text: 'Tâm lý');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thể loại'),
        content: TextField(
          controller: genre,
          decoration: const InputDecoration(labelText: 'Tên thể loại'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              store.addGenre(genre.text);
              Navigator.pop(context);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _roomDialog(BuildContext context, {Room? room}) {
    final name = TextEditingController(text: room?.name ?? 'Phòng mới');
    final capacity = TextEditingController(text: '${room?.capacity ?? 60}');
    final screenType = TextEditingController(text: room?.screenType ?? '2D');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(room == null ? 'Thêm phòng chiếu' : 'Sửa phòng chiếu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(name, 'Tên phòng'),
            _dialogField(capacity, 'Sức chứa'),
            _dialogField(screenType, 'Công nghệ chiếu: 2D/3D/IMAX'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              store.saveRoom(
                Room(
                  id: room?.id ?? 'R${compactId(DateTime.now())}',
                  cinemaId: room?.cinemaId ?? store.cinemas.first.id,
                  name: name.text.trim(),
                  capacity: int.tryParse(capacity.text) ?? 60,
                  screenType: screenType.text.trim(),
                  status: room?.status ?? RoomStatus.ready,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
