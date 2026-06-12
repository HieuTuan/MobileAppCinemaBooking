import 'package:json_annotation/json_annotation.dart';

part 'movie.g.dart';

/// Movie model representing a film available for booking.
/// 
/// **Requirements Coverage:**
/// - Requirement 3.1: Movie search and filtering with complete movie data
/// - Requirement 3.7: Movie fields including id, title, description, genres, duration, 
///   director, cast, poster, trailer, rating, age rating, release date, and status
/// 
/// Usage:
/// ```dart
/// // From JSON
/// final movie = Movie.fromJson(jsonMap);
/// 
/// // Access movie data
/// print('${movie.title} - ${movie.durationMinutes} min');
/// print('Age rating: ${movie.ageRating}');
/// ```
@JsonSerializable()
class Movie {
  /// Unique movie identifier
  final String id;
  
  /// Movie title
  final String title;
  
  /// Movie description/synopsis
  final String description;
  
  /// List of genres (e.g., ["Action", "Thriller"])
  final List<String> genres;
  
  /// Duration in minutes
  final int durationMinutes;
  
  /// Director name
  final String director;
  
  /// List of main cast members
  final List<String> cast;
  
  /// URL to movie poster image
  final String posterUrl;
  
  /// URL to movie trailer video
  final String trailerUrl;
  
  /// Average rating from reviews (0.0 to 5.0)
  final double rating;
  
  /// Age rating classification (P, C13, C16, C18, T18)
  final String ageRating;
  
  /// Movie release date
  final DateTime releaseDate;
  
  /// Movie status (nowShowing, comingSoon)
  final String status;
  
  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.genres,
    required this.durationMinutes,
    required this.director,
    required this.cast,
    required this.posterUrl,
    required this.trailerUrl,
    required this.rating,
    required this.ageRating,
    required this.releaseDate,
    required this.status,
  });
  
  /// Creates an instance from JSON map
  factory Movie.fromJson(Map<String, dynamic> json) =>
      _$MovieFromJson(json);
  
  /// Converts instance to JSON map
  Map<String, dynamic> toJson() => _$MovieToJson(this);
  
  /// Checks if movie is currently showing
  bool get isNowShowing => status == 'nowShowing';
  
  /// Checks if movie is coming soon
  bool get isComingSoon => status == 'comingSoon';
  
  /// Checks if movie requires age verification (T18 rating)
  bool get requiresAgeVerification => ageRating == 'T18';
  
  /// Returns minimum age required to watch (null if P rating)
  int? get minimumAge {
    switch (ageRating) {
      case 'P':
        return null; // All ages
      case 'C13':
        return 13;
      case 'C16':
        return 16;
      case 'C18':
      case 'T18':
        return 18;
      default:
        return null;
    }
  }
  
  /// Returns human-readable age rating description
  String get ageRatingDescription {
    switch (ageRating) {
      case 'P':
        return 'All ages';
      case 'C13':
        return '13+';
      case 'C16':
        return '16+';
      case 'C18':
        return '18+';
      case 'T18':
        return '18+ (with restrictions)';
      default:
        return ageRating;
    }
  }
  
  /// Returns formatted duration (e.g., "2h 30m")
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
  
  /// Returns comma-separated genres string
  String get genresString => genres.join(', ');
  
  /// Returns comma-separated cast string
  String get castString => cast.join(', ');
}
