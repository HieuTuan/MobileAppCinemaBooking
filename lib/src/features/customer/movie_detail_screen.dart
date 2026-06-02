import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';
import 'booking_screen.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({
    super.key,
    required this.store,
    required this.movie,
  });

  final CinemaStore store;
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final showtimes = store.showtimesForMovie(movie.id);
    final firstOpenShowtime = showtimes
        .where((item) => store.roomById(item.roomId).status == RoomStatus.ready)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text(
          'Chi tiết phim',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      bottomNavigationBar: _BottomBookBar(
        label: firstOpenShowtime == null
            ? 'Chưa có suất khả dụng'
            : 'Đặt vé ngay suất ${shortTime(firstOpenShowtime.startTime)}',
        onPressed: firstOpenShowtime == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingScreen(
                    store: store,
                    movie: movie,
                    showtime: firstOpenShowtime,
                  ),
                ),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HeroPoster(movie: movie),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(movie.ageRating, filled: true),
              ...movie.genres.take(3).map((genre) => _Tag(genre)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            movie.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            movie.title == 'Dune: Part Two' ? 'Dune: Part Two' : movie.director,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _InfoStrip(movie: movie),
          const SizedBox(height: 20),
          const _SectionHeading('Cốt truyện'),
          const SizedBox(height: 8),
          Text(
            movie.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 14),
          _CreditLine(label: 'Đạo diễn', value: movie.director),
          const SizedBox(height: 4),
          _CreditLine(label: 'Diễn viên', value: movie.cast.join(', ')),
          const SizedBox(height: 22),
          const _SectionHeading('Trailer'),
          const SizedBox(height: 10),
          _TrailerCard(url: movie.trailerUrl),
          const SizedBox(height: 22),
          _ShowtimeStrip(store: store, movie: movie, showtimes: showtimes),
          const SizedBox(height: 22),
          _ReviewBox(store: store, movie: movie),
        ],
      ),
    );
  }
}

class _HeroPoster extends StatelessWidget {
  const _HeroPoster({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 1.08,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                movie.posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Color(movie.heroColor).withValues(alpha: .2),
                  child: const Icon(Icons.local_movies_rounded, size: 52),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: .05),
                      AppColors.ink.withValues(alpha: .72),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          _InfoItem(
            label: 'Đánh giá',
            value: '⭐ ${movie.rating.toStringAsFixed(1)}',
          ),
          const _DividerLine(),
          _InfoItem(label: 'Thời lượng', value: '${movie.durationMinutes}p'),
          const _DividerLine(),
          _InfoItem(label: 'Khởi chiếu', value: shortDate(movie.releaseDate)),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: AppColors.line);
  }
}

class _CreditLine extends StatelessWidget {
  const _CreditLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _TrailerCard extends StatelessWidget {
  const _TrailerCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: AspectRatio(
        aspectRatio: 16 / 8.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nhấn phát liên kết YouTube:',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.gold,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowtimeStrip extends StatelessWidget {
  const _ShowtimeStrip({
    required this.store,
    required this.movie,
    required this.showtimes,
  });

  final CinemaStore store;
  final Movie movie;
  final List<Showtime> showtimes;

  @override
  Widget build(BuildContext context) {
    if (showtimes.isEmpty) {
      return const GlassCard(child: Text('Phim này chưa mở lịch chiếu.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Suất chiếu'),
        const SizedBox(height: 10),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: showtimes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final showtime = showtimes[index];
              final room = store.roomById(showtime.roomId);
              return SizedBox(
                width: 176,
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  onTap: room.status == RoomStatus.ready
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              store: store,
                              movie: movie,
                              showtime: showtime,
                            ),
                          ),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${shortTime(showtime.startTime)} • ${room.screenType}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        money(showtime.basePrice),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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

class _ReviewBox extends StatefulWidget {
  const _ReviewBox({required this.store, required this.movie});

  final CinemaStore store;
  final Movie movie;

  @override
  State<_ReviewBox> createState() => _ReviewBoxState();
}

class _ReviewBoxState extends State<_ReviewBox> {
  final _comment = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviews = widget.store.reviews
        .where((item) => item.movieId == widget.movie.id)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading('Đánh giá từ khán giả (${reviews.length})'),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _comment,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Hãy bình luận ấn tượng về bộ phim...',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Số sao: '),
                  ...List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => _rating = index + 1),
                      child: Icon(
                        index < _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.gold,
                      ),
                    );
                  }),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      widget.store.addReview(
                        widget.movie.id,
                        _rating,
                        _comment.text,
                      );
                      _comment.clear();
                    },
                    child: const Text('Gửi nhận xét'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          const GlassCard(child: Text('Chưa có đánh giá nào.'))
        else
          ...reviews.map(
            (review) => GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.goldSoft,
                  child: Icon(Icons.person_rounded, color: AppColors.ink),
                ),
                title: Text('Khán giả ${review.userId}'),
                subtitle: Text(
                  review.comment.isEmpty
                      ? 'Không có bình luận'
                      : review.comment,
                ),
                trailing: Text('⭐ ${review.rating}'),
              ),
            ),
          ),
      ],
    );
  }
}

class _BottomBookBar extends StatelessWidget {
  const _BottomBookBar({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.line)),
          boxShadow: softShadow(.09),
        ),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.local_fire_department_rounded),
            label: Text(label.toUpperCase()),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: AppColors.ink,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFFFB300) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: filled ? const Color(0xFFFFB300) : AppColors.line,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: filled ? 12 : 11,
          ),
        ),
      ),
    );
  }
}
