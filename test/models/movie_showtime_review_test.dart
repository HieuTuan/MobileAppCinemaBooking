import 'package:flutter_test/flutter_test.dart';
import 'package:cine_book/models/movie.dart';
import 'package:cine_book/models/showtime.dart';
import 'package:cine_book/models/review.dart';

void main() {
  group('Movie Model Tests', () {
    test('Movie fromJson and toJson should work correctly', () {
      // Arrange
      final movieJson = {
        'id': 'movie123',
        'title': 'The Matrix',
        'description': 'A computer hacker learns about the true nature of reality.',
        'genres': ['Action', 'Sci-Fi'],
        'durationMinutes': 136,
        'director': 'Wachowski Brothers',
        'cast': ['Keanu Reeves', 'Laurence Fishburne', 'Carrie-Anne Moss'],
        'posterUrl': 'https://example.com/poster.jpg',
        'trailerUrl': 'https://example.com/trailer.mp4',
        'rating': 4.5,
        'ageRating': 'C13',
        'releaseDate': '1999-03-31T00:00:00.000Z',
        'status': 'nowShowing',
      };

      // Act
      final movie = Movie.fromJson(movieJson);
      final movieToJson = movie.toJson();

      // Assert
      expect(movie.id, 'movie123');
      expect(movie.title, 'The Matrix');
      expect(movie.genres, ['Action', 'Sci-Fi']);
      expect(movie.durationMinutes, 136);
      expect(movie.rating, 4.5);
      expect(movie.ageRating, 'C13');
      expect(movie.status, 'nowShowing');
      expect(movie.isNowShowing, true);
      expect(movie.isComingSoon, false);
      expect(movie.minimumAge, 13);
      expect(movie.formattedDuration, '2h 16m');
      expect(movieToJson['id'], 'movie123');
      expect(movieToJson['title'], 'The Matrix');
    });

    test('Movie age rating helpers should work correctly', () {
      // Test P rating
      final movieP = Movie(
        id: '1',
        title: 'Kids Movie',
        description: 'For all ages',
        genres: ['Animation'],
        durationMinutes: 90,
        director: 'Director',
        cast: ['Actor'],
        posterUrl: 'url',
        trailerUrl: 'url',
        rating: 4.0,
        ageRating: 'P',
        releaseDate: DateTime.now(),
        status: 'nowShowing',
      );
      expect(movieP.minimumAge, null);
      expect(movieP.ageRatingDescription, 'All ages');
      expect(movieP.requiresAgeVerification, false);

      // Test T18 rating
      final movieT18 = Movie(
        id: '2',
        title: 'Adult Movie',
        description: 'For adults',
        genres: ['Horror'],
        durationMinutes: 120,
        director: 'Director',
        cast: ['Actor'],
        posterUrl: 'url',
        trailerUrl: 'url',
        rating: 4.0,
        ageRating: 'T18',
        releaseDate: DateTime.now(),
        status: 'nowShowing',
      );
      expect(movieT18.minimumAge, 18);
      expect(movieT18.ageRatingDescription, '18+ (with restrictions)');
      expect(movieT18.requiresAgeVerification, true);
    });
  });

  group('Showtime Model Tests', () {
    test('Showtime fromJson and toJson should work correctly', () {
      // Arrange
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

      // Act
      final showtime = Showtime.fromJson(showtimeJson);
      final showtimeToJson = showtime.toJson();

      // Assert
      expect(showtime.id, 'showtime123');
      expect(showtime.movieId, 'movie123');
      expect(showtime.roomId, 'room123');
      expect(showtime.basePrice, 150000);
      expect(showtime.status, 'scheduled');
      expect(showtime.isScheduled, true);
      expect(showtime.isCancelled, false);
      expect(showtime.roomName, 'Room 1');
      expect(showtime.cinemaName, 'CineLuxe Downtown');
      expect(showtime.fullLocation, 'CineLuxe Downtown - Room 1');
      expect(showtimeToJson['id'], 'showtime123');
      expect(showtimeToJson['basePrice'], 150000);
    });

    test('Showtime formatted price should work correctly', () {
      final showtime = Showtime(
        id: 'showtime123',
        movieId: 'movie123',
        roomId: 'room123',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(Duration(hours: 2)),
        basePrice: 150000,
        status: 'scheduled',
        roomName: 'Room 1',
        cinemaName: 'CineLuxe',
        cinemaAddress: '123 Main St',
      );

      expect(showtime.formattedPrice, '150,000 VND');
    });

    test('Showtime duration calculation should work correctly', () {
      final startTime = DateTime(2024, 1, 15, 19, 30);
      final endTime = DateTime(2024, 1, 15, 21, 46);
      
      final showtime = Showtime(
        id: 'showtime123',
        movieId: 'movie123',
        roomId: 'room123',
        startTime: startTime,
        endTime: endTime,
        basePrice: 150000,
        status: 'scheduled',
        roomName: 'Room 1',
        cinemaName: 'CineLuxe',
        cinemaAddress: '123 Main St',
      );

      expect(showtime.durationMinutes, 136);
    });
  });

  group('Review Model Tests', () {
    test('Review fromJson and toJson should work correctly', () {
      // Arrange
      final reviewJson = {
        'id': 'review123',
        'userId': 'user123',
        'userName': 'John Doe',
        'movieId': 'movie123',
        'rating': 5,
        'comment': 'Excellent movie! Highly recommended.',
        'isVerified': true,
        'createdAt': '2024-01-15T10:30:00.000Z',
      };

      // Act
      final review = Review.fromJson(reviewJson);
      final reviewToJson = review.toJson();

      // Assert
      expect(review.id, 'review123');
      expect(review.userId, 'user123');
      expect(review.userName, 'John Doe');
      expect(review.movieId, 'movie123');
      expect(review.rating, 5);
      expect(review.comment, 'Excellent movie! Highly recommended.');
      expect(review.isVerified, true);
      expect(review.isPositive, true);
      expect(review.isNegative, false);
      expect(review.isNeutral, false);
      expect(review.starEmojis, '⭐⭐⭐⭐⭐');
      expect(reviewToJson['id'], 'review123');
      expect(reviewToJson['rating'], 5);
    });

    test('Review rating classification should work correctly', () {
      final positiveReview = Review(
        id: 'review1',
        userId: 'user1',
        userName: 'User 1',
        movieId: 'movie1',
        rating: 4,
        comment: 'Good movie',
        isVerified: true,
        createdAt: DateTime.now(),
      );
      expect(positiveReview.isPositive, true);
      expect(positiveReview.isNegative, false);
      expect(positiveReview.isNeutral, false);

      final negativeReview = Review(
        id: 'review2',
        userId: 'user2',
        userName: 'User 2',
        movieId: 'movie1',
        rating: 2,
        comment: 'Not good',
        isVerified: true,
        createdAt: DateTime.now(),
      );
      expect(negativeReview.isPositive, false);
      expect(negativeReview.isNegative, true);
      expect(negativeReview.isNeutral, false);

      final neutralReview = Review(
        id: 'review3',
        userId: 'user3',
        userName: 'User 3',
        movieId: 'movie1',
        rating: 3,
        comment: 'Average',
        isVerified: true,
        createdAt: DateTime.now(),
      );
      expect(neutralReview.isPositive, false);
      expect(neutralReview.isNegative, false);
      expect(neutralReview.isNeutral, true);
    });

    test('Review truncatedComment should work correctly', () {
      final review = Review(
        id: 'review1',
        userId: 'user1',
        userName: 'User 1',
        movieId: 'movie1',
        rating: 5,
        comment: 'This is a very long comment that should be truncated when displaying in a limited space',
        isVerified: true,
        createdAt: DateTime.now(),
      );

      expect(review.truncatedComment(20), 'This is a very long ...');
      expect(review.truncatedComment(100), review.comment);
    });
  });
}
