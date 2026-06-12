# Movie, Showtime, and Review Models

This document provides usage examples for the Movie, Showtime, and Review data models with JSON serialization support.

## Requirements Coverage

These models satisfy the following requirements from the Cinema Booking API Integration specification:

- **Requirement 3.1**: Movie search and filtering API
- **Requirement 3.7**: Complete movie, showtime, and review data fields

## Models Overview

### Movie Model (`lib/models/movie.dart`)

Represents a film available for booking with complete metadata including genres, cast, ratings, and age restrictions.

**Key Fields:**
- `id`, `title`, `description`
- `genres` (List<String>)
- `durationMinutes`
- `director`, `cast` (List<String>)
- `posterUrl`, `trailerUrl`
- `rating` (0.0-5.0)
- `ageRating` (P, C13, C16, C18, T18)
- `releaseDate`, `status` (nowShowing, comingSoon)

**Convenience Methods:**
- `isNowShowing`, `isComingSoon`
- `requiresAgeVerification` (returns true for T18 movies)
- `minimumAge` (returns null for P, 13 for C13, etc.)
- `ageRatingDescription` (returns "All ages", "13+", etc.)
- `formattedDuration` (returns "2h 30m")
- `genresString`, `castString` (comma-separated lists)

### Showtime Model (`lib/models/showtime.dart`)

Represents a specific screening of a movie at a particular cinema and room.

**Key Fields:**
- `id`, `movieId`, `roomId`
- `startTime`, `endTime`
- `basePrice` (VND)
- `status` (scheduled, cancelled)
- `roomName`, `cinemaName`, `cinemaAddress`

**Convenience Methods:**
- `isScheduled`, `isCancelled`
- `hasStarted`, `hasEnded`, `isPlaying`
- `durationMinutes` (calculated from startTime and endTime)
- `timeUntilStart` (Duration or null if already started)
- `formattedStartTime` (returns "14:30")
- `formattedDate` (returns "Mon, Dec 25")
- `formattedPrice` (returns "150,000 VND")
- `fullLocation` (returns "CineLuxe Downtown - Room 1")

### Review Model (`lib/models/review.dart`)

Represents a customer's movie review with verification status.

**Key Fields:**
- `id`, `userId`, `userName`, `movieId`
- `rating` (1-5)
- `comment`
- `isVerified` (true if user has watched the movie)
- `createdAt`

**Convenience Methods:**
- `isPositive` (rating >= 4)
- `isNegative` (rating <= 2)
- `isNeutral` (rating == 3)
- `starEmojis` (returns "⭐⭐⭐⭐⭐")
- `formattedDate` (returns "Dec 25, 2023")
- `relativeTime` (returns "2 days ago", "1 week ago", etc.)
- `truncatedComment(int maxLength)` (truncates with ellipsis)

## Usage Examples

### Working with Movie

```dart
import 'package:cine_book/models/movie.dart';

// Deserialize from API JSON response
final movieJson = {
  'id': 'movie123',
  'title': 'The Matrix',
  'description': 'A computer hacker learns about the true nature of reality.',
  'genres': ['Action', 'Sci-Fi'],
  'durationMinutes': 136,
  'director': 'Wachowski Brothers',
  'cast': ['Keanu Reeves', 'Laurence Fishburne'],
  'posterUrl': 'https://example.com/poster.jpg',
  'trailerUrl': 'https://example.com/trailer.mp4',
  'rating': 4.5,
  'ageRating': 'C13',
  'releaseDate': '1999-03-31T00:00:00.000Z',
  'status': 'nowShowing',
};

final movie = Movie.fromJson(movieJson);

// Access movie data
print('${movie.title} - ${movie.formattedDuration}');
// Output: "The Matrix - 2h 16m"

print('Rating: ${movie.rating}/5 - ${movie.ageRatingDescription}');
// Output: "Rating: 4.5/5 - 13+"

print('Genres: ${movie.genresString}');
// Output: "Genres: Action, Sci-Fi"

// Check age restrictions
if (movie.requiresAgeVerification) {
  print('Age verification required!');
}

// Serialize back to JSON
final jsonOutput = movie.toJson();
```

### Working with Showtime

```dart
import 'package:cine_book/models/showtime.dart';

// Deserialize from API JSON response
final showtimeJson = {
  'id': 'showtime123',
  'movieId': 'movie123',
  'roomId': 'room123',
  'startTime': '2024-01-15T19:30:00.000Z',
  'endTime': '2024-01-15T21:46:00.000Z',
  'basePrice': 150000,
  'status': 'scheduled',
  'roomName': 'Room 1',
  'cinemaName': 'CineLuxe Downtown',
  'cinemaAddress': '123 Main St, City',
};

final showtime = Showtime.fromJson(showtimeJson);

// Display showtime information
print('${showtime.formattedDate} at ${showtime.formattedStartTime}');
// Output: "Mon, Jan 15 at 19:30"

print('Location: ${showtime.fullLocation}');
// Output: "Location: CineLuxe Downtown - Room 1"

print('Price: ${showtime.formattedPrice}');
// Output: "Price: 150,000 VND"

// Check showtime status
if (showtime.isScheduled && !showtime.hasStarted) {
  final timeUntil = showtime.timeUntilStart;
  if (timeUntil != null) {
    print('Starts in ${timeUntil.inHours} hours');
  }
}

// Serialize back to JSON
final jsonOutput = showtime.toJson();
```

### Working with Review

