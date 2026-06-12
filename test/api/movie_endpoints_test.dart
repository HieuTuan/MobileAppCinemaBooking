import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:cine_book/api/api_client.dart';
import 'package:cine_book/models/movie.dart';
import 'package:cine_book/models/review.dart';
import 'package:cine_book/models/paginated_response.dart';

/// Unit tests for movie search and filtering endpoints.
/// 
/// **Requirements Coverage:**
/// - Requirement 3.1: Movie search and filtering with complete movie data
/// - Requirement 3.2: Search matches against title, director, cast members, and genres
/// - Requirement 3.3: Genre filter returns only movies containing that genre
/// - Requirement 3.4: Status filter for "nowShowing" movies
/// - Requirement 3.5: Status filter for "comingSoon" movies
/// - Requirement 3.6: Returns all active movies sorted by releaseDate descending
/// - Requirement 3.8: Pagination support with default page 1 and pageSize 20
void main() {
  late APIClient apiClient;
  late DioAdapter dioAdapter;

  setUp(() {
    apiClient = APIClient();
    dioAdapter = DioAdapter(
      dio: apiClient.dio,
      matcher: const UrlRequestMatcher(),
    );
  });

  group('getMovies - Basic Functionality', () {
    test('should fetch movies without filters and use default pagination', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 'movie-1',
            'title': 'Test Movie 1',
            'description': 'A test movie',
            'genres': ['Action', 'Thriller'],
            'durationMinutes': 120,
            'director': 'Director Name',
            'cast': ['Actor 1', 'Actor 2'],
            'posterUrl': 'https://example.com/poster1.jpg',
            'trailerUrl': 'https://example.com/trailer1.mp4',
            'rating': 4.5,
            'ageRating': 'C13',
            'releaseDate': '2024-01-01T00:00:00.000Z',
            'status': 'nowShowing',
          },
          {
            'id': 'movie-2',
            'title': 'Test Movie 2',
            'description': 'Another test movie',
            'genres': ['Comedy', 'Drama'],
            'durationMinutes': 105,
            'director': 'Another Director',
            'cast': ['Actor 3', 'Actor 4'],
            'posterUrl': 'https://example.com/poster2.jpg',
            'trailerUrl': 'https://example.com/trailer2.mp4',
            'rating': 3.8,
            'ageRating': 'P',
            'releaseDate': '2024-02-01T00:00:00.000Z',
            'status': 'nowShowing',
          },
        ],
        'page': 1,
        'pageSize': 20,
        'totalItems': 2,
        'totalPages': 1,
        'hasNext': false,
        'hasPrevious': false,
      };

      dioAdapter.onGet(
        '/api/movies',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 1, 'pageSize': 20},
      );

      // Act
      final result = await apiClient.getMovies();

      // Assert
      expect(result.data.length, 2);
      expect(result.page, 1);
      expect(result.pageSize, 20);
      expect(result.totalItems, 2);
      expect(result.totalPages, 1);
      expect(result.hasNext, false);
      expect(result.hasPrevious, false);
      expect(result.data[0].title, 'Test Movie 1');
      expect(result.data[1].title, 'Test Movie 2');
    });

    test('should fetch movies with custom pagination parameters', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 'movie-3',
            'title': 'Test Movie 3',
            'description': 'Third test movie',
            'genres': ['Horror'],
            'durationMinutes': 95,
            'director': 'Horror Director',
            'cast': ['Actor 5'],
            'posterUrl': 'https://example.com/poster3.jpg',
            'trailerUrl': 'https://example.com/trailer3.mp4',
            'rating': 4.0,
            'ageRating': 'C18',
            'releaseDate': '2024-03-01T00:00:00.000Z',
            'status': 'nowShowing',
          },
        ],
        'page': 2,
        'pageSize': 10,
        'totalItems': 25,
        'totalPages': 3,
        'hasNext': true,
        'hasPrevious': true,
      };

      dioAdapter.onGet(
        '/api/movies',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 2, 'pageSize': 10},
      );

      // Act
      final result = await apiClient.getMovies(page: 2, pageSize: 10);

      // Assert
      expect(result.page, 2);
      expect(result.pageSize, 10);
      expect(result.totalItems, 25);
      expect(result.totalPages, 3);
      expect(result.hasNext, true);
      expect(result.hasPrevious, true);
      expect(result.data.length, 1);
    });
  });

  group('getMovies - Search Filter (Requirement 3.2)', () {
    test('should filter movies by search text', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 'movie-avengers',
            'title': 'Avengers: Endgame',
            'description': 'Superhero movie',
            'genres': ['Action', 'Adventure'],
            'durationMinutes': 180,
            'director': 'Russo Brothers',
            'cast': ['Robert Downey Jr.', 'Chris Evans'],
            'posterUrl': 'https://example.com/avengers.jpg',
            'trailerUrl': 'https://example.com/avengers.mp4',
            'rating': 4.8,
            'ageRating': 'C13',
            'releaseDate': '2019-04-26T00:00:00.000Z',
            'status': 'nowShowing',
          },
        ],
        'page': 1,
        'pageSize': 20,
        'totalItems': 1,
        'totalPages': 1,
        'hasNext': false,
        'hasPrevious': false,
      };

      dioAdapter.onGet(
        '/api/movies',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 1, 'pageSize': 20, 'search': 'avengers'},
      );

      // Act
      final result = await apiClient.getMovies(search: 'avengers');

      // Assert
      expect(result.data.length, 1);
      expect(result.data[0].title, 'Avengers: Endgame');
      expect(result.data[0].director, 'Russo Brothers');
    });

    test('should handle empty search results', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'page': 1,
        'pageSize': 20,
        'totalItems': 0,
        'totalPages': 0,
        'hasNext': false,
        'hasPrevious': false,
      };

      dioAdapter.onGet(
        '/api/movies',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 1, 'pageSize': 20, 'search': 'nonexistent'},
      );

      // Act
      final result = await apiClient.getMovies(search: 'nonexistent');

      // Assert
      expect(result.data.length, 0);
      expect(result.totalItems, 0);
    });
  });

  group('getMovies - Genre Filter (Requirement 3.3)', () {
    test('should filter movies by genre', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 'movie-action1',
            'title': 'Action Movie 1',
            'description': 'An action movie',
            'genres': ['Action', 'Thriller'],
            'durationMinutes': 120,
            'director': 'Action Director',
            'cast': ['Action Star'],
            'posterUrl': 'https://example.com/action1.jpg',
            'trailerUrl': 'https://example.com/action1.mp4',
            'rating': 4.2,
            'ageRating': 'C16',
            'releaseDate': '2024-01-15T00:00:00.000Z',
            'status': 'nowShowing',
          },
          {
            'id': 'movie-action2',
            'title': 'Action Movie 2',
            'description': 'Another action movie',
            'genres': ['Action', 'Adventure'],
            'durationMinutes': 135,
            'director': 'Another Action Director',
            'cast': ['Action Hero'],
            'posterUrl': 'https://example.com/action2.jpg',
            'trailerUrl': 'https://example.com/action2.mp4',
            'rating': 4.5,
            'ageRating': 'C13',
            'releaseDate': '2024-02-20T00:00:00.000Z',
            'status': 'nowShowing',
          },
        ],
        'page': 1,
        'pageSize': 20,
        'totalItems': 2,
        'totalPages': 1,
        'hasNext': false,
        'hasPrevious': false,
      };

      dioAdapter.onGet(
        '/api/movies',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 1, 'pageSize': 20, 'genre': 'Action'},
      );

      // Act
      final result = await apiClient.getMovies(genre: 'Action');

      // Assert
      expect(result.data.length, 2);
      expect(result.data[0].genres, contains('Action'));
      expect(result.data[1].genres, contains('Action'));
    });
  });

  group('getMovies - Status Filter (Requirements 3.4, 3.5)', () {
    test('should filter movies by nowShowing status', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 'movie-showing1',
            'title': 'Now Showing Movie',
            'description': 'Currently in theaters',
            'genres': ['Drama'],
            'durationMinutes': 110,
            'director': 'Drama Director',
            'cast': ['Drama Actor'],
            'posterUrl': 'https://example.com/showing.jpg',
            'trailerUrl': 'https://example.com/showing.mp4',
            'rating': 4.1,
            'ageRating': 'P',
            'releaseDate': '2024-01-01T00:00:00.000Z',
            'status': 'nowShowing',
          },
        ],
        'page': 1,
        'pageSize': 20,
        'totalItems': 1,
        'totalPages': 1,
        'hasNext': false,
        'hasPrevious': false,
      };

      dioAdapter.onGet(
        '/api/movies',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 1, 'pageSize': 20, 'status': 'nowShowing'},
      );

      // Act
      final result = await apiClient.getMovies(status: 'nowShowing');

      // Assert
      expect(result.data.length, 1);
      expect(result.data[0].status, 'nowShowing');
      expect(result.data[0].isNowShowing, true);
    });

    test('should filter movies by comingSoon status', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 'movie-coming1',
            'title': 'Coming Soon Movie',
            'description': 'Upcoming release',
            'genres': ['Sci-Fi'],
            'durationMinutes': 145,
            'director': 'Sci-Fi Director',
            'cast': ['Sci-Fi Star'],
            'posterUrl': 'https://example.com/coming.jpg',
            'trailerUrl': 'https://example.com/coming.mp4',
            'rating': 0.0,
            'ageRating': 'C13',
            'releaseDate': '2024-12-25T00:00:00.000Z',
            'status': 'comingSoon',
          },
        ],
        'page': 1,
        'pageSize': 20,
        'totalItems': 1,
        'totalPages': 1,
        'hasNext': false,
        'hasPrevious': false,
      };

      dioAdapter.onGet(
        '/api/movies',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 1, 'pageSize': 20, 'status': 'comingSoon'},
      );

      // Act
      final result = await apiClient.getMovies(status: 'comingSoon');

      // Assert
      expect(result.data.length, 1);
      expect(result.data[0].status, 'comingSoon');
      expect(result.data[0].isComingSoon, true);
    });
  });

  group('getMovies - Combined Filters', () {
    test('should apply multiple filters simultaneously', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 'movie-filtered',
            'title': 'Filtered Movie',
            'description': 'Matches all filters',
            'genres': ['Action', 'Thriller'],
            'durationMinutes': 125,
            'director': 'Filter Director',
            'cast': ['Filter Actor'],
            'posterUrl': 'https://example.com/filtered.jpg',
            'trailerUrl': 'https://example.com/filtered.mp4',
            'rating': 4.3,
            'ageRating': 'C16',
            'releaseDate': '2024-03-01T00:00:00.000Z',
            'status': 'nowShowing',
          },
        ],
        'page': 1,
        'pageSize': 20,
        'totalItems': 1,
        'totalPages': 1,
        'hasNext': false,
        'hasPrevious': false,
      };

      dioAdapter.onGet(
        '/api/movies',
        (server) => server.reply(200, mockResponse),
        queryParameters: {
          'page': 1,
          'pageSize': 20,
          'search': 'filtered',
          'genre': 'Action',
          'status': 'nowShowing',
        },
      );

      // Act
      final result = await apiClient.getMovies(
        search: 'filtered',
        genre: 'Action',
        status: 'nowShowing',
      );

      // Assert
      expect(result.data.length, 1);
      expect(result.data[0].title, 'Filtered Movie');
      expect(result.data[0].genres, contains('Action'));
      expect(result.data[0].status, 'nowShowing');
    });
  });

  group('getMovieDetails - Movie Detail Retrieval (Requirement 3.1)', () {
    test('should fetch complete movie details by ID', () async {
      // Arrange
      final mockMovie = {
        'id': 'movie-detail-1',
        'title': 'Detailed Movie',
        'description': 'A movie with full details',
        'genres': ['Action', 'Drama', 'Thriller'],
        'durationMinutes': 155,
        'director': 'Christopher Nolan',
        'cast': ['Actor A', 'Actor B', 'Actor C'],
        'posterUrl': 'https://example.com/detailed-poster.jpg',
        'trailerUrl': 'https://example.com/detailed-trailer.mp4',
        'rating': 4.7,
        'ageRating': 'C13',
        'releaseDate': '2024-06-15T00:00:00.000Z',
        'status': 'nowShowing',
      };

      dioAdapter.onGet(
        '/api/movies/movie-detail-1',
        (server) => server.reply(200, mockMovie),
      );

      // Act
      final result = await apiClient.getMovieDetails('movie-detail-1');

      // Assert
      expect(result.id, 'movie-detail-1');
      expect(result.title, 'Detailed Movie');
      expect(result.description, 'A movie with full details');
      expect(result.genres.length, 3);
      expect(result.durationMinutes, 155);
      expect(result.director, 'Christopher Nolan');
      expect(result.cast.length, 3);
      expect(result.rating, 4.7);
      expect(result.ageRating, 'C13');
      expect(result.status, 'nowShowing');
    });

    test('should handle 404 when movie not found', () async {
      // Arrange
      dioAdapter.onGet(
        '/api/movies/nonexistent-movie',
        (server) => server.reply(404, {
          'code': 'NOT_FOUND',
          'message': 'Movie not found',
          'timestamp': DateTime.now().toIso8601String(),
          'path': '/api/movies/nonexistent-movie',
        }),
      );

      // Act & Assert
      expect(
        () => apiClient.getMovieDetails('nonexistent-movie'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('getMovieReviews - Movie Reviews with Pagination (Requirements 3.1, 3.8)', () {
    test('should fetch movie reviews with default pagination', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 'review-1',
            'userId': 'user-1',
            'userName': 'John Doe',
            'movieId': 'movie-1',
            'rating': 5,
            'comment': 'Excellent movie! Highly recommended.',
            'isVerified': true,
            'createdAt': '2024-01-15T10:30:00.000Z',
          },
          {
            'id': 'review-2',
            'userId': 'user-2',
            'userName': 'Jane Smith',
            'movieId': 'movie-1',
            'rating': 4,
            'comment': 'Great movie, enjoyed it a lot.',
            'isVerified': true,
            'createdAt': '2024-01-14T15:20:00.000Z',
          },
        ],
        'page': 1,
        'pageSize': 20,
        'totalItems': 2,
        'totalPages': 1,
        'hasNext': false,
        'hasPrevious': false,
      };

      dioAdapter.onGet(
        '/api/movies/movie-1/reviews',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 1, 'pageSize': 20},
      );

      // Act
      final result = await apiClient.getMovieReviews('movie-1');

      // Assert
      expect(result.data.length, 2);
      expect(result.page, 1);
      expect(result.pageSize, 20);
      expect(result.data[0].userName, 'John Doe');
      expect(result.data[0].rating, 5);
      expect(result.data[0].isVerified, true);
      expect(result.data[1].userName, 'Jane Smith');
      expect(result.data[1].rating, 4);
    });

    test('should fetch movie reviews with custom pagination', () async {
      // Arrange
      final mockResponse = {
        'data': [
          {
            'id': 'review-11',
            'userId': 'user-11',
            'userName': 'Bob Johnson',
            'movieId': 'movie-2',
            'rating': 3,
            'comment': 'It was okay, not bad but not great.',
            'isVerified': false,
            'createdAt': '2024-02-01T12:00:00.000Z',
          },
        ],
        'page': 2,
        'pageSize': 10,
        'totalItems': 15,
        'totalPages': 2,
        'hasNext': false,
        'hasPrevious': true,
      };

      dioAdapter.onGet(
        '/api/movies/movie-2/reviews',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 2, 'pageSize': 10},
      );

      // Act
      final result = await apiClient.getMovieReviews('movie-2', page: 2, pageSize: 10);

      // Assert
      expect(result.data.length, 1);
      expect(result.page, 2);
      expect(result.pageSize, 10);
      expect(result.totalItems, 15);
      expect(result.hasNext, false);
      expect(result.hasPrevious, true);
    });

    test('should handle empty reviews list', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'page': 1,
        'pageSize': 20,
        'totalItems': 0,
        'totalPages': 0,
        'hasNext': false,
        'hasPrevious': false,
      };

      dioAdapter.onGet(
        '/api/movies/movie-no-reviews/reviews',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 1, 'pageSize': 20},
      );

      // Act
      final result = await apiClient.getMovieReviews('movie-no-reviews');

      // Assert
      expect(result.data.length, 0);
      expect(result.totalItems, 0);
    });
  });

  group('Edge Cases and Error Handling', () {
    test('should handle network errors gracefully', () async {
      // Arrange
      dioAdapter.onGet(
        '/api/movies',
        (server) => server.throws(
          500,
          DioException(
            requestOptions: RequestOptions(path: '/api/movies'),
            error: 'Internal Server Error',
          ),
        ),
      );

      // Act & Assert
      expect(
        () => apiClient.getMovies(),
        throwsA(isA<DioException>()),
      );
    });

    test('should handle timeout errors', () async {
      // Arrange
      dioAdapter.onGet(
        '/api/movies',
        (server) => server.throws(
          408,
          DioException(
            requestOptions: RequestOptions(path: '/api/movies'),
            type: DioExceptionType.connectionTimeout,
            error: 'Connection timeout',
          ),
        ),
      );

      // Act & Assert
      expect(
        () => apiClient.getMovies(),
        throwsA(isA<DioException>()),
      );
    });

    test('should skip empty filter parameters', () async {
      // Arrange
      final mockResponse = {
        'data': [],
        'page': 1,
        'pageSize': 20,
        'totalItems': 0,
        'totalPages': 0,
        'hasNext': false,
        'hasPrevious': false,
      };

      dioAdapter.onGet(
        '/api/movies',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 1, 'pageSize': 20},
      );

      // Act
      final result = await apiClient.getMovies(
        search: '',
        genre: '',
        status: '',
      );

      // Assert - empty strings should not be sent as query parameters
      expect(result.data.length, 0);
    });
  });
}
