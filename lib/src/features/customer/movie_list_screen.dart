import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../repositories/movie_repository.dart';
import '../../shared/widgets/cache_banner.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';
import '../../utils/connectivity_service.dart';
import 'movie_detail_screen.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, required this.store});

  final CinemaStore store;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final _search = TextEditingController();
  PageController? _featuredController;
  String _genre = '';
  MovieStatus? _status;
  double _featuredPage = 0;

  final MovieRepository _movieRepo = MovieRepository();
  final ConnectivityService _connectivity = ConnectivityService();

  // Cache status (driven by repository + connectivity stream).
  bool _fromCache = false;
  DateTime? _cachedAt;
  StreamSubscription? _changesSub;
  StreamSubscription? _connectivitySub;

  PageController get _carouselController {
    return _featuredController ??= PageController(viewportFraction: .66)
      ..addListener(() {
        final nextPage = _featuredController?.page ?? 0;
        if ((nextPage - _featuredPage).abs() > .001) {
          setState(() => _featuredPage = nextPage);
        }
      });
  }

  @override
  void initState() {
    super.initState();
    _movieRepo.startAutoSync();
    _changesSub = _movieRepo.changes.listen((_) {
      if (!mounted) return;
      setState(() {
        _fromCache = false;
        _cachedAt = DateTime.now();
      });
    });
    _connectivitySub = _connectivity.connectivityStream.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _changesSub?.cancel();
    _connectivitySub?.cancel();
    _search.dispose();
    _featuredController?.dispose();
    super.dispose();
  }

  Future<void> _pullRefresh() async {
    final result = await _movieRepo.getMovies(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _fromCache = result.fromCache;
      _cachedAt = result.cachedAt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final selectedGenre = _genre.isEmpty ? store.genres.first : _genre;
    final movies = store.searchMovies(_search.text, selectedGenre, _status);
    return RefreshIndicator(
      onRefresh: _pullRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          CacheBanner(
            fromCache: _fromCache || !_connectivity.isOnline,
            cachedAt: _cachedAt,
          ),
          _FeaturedMovieCarousel(
            movies: store.movies,
            controller: _carouselController,
            page: _featuredPage,
            onMovieTap: (movie) => _openMovie(store, movie),
          ),
          const SizedBox(height: 14),
          _HeroBanner(store: store),
          const SizedBox(height: 14),
          _MovieFilterBar(
            search: _search,
            genres: store.genres,
            selectedGenre: selectedGenre,
            selectedStatus: _status,
            onSearchChanged: (_) => setState(() {}),
            onStatusChanged: (status) => setState(() => _status = status),
            onGenreChanged: (genre) => setState(() => _genre = genre),
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
                    onTap: () => _openMovie(store, movies[index]),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _openMovie(CinemaStore store, Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(store: store, movie: movie),
      ),
    );
  }
}

class _MovieFilterBar extends StatelessWidget {
  const _MovieFilterBar({
    required this.search,
    required this.genres,
    required this.selectedGenre,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onGenreChanged,
  });

  final TextEditingController search;
  final List<String> genres;
  final String selectedGenre;
  final MovieStatus? selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<MovieStatus?> onStatusChanged;
  final ValueChanged<String> onGenreChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .74),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: softShadow(.05),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 52,
              child: TextField(
                controller: search,
                onChanged: onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Tìm phim, thể loại, diễn viên...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          onPressed: () {
                            search.clear();
                            onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: AppColors.pearl.withValues(alpha: .72),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.gold,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _StatusSegmentedFilter(
              selectedStatus: selectedStatus,
              onChanged: onStatusChanged,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: genres.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  final label = index == 0 ? 'Tất cả' : genre;
                  return _GenrePill(
                    label: label,
                    selected: genre == selectedGenre,
                    onTap: () => onGenreChanged(genre),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSegmentedFilter extends StatelessWidget {
  const _StatusSegmentedFilter({
    required this.selectedStatus,
    required this.onChanged,
  });

  final MovieStatus? selectedStatus;
  final ValueChanged<MovieStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pearl,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _StatusSegment(
              label: 'Tất cả',
              icon: Icons.grid_view_rounded,
              selected: selectedStatus == null,
              onTap: () => onChanged(null),
            ),
            _StatusSegment(
              label: 'Đang chiếu',
              icon: Icons.play_circle_outline_rounded,
              selected: selectedStatus == MovieStatus.nowShowing,
              onTap: () => onChanged(MovieStatus.nowShowing),
            ),
            _StatusSegment(
              label: 'Sắp chiếu',
              icon: Icons.event_available_rounded,
              selected: selectedStatus == MovieStatus.comingSoon,
              onTap: () => onChanged(MovieStatus.comingSoon),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSegment extends StatelessWidget {
  const _StatusSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected ? softShadow(.04) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? AppColors.gold : AppColors.muted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.ink : AppColors.muted,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
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

class _GenrePill extends StatelessWidget {
  const _GenrePill({
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
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.gold.withValues(alpha: .72)
                : AppColors.line,
          ),
          boxShadow: selected ? softShadow(.08) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? AppColors.gold : AppColors.pearl,
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? Icons.check_rounded : Icons.local_movies_outlined,
                size: 13,
                color: selected ? Colors.white : AppColors.muted,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedMovieCarousel extends StatelessWidget {
  const _FeaturedMovieCarousel({
    required this.movies,
    required this.controller,
    required this.page,
    required this.onMovieTap,
  });

  final List<Movie> movies;
  final PageController controller;
  final double page;
  final ValueChanged<Movie> onMovieTap;

  @override
  Widget build(BuildContext context) {
    final featuredMovies = movies.take(5).toList();
    if (featuredMovies.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth >= 700 ? 440.0 : 360.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Phim nổi bật'),
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: controller,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                itemCount: featuredMovies.length,
                itemBuilder: (context, index) {
                  final distance = (page - index).abs().clamp(0.0, 1.0);
                  final scale = 1 - distance * .12;
                  final verticalInset = 22 + distance * 26;
                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.fromLTRB(8, verticalInset, 8, 8),
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topCenter,
                      child: _FeaturedMovieCard(
                        movie: featuredMovies[index],
                        active: distance < .35,
                        onTap: () => onMovieTap(featuredMovies[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeaturedMovieCard extends StatelessWidget {
  const _FeaturedMovieCard({
    required this.movie,
    required this.active,
    required this.onTap,
  });

  final Movie movie;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TiltCard(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? AppColors.gold.withValues(alpha: .55)
                : AppColors.line,
          ),
          boxShadow: softShadow(active ? .16 : .07),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
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
                        color: Color(movie.heroColor).withValues(alpha: .24),
                        alignment: Alignment.center,
                        child: const Icon(Icons.local_movies_rounded, size: 52),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.ink.withValues(alpha: .04),
                              AppColors.ink.withValues(alpha: .72),
                            ],
                            stops: const [.45, .68, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _AgeBadge(label: movie.ageRating),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.deepOrange,
                                size: 16,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                movie.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  children: [
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.genres.take(2).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
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

class _AgeBadge extends StatelessWidget {
  const _AgeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
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