```dart
import 'package:cine_book/models/review.dart';

// Deserialize from API JSON response
final reviewJson = {
  'id': 'review123',
  'userId': 'user123',
  'userName': 'John Doe',
  'movieId': 'movie123',
  'rating': 5,
  'comment': 'Excellent movie! Highly recommended. The action scenes were amazing.',
  'isVerified': true,
  'createdAt': '2024-01-15T10:30:00.000Z',
};

final review = Review.fromJson(reviewJson);

// Display review information
print('${review.userName} ${review.starEmojis}');
// Output: "John Doe ⭐⭐⭐⭐⭐"

print('${review.relativeTime}${review.isVerified ? ' • Verified' : ''}');
// Output: "2 days ago • Verified"

print(review.truncatedComment(50));
// Output: "Excellent movie! Highly recommended. The action..."

// Check review sentiment
if (review.isPositive) {
  print('Positive review!');
} else if (review.isNegative) {
  print('Negative review');
} else {
  print('Neutral review');
}

// Serialize back to JSON
final jsonOutput = review.toJson();
```

### Using in API Client

```dart
import 'package:dio/dio.dart';
import 'package:cine_book/models/movie.dart';
import 'package:cine_book/models/showtime.dart';
import 'package:cine_book/models/review.dart';

class MoviesApiClient {
  final Dio dio;
  
  MoviesApiClient(this.dio);
  
  /// Get movies with optional filters
  Future<List<Movie>> getMovies({
    String? search,
    String? genre,
    String? status,
  }) async {
    final response = await dio.get('/api/movies', queryParameters: {
      if (search != null) 'search': search,
      if (genre != null) 'genre': genre,
      if (status != null) 'status': status,
    });
    
    final List<dynamic> moviesJson = response.data['movies'];
    return moviesJson.map((json) => Movie.fromJson(json)).toList();
  }
  
  /// Get showtimes for a movie
  Future<List<Showtime>> getShowtimes(String movieId, {DateTime? date}) async {
    final response = await dio.get('/api/movies/$movieId/showtimes', 
      queryParameters: {
        if (date != null) 'date': date.toIso8601String(),
      }
    );
    
    final List<dynamic> showtimesJson = response.data['showtimes'];
    return showtimesJson.map((json) => Showtime.fromJson(json)).toList();
  }
  
  /// Get reviews for a movie
  Future<List<Review>> getReviews(String movieId, {int page = 1}) async {
    final response = await dio.get('/api/movies/$movieId/reviews',
      queryParameters: {'page': page}
    );
    
    final List<dynamic> reviewsJson = response.data['reviews'];
    return reviewsJson.map((json) => Review.fromJson(json)).toList();
  }
  
  /// Create a review
  Future<Review> createReview({
    required String movieId,
    required int rating,
    required String comment,
  }) async {
    final response = await dio.post('/api/reviews', data: {
      'movieId': movieId,
      'rating': rating,
      'comment': comment,
    });
    
    return Review.fromJson(response.data);
  }
}
```

### Using with State Management

```dart
import 'package:flutter/material.dart';
import 'package:cine_book/models/movie.dart';
import 'package:cine_book/models/showtime.dart';

class MovieDetailsScreen extends StatefulWidget {
  final String movieId;
  
  const MovieDetailsScreen({required this.movieId});
  
  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  Movie? movie;
  List<Showtime> showtimes = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadMovieData();
  }
  
  Future<void> _loadMovieData() async {
    // Load movie and showtimes from API
    // final movieData = await apiClient.getMovieDetails(widget.movieId);
    // final showtimesData = await apiClient.getShowtimes(widget.movieId);
    
    setState(() {
      // movie = movieData;
      // showtimes = showtimesData;
      isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: Text(movie?.title ?? '')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie poster
            Image.network(movie?.posterUrl ?? ''),
            
            // Movie info
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie?.title ?? '', style: Theme.of(context).textTheme.headlineMedium),
                  SizedBox(height: 8),
                  Text('${movie?.formattedDuration} • ${movie?.genresString}'),
                  Text('Rating: ${movie?.rating}/5 • ${movie?.ageRatingDescription}'),
                  SizedBox(height: 16),
                  Text(movie?.description ?? ''),
                  SizedBox(height: 24),
                  Text('Showtimes', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  ...showtimes.map((showtime) => ListTile(
                    title: Text(showtime.formattedStartTime),
                    subtitle: Text('${showtime.fullLocation} • ${showtime.formattedPrice}'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to seat selection
                    },
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Testing

Comprehensive unit tests are available in `test/models/movie_showtime_review_test.dart`:

```bash
# Run all model tests
flutter test test/models/movie_showtime_review_test.dart

# Run specific test group
flutter test test/models/movie_showtime_review_test.dart --name "Movie Model Tests"
```

## Code Generation

These models use `json_serializable` for automatic JSON serialization code generation. If you modify the models, regenerate the `.g.dart` files:

```bash
# Generate once
flutter pub run build_runner build

# Watch for changes and regenerate automatically
flutter pub run build_runner watch

# Clean and regenerate
flutter pub run build_runner build --delete-conflicting-outputs
```

## Related Files

- Model definitions: `lib/models/movie.dart`, `lib/models/showtime.dart`, `lib/models/review.dart`
- Generated code: `lib/models/movie.g.dart`, `lib/models/showtime.g.dart`, `lib/models/review.g.dart`
- Unit tests: `test/models/movie_showtime_review_test.dart`
- API Client: `lib/api/api_client.dart` (for integration examples)

## Next Steps

After implementing these models, you can:

1. Integrate them into the API Client (`lib/api/api_client.dart`)
2. Use them in state management stores
3. Display them in UI components
4. Cache them for offline access using `lib/cache/` module
5. Implement real-time updates via WebSocket for showtimes

For more information, see:
- Design Document: `.kiro/specs/cinema-booking-api-integration/design.md`
- Requirements: `.kiro/specs/cinema-booking-api-integration/requirements.md`
