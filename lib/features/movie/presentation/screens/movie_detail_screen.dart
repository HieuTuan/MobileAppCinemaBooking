import 'package:cached_network_image/cached_network_image.dart';
import 'package:cine_book/core/constants/app_colors.dart';
import 'package:cine_book/core/utils/injection.dart';
import 'package:cine_book/features/movie/data/models/movie_model.dart';
import 'package:cine_book/features/movie/domain/repositories/movie_repository.dart';
import 'package:cine_book/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MovieDetailScreen extends StatefulWidget {
  final String movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Future<MovieModel> _movieFuture;

  @override
  void initState() {
    super.initState();
    _movieFuture = getIt<MovieRepository>().getMovieDetails(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: FutureBuilder<MovieModel>(
        future: _movieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Không tìm thấy phim', style: TextStyle(color: Colors.white)));
          }

          final movie = snapshot.data!;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 400,
                    pinned: true,
                    leading: const SizedBox.shrink(), // Custom back button used below
                    backgroundColor: AppColors.backgroundDark,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: movie.posterUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.broken_image, color: Colors.white24, size: 80),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.backgroundDark.withValues(alpha: 0.8),
                                  AppColors.backgroundDark,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    movie.genre.join(' • '),
                                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            _buildAgeRating(movie.ageRating),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildInfoItem(Icons.star, AppColors.secondary, '${movie.imdbRating} IMDB'),
                            const SizedBox(width: 24),
                            _buildInfoItem(Icons.access_time, Colors.grey, '${movie.durationMinutes} phút'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Nội dung phim',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.description,
                          style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 120), // Bottom padding for FAB
                      ]),
                    ),
                  ),
                ],
              ),
              // Floating Back Button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.push('${AppRouter.showtime}?movieId=${widget.movieId}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 8,
          ),
          child: const Text(
            'MUA VÉ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeRating(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rating,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}
