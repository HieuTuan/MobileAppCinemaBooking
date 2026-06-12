import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import '../../lib/api/api_client.dart';
import '../../lib/api/exceptions/api_exceptions.dart';
import '../../lib/models/api_error.dart';

void main() {
  group('Error Handling Tests', () {
    late APIClient apiClient;
    late DioAdapter dioAdapter;
    
    setUp(() {
      apiClient = APIClient();
      // Update base URL for testing
      apiClient.updateBaseUrl('https://test-api.example.com');
      
      // Create mock adapter for Dio
      dioAdapter = DioAdapter(dio: apiClient.dio);
    });
    
    group('HTTP Status Code Mapping', () {
      test('400 Bad Request should throw ApiValidationException', () async {
        // Arrange
        const path = '/api/test';
        final errorResponse = {
          'code': 'VALIDATION_ERROR',
          'message': 'Invalid request data',
          'timestamp': '2024-01-01T00:00:00Z',
          'path': path,
          'fieldErrors': {
            'email': 'Email already exists',
            'phone': 'Invalid phone format'
          }
        };
        
        dioAdapter.onGet(
          path,
          (server) => server.reply(400, errorResponse),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected ApiValidationException to be thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ApiValidationException>());
          final exception = e.error as ApiValidationException;
          expect(exception.error.code, equals('VALIDATION_ERROR'));
          expect(exception.error.message, equals('Invalid request data'));
          expect(exception.error.fieldErrors, isNotNull);
          expect(exception.error.fieldErrors!['email'], equals('Email already exists'));
        }
      });
      
      test('401 Unauthorized should throw ApiAuthException', () async {
        // Arrange
        const path = '/api/protected';
        final errorResponse = {
          'code': 'AUTH_FAILED',
          'message': 'Invalid or expired token',
          'timestamp': '2024-01-01T00:00:00Z',
          'path': path,
        };
        
        dioAdapter.onGet(
          path,
          (server) => server.reply(401, errorResponse),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected ApiAuthException to be thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ApiAuthException>());
          final exception = e.error as ApiAuthException;
          expect(exception.error.code, equals('AUTH_FAILED'));
          expect(exception.error.message, equals('Invalid or expired token'));
        }
      });
      
      test('403 Forbidden should throw ApiAuthorizationException', () async {
        // Arrange
        const path = '/api/admin/users';
        final errorResponse = {
          'code': 'FORBIDDEN',
          'message': 'Insufficient permissions',
          'timestamp': '2024-01-01T00:00:00Z',
          'path': path,
        };
        
        dioAdapter.onGet(
          path,
          (server) => server.reply(403, errorResponse),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected ApiAuthorizationException to be thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ApiAuthorizationException>());
          final exception = e.error as ApiAuthorizationException;
          expect(exception.error.message, equals('Insufficient permissions'));
        }
      });
      
      test('404 Not Found should throw ApiNotFoundException', () async {
        // Arrange
        const path = '/api/movies/invalid-id';
        final errorResponse = {
          'code': 'NOT_FOUND',
          'message': 'Movie not found',
          'timestamp': '2024-01-01T00:00:00Z',
          'path': path,
        };
        
        dioAdapter.onGet(
          path,
          (server) => server.reply(404, errorResponse),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected ApiNotFoundException to be thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ApiNotFoundException>());
          final exception = e.error as ApiNotFoundException;
          expect(exception.error.message, equals('Movie not found'));
        }
      });
      
      test('409 Conflict should throw ApiConflictException', () async {
        // Arrange
        const path = '/api/showtimes/123/seats/hold';
        final errorResponse = {
          'code': 'SEAT_CONFLICT',
          'message': 'Seats already booked',
          'timestamp': '2024-01-01T00:00:00Z',
          'path': path,
        };
        
        dioAdapter.onPost(
          path,
          (server) => server.reply(409, errorResponse),
          data: {'seatCodes': ['A1', 'A2']},
        );
        
        // Act & Assert
        try {
          await apiClient.post(path, data: {'seatCodes': ['A1', 'A2']});
          fail('Expected ApiConflictException to be thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ApiConflictException>());
          final exception = e.error as ApiConflictException;
          expect(exception.error.message, equals('Seats already booked'));
        }
      });
      
      test('429 Rate Limit should throw ApiRateLimitException with retry after', () async {
        // Arrange
        const path = '/api/movies';
        final errorResponse = {
          'code': 'RATE_LIMIT',
          'message': 'Too many requests',
          'timestamp': '2024-01-01T00:00:00Z',
          'path': path,
        };
        
        dioAdapter.onGet(
          path,
          (server) => server.reply(
            429,
            errorResponse,
            headers: {'retry-after': ['60']},
          ),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected ApiRateLimitException to be thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ApiRateLimitException>());
          final exception = e.error as ApiRateLimitException;
          expect(exception.error.message, equals('Too many requests'));
          expect(exception.retryAfter, isNotNull);
          // Retry after should be approximately 60 seconds from now
          final diff = exception.retryAfter.difference(DateTime.now()).inSeconds;
          expect(diff, greaterThanOrEqualTo(55));
          expect(diff, lessThanOrEqualTo(65));
        }
      });
      
      test('500 Server Error should throw ApiServerException', () async {
        // Arrange
        const path = '/api/bookings';
        final errorResponse = {
          'code': 'INTERNAL_ERROR',
          'message': 'Internal server error',
          'timestamp': '2024-01-01T00:00:00Z',
          'path': path,
        };
        
        dioAdapter.onPost(
          path,
          (server) => server.reply(500, errorResponse),
        );
        
        // Act & Assert
        try {
          await apiClient.post(path, data: {'test': 'data'});
          fail('Expected ApiServerException to be thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ApiServerException>());
          final exception = e.error as ApiServerException;
          expect(exception.error.message, equals('Internal server error'));
        }
      });
    });
    
    group('Error Parsing', () {
      test('Should parse error with all fields', () async {
        // Arrange
        const path = '/api/test';
        final errorResponse = {
          'code': 'TEST_ERROR',
          'message': 'Test message',
          'timestamp': '2024-01-01T12:00:00Z',
          'path': path,
          'fieldErrors': {
            'field1': 'Error 1',
            'field2': 'Error 2'
          }
        };
        
        dioAdapter.onGet(
          path,
          (server) => server.reply(400, errorResponse),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected exception');
        } on DioException catch (e) {
          final exception = e.error as ApiValidationException;
          expect(exception.error.code, equals('TEST_ERROR'));
          expect(exception.error.message, equals('Test message'));
          expect(exception.error.path, equals(path));
          expect(exception.error.fieldErrors, isNotNull);
          expect(exception.error.fieldErrors!.length, equals(2));
        }
      });
      
      test('Should handle simplified error format with just message', () async {
        // Arrange
        const path = '/api/test';
        final errorResponse = {
          'error': 'Simple error message',
        };
        
        dioAdapter.onGet(
          path,
          (server) => server.reply(400, errorResponse),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected exception');
        } on DioException catch (e) {
          final exception = e.error as ApiValidationException;
          expect(exception.error.message, equals('Simple error message'));
        }
      });
      
      test('Should create default error when response is not JSON', () async {
        // Arrange
        const path = '/api/test';
        
        dioAdapter.onGet(
          path,
          (server) => server.reply(500, 'Plain text error'),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected exception');
        } on DioException catch (e) {
          final exception = e.error as ApiServerException;
          expect(exception.error.code, contains('HTTP_500'));
        }
      });
    });
    
    group('Network Errors', () {
      test('Connection timeout should throw ApiTimeoutException', () async {
        // Arrange
        const path = '/api/slow';
        
        dioAdapter.onGet(
          path,
          (server) => server.throws(
            0,
            DioException(
              requestOptions: RequestOptions(path: path),
              type: DioExceptionType.connectionTimeout,
            ),
          ),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected ApiTimeoutException to be thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ApiTimeoutException>());
        }
      });
      
      test('Connection error should throw ApiNetworkException', () async {
        // Arrange
        const path = '/api/offline';
        
        dioAdapter.onGet(
          path,
          (server) => server.throws(
            0,
            DioException(
              requestOptions: RequestOptions(path: path),
              type: DioExceptionType.connectionError,
              message: 'No internet connection',
            ),
          ),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected ApiNetworkException to be thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ApiNetworkException>());
          final exception = e.error as ApiNetworkException;
          expect(exception.message, contains('Network connection failed'));
        }
      });
    });
    
    group('Retry-After Header Parsing', () {
      test('Should parse Retry-After as delay-seconds', () async {
        // Arrange
        const path = '/api/rate-limited';
        final errorResponse = {
          'code': 'RATE_LIMIT',
          'message': 'Too many requests',
          'timestamp': '2024-01-01T00:00:00Z',
          'path': path,
        };
        
        dioAdapter.onGet(
          path,
          (server) => server.reply(
            429,
            errorResponse,
            headers: {'retry-after': ['120']},
          ),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected exception');
        } on DioException catch (e) {
          final exception = e.error as ApiRateLimitException;
          final diff = exception.retryAfter.difference(DateTime.now()).inSeconds;
          expect(diff, greaterThanOrEqualTo(115));
          expect(diff, lessThanOrEqualTo(125));
        }
      });
      
      test('Should use default 60 seconds when Retry-After header is missing', () async {
        // Arrange
        const path = '/api/rate-limited';
        final errorResponse = {
          'code': 'RATE_LIMIT',
          'message': 'Too many requests',
          'timestamp': '2024-01-01T00:00:00Z',
          'path': path,
        };
        
        dioAdapter.onGet(
          path,
          (server) => server.reply(429, errorResponse),
        );
        
        // Act & Assert
        try {
          await apiClient.get(path);
          fail('Expected exception');
        } on DioException catch (e) {
          final exception = e.error as ApiRateLimitException;
          final diff = exception.retryAfter.difference(DateTime.now()).inSeconds;
          expect(diff, greaterThanOrEqualTo(55));
          expect(diff, lessThanOrEqualTo(65));
        }
      });
    });
  });
}
