import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/app_models.dart';
import '../../state/cinema_store.dart';
import 'booking_screen.dart';
import 'movie_reviews_section.dart';
import 'showtime_selection_screen.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Thông tin phim',
          style: TextStyle(fontWeight: FontWeight.w900),
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
                    tooltip: 'Rạp gần bạn',
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
      bottomNavigationBar: _BottomBuyBar(
        enabled: firstOpenShowtime != null,
        label: firstOpenShowtime == null ? 'Chưa có suất chiếu' : 'Mua vé',
        onPressed: firstOpenShowtime == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ShowtimeSelectionScreen(store: store, movie: movie),
                ),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          _MovieHero(movie: movie),
          _MovieMetaStrip(movie: movie),
          _MomoRatingCard(movie: movie),
          const _SectionDivider(),
          _StorySection(movie: movie),
          const _SectionDivider(),
          _CastSection(movie: movie),
          const _SectionDivider(),
          _ShowtimeSection(store: store, movie: movie, showtimes: showtimes),
          const _SectionDivider(),
          MovieReviewsSection(
            movieId: movie.id,
            currentUserId: store.currentUser?.id,
          ),
        ],
      ),
    );
  }
}

class _MovieHero extends StatelessWidget {
  const _MovieHero({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pearl,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              movie.posterUrl,
              width: 126,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 126,
                height: 180,
                color: Color(movie.heroColor).withValues(alpha: .25),
                child: const Icon(Icons.local_movies_rounded, size: 46),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _AgeBadge(label: movie.ageRating),
                const SizedBox(height: 10),
                Text(
                  movie.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  movie.genres.take(3).join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.black,
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${movie.rating.toStringAsFixed(1)}/10',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieMetaStrip extends StatelessWidget {
  const _MovieMetaStrip({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: [
          _MetaItem(
            value: '${movie.durationMinutes} phút',
            label: 'Thời lượng',
          ),
          const _VerticalDivider(),
          _MetaItem(value: shortDate(movie.releaseDate), label: 'Khởi chiếu'),
          const _VerticalDivider(),
          _MetaItem(
            value: movie.status == MovieStatus.nowShowing
                ? 'Đang chiếu'
                : 'Sắp chiếu',
            label: 'Trạng thái',
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _MomoRatingCard extends StatelessWidget {
  const _MomoRatingCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final rating = movie.rating.clamp(0, 10);
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_movies_rounded, color: Colors.black),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'CineLuxe Rating',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Viết đánh giá',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.black, size: 42),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: rating.toStringAsFixed(1).replaceAll('.0', ''),
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const TextSpan(
                      text: '/10',
                      style: TextStyle(fontSize: 18, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: _RatingBars(rating: rating.toDouble())),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Từ 126 khán giả đã mua vé',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _RatingBars extends StatelessWidget {
  const _RatingBars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('9-10', rating >= 8.5 ? .86 : .42),
      ('7-8', rating >= 7 ? .48 : .22),
      ('5-6', rating >= 5 ? .24 : .08),
      ('3-4', rating >= 3 ? .12 : .04),
      ('1-2', .04),
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    row.$1,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: row.$2,
                      minHeight: 5,
                      backgroundColor: AppColors.line,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StorySection extends StatelessWidget {
  const _StorySection({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading('Nội dung phim'),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                height: 1.45,
              ),
              children: [
                TextSpan(text: movie.description),
                const TextSpan(
                  text: '  Xem thêm',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CreditLine(label: 'Đạo diễn', value: movie.director),
        ],
      ),
    );
  }
}

class _CastSection extends StatelessWidget {
  const _CastSection({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final cast = movie.cast;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 18),
            child: _SectionHeading('Diễn viên và Đoàn làm phim'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 178,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cast.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final name = cast[index];
                return _CastCard(name: name, role: _roleFor(index, movie));
              },
            ),
          ),
        ],
      ),
    );
  }

  String _roleFor(int index, Movie movie) {
    if (index == 0) return 'Vai chính';
    if (index == 1) return movie.genres.first;
    return 'Diễn viên';
  }
}

class _CastCard extends StatelessWidget {
  const _CastCard({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://api.dicebear.com/8.x/initials/png?seed=${Uri.encodeComponent(name)}&backgroundColor=fce7f3,ddd6fe,e0f2fe,fee2e2',
              width: 116,
              height: 112,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 116,
                height: 112,
                color: AppColors.pearl,
                alignment: Alignment.center,
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 3),
          Text(
            role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part.characters.first).join();
  }
}

class _ShowtimeSection extends StatelessWidget {
  const _ShowtimeSection({
    required this.store,
    required this.movie,
    required this.showtimes,
  });

  final CinemaStore store;
  final Movie movie;
  final List<Showtime> showtimes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 18),
            child: _SectionHeading('Suất chiếu gần nhất'),
          ),
          const SizedBox(height: 12),
          if (showtimes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(right: 18),
              child: Text('Phim này chưa mở lịch chiếu.'),
            )
          else
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: showtimes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final showtime = showtimes[index];
                  final room = store.roomById(showtime.roomId);
                  final ready = room.status == RoomStatus.ready;
                  return _ShowtimeTile(
                    showtime: showtime,
                    room: room,
                    enabled: ready,
                    onTap: ready
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
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ShowtimeTile extends StatelessWidget {
  const _ShowtimeTile({
    required this.showtime,
    required this.room,
    required this.enabled,
    required this.onTap,
  });

  final Showtime showtime;
  final Room room;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : AppColors.pearl,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? Colors.black : AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${shortTime(showtime.startTime)} • ${room.screenType}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              room.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const Spacer(),
            Text(
              money(showtime.basePrice),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudienceReviews extends StatefulWidget {
  const _AudienceReviews({required this.store, required this.movie});

  final CinemaStore store;
  final Movie movie;

  @override
  State<_AudienceReviews> createState() => _AudienceReviewsState();
}

class _AudienceReviewsState extends State<_AudienceReviews> {
  final _comment = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userReviews = widget.store.reviews
        .where((item) => item.movieId == widget.movie.id)
        .toList();
    final reviews = [
      ...userReviews.map(_ReviewView.fromReview),
      ..._sampleReviews(widget.movie),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading('Đánh giá từ khán giả (${reviews.length})'),
          const SizedBox(height: 12),
          _WriteReviewCard(
            controller: _comment,
            rating: _rating,
            onRatingChanged: (value) => setState(() => _rating = value),
            onSend: () {
              widget.store.addReview(
                widget.movie.id,
                _rating,
                _comment.text.trim(),
              );
              _comment.clear();
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
          ...reviews
              .take(4)
              .map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReviewCard(review: review),
                ),
              ),
        ],
      ),
    );
  }

  List<_ReviewView> _sampleReviews(Movie movie) {
    return [
      const _ReviewView(
        initials: 'MT',
        name: 'Ngô Minh Thiện',
        date: '25/05/2026',
        rating: 4,
        mood: 'Chưa ưng...',
        text: 'Phim chưa thật sự bùng nổ, phần nhạc và nhịp kể còn hơi đều.',
        tags: ['Chưa đặc sắc', 'Bình thường'],
        reactions: '😡 👍 😢 26',
        comments: '2 bình luận',
      ),
      _ReviewView(
        initials: 'TD',
        name: 'Nguyễn Tiến Đạt',
        date: '24/05/2026',
        rating: movie.rating.round().clamp(1, 10),
        mood: 'Cực phẩm!',
        text:
            'Phim rất hay, hình ảnh đẹp và dễ theo dõi. Không cần biết nhiều trước đó vẫn xem được trọn vẹn.',
        tags: const ['Tuyệt vời', 'Hài lòng', 'Cảm động', 'Ý nghĩa'],
        reactions: '😡 👍 😮 9',
        comments: '1 bình luận',
      ),
    ];
  }
}

class _WriteReviewCard extends StatelessWidget {
  const _WriteReviewCard({
    required this.controller,
    required this.rating,
    required this.onRatingChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Bạn nghĩ gì về bộ phim này?',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => onRatingChanged(index + 1),
                  child: Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.black,
                  ),
                );
              }),
              const Spacer(),
              FilledButton(
                onPressed: onSend,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Gửi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final _ReviewView review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: softShadow(.035),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.pearl,
                child: Text(
                  review.initials,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Đã mua qua CineLuxe • ${review.date}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ScorePill(score: review.rating),
                  const SizedBox(height: 6),
                  Text(
                    review.mood,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.35,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in review.tags)
                Chip(
                  label: Text(tag),
                  side: BorderSide.none,
                  backgroundColor: AppColors.pearl,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                review.reactions,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '| ${review.comments}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const Spacer(),
              const _SquareIconButton(icon: Icons.mode_comment_outlined),
              const SizedBox(width: 8),
              const _SquareIconButton(icon: Icons.thumb_up_alt_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewView {
  const _ReviewView({
    required this.initials,
    required this.name,
    required this.date,
    required this.rating,
    required this.mood,
    required this.text,
    required this.tags,
    required this.reactions,
    required this.comments,
  });

  final String initials;
  final String name;
  final String date;
  final int rating;
  final String mood;
  final String text;
  final List<String> tags;
  final String reactions;
  final String comments;

  factory _ReviewView.fromReview(Review review) {
    return _ReviewView(
      initials: 'CL',
      name: 'Khán giả ${review.userId}',
      date: shortDate(review.createdAt),
      rating: review.rating * 2,
      mood: review.rating >= 4 ? 'Cực phẩm!' : 'Đã xem',
      text: review.comment.isEmpty ? 'Không có bình luận.' : review.comment,
      tags: const ['Đã mua vé', 'CineLuxe'],
      reactions: '👍 ${review.rating + 3}',
      comments: '0 bình luận',
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
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          '★ $score/10',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.line),
        ),
        child: Icon(icon, color: AppColors.ink),
      ),
    );
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

class _BottomBuyBar extends StatelessWidget {
  const _BottomBuyBar({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .96),
          border: const Border(top: BorderSide(color: AppColors.line)),
          boxShadow: softShadow(.1),
        ),
        child: SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: enabled ? Colors.black : AppColors.muted,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(label),
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
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 12, color: AppColors.pearl);
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.line);
  }
}
