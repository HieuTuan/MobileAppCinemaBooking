import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:cine_book/api/api_client.dart';
import 'package:cine_book/models/showtime.dart';

/// Unit tests for showtime retrieval endpoints.
/// 
/// **Requirements Coverage:**
/// - Requirement 3.1: Showtime retrieval for movie screenings
/// - Requirement 3.7: Complete showtime information including movie, room, timing, and pricing
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

  group('getShowtimes - Basic Functionality', () {
    test('should fetch all showtimes for a movie without date filter', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'showtime-1',
          'movieId': 'movie-123',
          'roomId': 'room-1',
          'startTime': '2024-03-15T14:30:00.000Z',
          'endTime': '2024-03-15T16:45:00.000Z',
          'basePrice': 150000,
          'status': 'scheduled',
          'roomName': 'Theater 1',
          'cinemaName': 'CineLuxe Central',
          'cinemaAddress': '123 Main Street, District 1, Ho Chi Minh City',
        },
        {
          'id': 'showtime-2',
          'movieId': 'movie-123',
          'roomId': 'room-2',
          'startTime': '2024-03-15T18:00:00.000Z',
          'endTime': '2024-03-15T20:15:00.000Z',
          'basePrice': 180000,
          'status': 'scheduled',
          'roomName': 'Theater 2',
          'cinemaName': 'CineLuxe Central',
          'cinemaAddress': '123 Main Street, District 1, Ho Chi Minh City',
        },
        {
          'id': 'showtime-3',
          'movieId': 'movie-123',
          'roomId': 'room-1',
          'startTime': '2024-03-16T14:30:00.000Z',
          'endTime': '2024-03-16T16:45:00.000Z',
          'basePrice': 150000,
          'status': 'scheduled',
          'roomName': 'Theater 1',
          'cinemaName': 'CineLuxe Central',
          'cinemaAddress': '123 Main Street, District 1, Ho Chi Minh City',
        },
      ];

      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'movieId': 'movie-123'},
      );

      // Act
      final result = await apiClient.getShowtimes('movie-123');

      // Assert
      expect(result.length, 3);
      expect(result[0].id, 'showtime-1');
      expect(result[0].movieId, 'movie-123');
      expect(result[0].roomId, 'room-1');
      expect(result[0].basePrice, 150000);
      expect(result[0].status, 'scheduled');
      expect(result[0].roomName, 'Theater 1');
      expect(result[0].cinemaName, 'CineLuxe Central');
      expect(result[1].id, 'showtime-2');
      expect(result[2].id, 'showtime-3');
    });

    test('should fetch showtimes for a movie with date filter', () async {
      // Arrange
      final filterDate = DateTime(2024, 3, 15);
      final mockResponse = [
        {
          'id': 'showtime-1',
          'movieId': 'movie-123',
          'roomId': 'room-1',
          'startTime': '2024-03-15T14:30:00.000Z',
          'endTime': '2024-03-15T16:45:00.000Z',
          'basePrice': 150000,
          'status': 'scheduled',
          'roomName': 'Theater 1',
          'cinemaName': 'CineLuxe Central',
          'cinemaAddress': '123 Main Street, District 1, Ho Chi Minh City',
        },
        {
          'id': 'showtime-2',
          'movieId': 'movie-123',
          'roomId': 'room-2',
          'startTime': '2024-03-15T18:00:00.000Z',
          'endTime': '2024-03-15T20:15:00.000Z',
          'basePrice': 180000,
          'status': 'scheduled',
          'roomName': 'Theater 2',
          'cinemaName': 'CineLuxe Central',
          'cinemaAddress': '123 Main Street, District 1, Ho Chi Minh City',
        },
      ];

      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'movieId': 'movie-123', 'date': '2024-03-15'},
      );

      // Act
      final result = await apiClient.getShowtimes('movie-123', date: filterDate);

      // Assert
      expect(result.length, 2);
      expect(result[0].id, 'showtime-1');
      expect(result[1].id, 'showtime-2');
      // Verify both showtimes are on the same date
      expect(result[0].startTime.year, 2024);
      expect(result[0].startTime.month, 3);
      expect(result[0].startTime.day, 15);
      expect(result[1].startTime.year, 2024);
      expect(result[1].startTime.month, 3);
      expect(result[1].startTime.day, 15);
    });

    test('should handle empty showtime list', () async {
      // Arrange
      final mockResponse = <Map<String, dynamic>>[];

      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'movieId': 'movie-no-showtimes'},
      );

      // Act
      final result = await apiClient.getShowtimes('movie-no-showtimes');

      // Assert
      expect(result.length, 0);
      expect(result, isEmpty);
    });
  });

  group('getShowtimes - DateTime Formatting', () {
    test('should format date correctly with single digit month and day', () async {
      // Arrange
      final filterDate = DateTime(2024, 1, 5); // January 5th
      final mockResponse = [
        {
          'id': 'showtime-early',
          'movieId': 'movie-456',
          'roomId': 'room-1',
          'startTime': '2024-01-05T10:00:00.000Z',
          'endTime': '2024-01-05T12:15:00.000Z',
          'basePrice': 120000,
          'status': 'scheduled',
          'roomName': 'Theater 1',
          'cinemaName': 'CineLuxe North',
          'cinemaAddress': '456 North Avenue, District 2, Ho Chi Minh City',
        },
      ];

      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'movieId': 'movie-456', 'date': '2024-01-05'},
      );

      // Act
      final result = await apiClient.getShowtimes('movie-456', date: filterDate);

      // Assert
      expect(result.length, 1);
      expect(result[0].startTime.month, 1);
      expect(result[0].startTime.day, 5);
    });

    test('should format date correctly with double digit month and day', () async {
      // Arrange
      final filterDate = DateTime(2024, 12, 25); // December 25th
      final mockResponse = [
        {
          'id': 'showtime-xmas',
          'movieId': 'movie-789',
          'roomId': 'room-3',
          'startTime': '2024-12-25T20:00:00.000Z',
          'endTime': '2024-12-25T22:30:00.000Z',
          'basePrice': 200000,
          'status': 'scheduled',
          'roomName': 'Theater 3 VIP',
          'cinemaName': 'CineLuxe Premium',
          'cinemaAddress': '789 Premium Street, District 3, Ho Chi Minh City',
        },
      ];

      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'movieId': 'movie-789', 'date': '2024-12-25'},
      );

      // Act
      final result = await apiClient.getShowtimes('movie-789', date: filterDate);

      // Assert
      expect(result.length, 1);
      expect(result[0].startTime.month, 12);
      expect(result[0].startTime.day, 25);
    });

    test('should handle DateTime with time component and extract only date', () async {
      // Arrange - Date with specific time that should be ignored
      final filterDate = DateTime(2024, 6, 15, 14, 30, 45); // June 15, 2024 at 14:30:45
      final mockResponse = [
        {
          'id': 'showtime-afternoon',
          'movieId': 'movie-999',
          'roomId': 'room-2',
          'startTime': '2024-06-15T15:00:00.000Z',
          'endTime': '2024-06-15T17:15:00.000Z',
          'basePrice': 160000,
          'status': 'scheduled',
          'roomName': 'Theater 2',
          'cinemaName': 'CineLuxe Central',
          'cinemaAddress': '999 Central Road, District 1, Ho Chi Minh City',
        },
      ];

      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(200, mockResponse),
        // Should send only the date part, not the time
        queryParameters: {'movieId': 'movie-999', 'date': '2024-06-15'},
      );

      // Act
      final result = await apiClient.getShowtimes('movie-999', date: filterDate);

      // Assert
      expect(result.length, 1);
      expect(result[0].startTime.year, 2024);
      expect(result[0].startTime.month, 6);
      expect(result[0].startTime.day, 15);
    });
  });

  group('getShowtimes - Showtime Details (Requirement 3.7)', () {
    test('should return complete showtime information', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'showtime-complete',
          'movieId': 'movie-complete',
          'roomId': 'room-vip',
          'startTime': '2024-03-20T19:00:00.000Z',
          'endTime': '2024-03-20T21:30:00.000Z',
          'basePrice': 250000,
          'status': 'scheduled',
          'roomName': 'VIP Theater 1',
          'cinemaName': 'CineLuxe Premium Plaza',
          'cinemaAddress': '100 Premium Plaza, District 1, Ho Chi Minh City',
        },
      ];

      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'movieId': 'movie-complete'},
      );

      // Act
      final result = await apiClient.getShowtimes('movie-complete');

      // Assert
      expect(result.length, 1);
      final showtime = result[0];
      
      // Verify all required fields are present
      expect(showtime.id, isNotEmpty);
      expect(showtime.movieId, 'movie-complete');
      expect(showtime.roomId, 'room-vip');
      expect(showtime.startTime, isA<DateTime>());
      expect(showtime.endTime, isA<DateTime>());
      expect(showtime.basePrice, 250000);
      expect(showtime.status, 'scheduled');
      expect(showtime.roomName, 'VIP Theater 1');
      expect(showtime.cinemaName, 'CineLuxe Premium Plaza');
      expect(showtime.cinemaAddress, isNotEmpty);
      
      // Verify timing consistency
      expect(showtime.endTime.isAfter(showtime.startTime), true);
      expect(showtime.durationMinutes, 150); // 2.5 hours
    });

    test('should handle different showtime statuses', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'showtime-cancelled',
          'movieId': 'movie-status-test',
          'roomId': 'room-1',
          'startTime': '2024-03-18T14:00:00.000Z',
          'endTime': '2024-03-18T16:00:00.000Z',
          'basePrice': 150000,
          'status': 'cancelled',
          'roomName': 'Theater 1',
          'cinemaName': 'CineLuxe Central',
          'cinemaAddress': '123 Main Street, District 1, Ho Chi Minh City',
        },
      ];

      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'movieId': 'movie-status-test'},
      );

      // Act
      final result = await apiClient.getShowtimes('movie-status-test');

      // Assert
      expect(result.length, 1);
      expect(result[0].status, 'cancelled');
      expect(result[0].isCancelled, true);
      expect(result[0].isScheduled, false);
    });

    test('should handle multiple showtimes across different theaters', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'showtime-theater1',
          'movieId': 'movie-multi-theater',
          'roomId': 'room-1-central',
          'startTime': '2024-03-22T14:00:00.000Z',
          'endTime': '2024-03-22T16:15:00.000Z',
          'basePrice': 150000,
          'status': 'scheduled',
          'roomName': 'Theater 1',
          'cinemaName': 'CineLuxe Central',
          'cinemaAddress': '123 Main Street, District 1, Ho Chi Minh City',
        },
        {
          'id': 'showtime-theater2',
          'movieId': 'movie-multi-theater',
          'roomId': 'room-2-north',
          'startTime': '2024-03-22T14:30:00.000Z',
          'endTime': '2024-03-22T16:45:00.000Z',
          'basePrice': 140000,
          'status': 'scheduled',
          'roomName': 'Theater 2',
          'cinemaName': 'CineLuxe North',
          'cinemaAddress': '456 North Avenue, District 2, Ho Chi Minh City',
        },
        {
          'id': 'showtime-theater3',
          'movieId': 'movie-multi-theater',
          'roomId': 'room-3-south',
          'startTime': '2024-03-22T15:00:00.000Z',
          'endTime': '2024-03-22T17:15:00.000Z',
          'basePrice': 130000,
          'status': 'scheduled',
          'roomName': 'Theater 3',
          'cinemaName': 'CineLuxe South',
          'cinemaAddress': '789 South Road, District 7, Ho Chi Minh City',
        },
      ];

      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'movieId': 'movie-multi-theater'},
      );

      // Act
      final result = await apiClient.getShowtimes('movie-multi-theater');

      // Assert
      expect(result.length, 3);
      
      // Verify different cinemas
      final cinemas = result.map((s) => s.cinemaName).toSet();
      expect(cinemas.length, 3);
      expect(cinemas, contains('CineLuxe Central'));
      expect(cinemas, contains('CineLuxe North'));
      expect(cinemas, contains('CineLuxe South'));
      
      // Verify all have the same movie ID
      expect(result.every((s) => s.movieId == 'movie-multi-theater'), true);
    });
  });

  group('Error Handling', () {
    test('should handle 404 when movie not found', () async {
      // Arrange
      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(404, {
          'code': 'NOT_FOUND',
          'message': 'Movie not found',
          'timestamp': DateTime.now().toIso8601String(),
          'path': '/api/showtimes',
        }),
        queryParameters: {'movieId': 'nonexistent-movie'},
      );

      // Act & Assert
      expect(
        () => apiClient.getShowtimes('nonexistent-movie'),
        throwsA(isA<DioException>()),
      );
    });

    test('should handle network errors gracefully', () async {
      // Arrange
      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.throws(
          500,
          DioException(
            requestOptions: RequestOptions(path: '/api/showtimes'),
            error: 'Internal Server Error',
          ),
        ),
      );

      // Act & Assert
      expect(
        () => apiClient.getShowtimes('movie-error'),
        throwsA(isA<DioException>()),
      );
    });

    test('should handle timeout errors', () async {
      // Arrange
      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.throws(
          408,
          DioException(
            requestOptions: RequestOptions(path: '/api/showtimes'),
            type: DioExceptionType.connectionTimeout,
            error: 'Connection timeout',
          ),
        ),
      );

      // Act & Assert
      expect(
        () => apiClient.getShowtimes('movie-timeout'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('Showtime Model Properties', () {
    test('should correctly calculate duration from start and end times', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'showtime-duration',
          'movieId': 'movie-duration-test',
          'roomId': 'room-1',
          'startTime': '2024-04-01T14:00:00.000Z',
          'endTime': '2024-04-01T16:30:00.000Z', // 2.5 hours = 150 minutes
          'basePrice': 150000,
          'status': 'scheduled',
          'roomName': 'Theater 1',
          'cinemaName': 'CineLuxe Central',
          'cinemaAddress': '123 Main Street, District 1, Ho Chi Minh City',
        },
      ];

      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'movieId': 'movie-duration-test'},
      );

      // Act
      final result = await apiClient.getShowtimes('movie-duration-test');

      // Assert
      expect(result.length, 1);
      expect(result[0].durationMinutes, 150);
    });

    test('should format price correctly', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'showtime-price',
          'movieId': 'movie-price-test',
          'roomId': 'room-1',
          'startTime': '2024-04-01T14:00:00.000Z',
          'endTime': '2024-04-01T16:00:00.000Z',
          'basePrice': 1500000, // 1,500,000 VND
          'status': 'scheduled',
          'roomName': 'Theater 1',
          'cinemaName': 'CineLuxe Central',
          'cinemaAddress': '123 Main Street, District 1, Ho Chi Minh City',
        },
      ];

      dioAdapter.onGet(
        '/api/showtimes',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'movieId': 'movie-price-test'},
      );

      // Act
      final result = await apiClient.getShowtimes('movie-price-test');

      // Assert
      expect(result.length, 1);
      expect(result[0].basePrice, 1500000);
      expect(result[0].formattedPrice, '1,500,000 VND');
    });
  });
}
