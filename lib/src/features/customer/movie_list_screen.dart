import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';
import 'movie_detail_screen.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, required this.store});

  final CinemaStore store;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final _search = TextEditingController();
  String _genre = 'Tất cả';
  MovieStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final movies = store.searchMovies(_search.text, _genre, _status);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _HeroBanner(store: store),
        const SizedBox(height: 14),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Tìm phim theo tên, thể loại, diễn viên...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Tất cả trạng thái'),
              selected: _status == null,
              onSelected: (_) => setState(() => _status = null),
            ),
            ChoiceChip(
              label: const Text('Đang chiếu'),
              selected: _status == MovieStatus.nowShowing,
              onSelected: (_) =>
                  setState(() => _status = MovieStatus.nowShowing),
            ),
            ChoiceChip(
              label: const Text('Sắp chiếu'),
              selected: _status == MovieStatus.comingSoon,
              onSelected: (_) =>
                  setState(() => _status = MovieStatus.comingSoon),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: store.genres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final genre = store.genres[index];
              return ChoiceChip(
                label: Text(genre),
                selected: genre == _genre,
                onSelected: (_) => setState(() => _genre = genre),
              );
            },
          ),
        ),
        const SectionTitle(title: 'Phim phù hợp với bạn'),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 900
                ? 4
                : width >= 620
                ? 3
                : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movies.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .58,
              ),
              itemBuilder: (context, index) {
                return _MovieCard(
                  movie: movies[index],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MovieDetailScreen(store: store, movie: movies[index]),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.store});

  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    final banner = store.banners.firstWhere((item) => item.active);
    final cinema = store.cinemas.first;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Colors.white, AppColors.platinum, AppColors.goldSoft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    banner.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(banner.message),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.location_on_outlined),
                  label: Text('Gần bạn: ${cinema.name}'),
                ),
                Chip(
                  avatar: const Icon(Icons.map_outlined),
                  label: Text(cinema.address),
                ),
                const Chip(
                  avatar: Icon(Icons.timer_outlined),
                  label: Text('Đặt vé trong <= 5 bước'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie, required this.onTap});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TiltCard(
      onTap: onTap,
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      movie.posterUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => Container(
                        color: Color(movie.heroColor).withValues(alpha: .2),
                        alignment: Alignment.center,
                        child: const Icon(Icons.local_movies_rounded, size: 42),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .88),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            movie.status == MovieStatus.nowShowing
                                ? 'Đang chiếu'
                                : 'Sắp chiếu',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${movie.durationMinutes} phút - ${movie.ageRating} - ${movie.rating}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
