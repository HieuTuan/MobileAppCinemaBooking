import 'package:cached_network_image/cached_network_image.dart';
import 'package:cine_book/core/constants/app_colors.dart';
import 'package:cine_book/features/movie/data/models/movie_model.dart';
import 'package:cine_book/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class MovieCard extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback? onTap;
  final double width;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('${AppRouter.movieDetail}?id=${movie.id}'),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed Aspect Ratio for Image to prevent layout shifts
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) {
                    debugPrint('Image failed to load: $url');
                    return Container(
                      color: Colors.grey[900],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Lỗi tải ảnh',
                            style: TextStyle(color: Colors.white24, fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title with constraints
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            // Bottom Info Row
            Row(
              children: [
                Icon(Icons.star, color: AppColors.secondary, size: 14),
                const SizedBox(width: 4),
                Text(
                  movie.imdbRating?.toString() ?? 'N/A',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                _buildAgeRating(movie.ageRating),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeRating(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rating,
        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
