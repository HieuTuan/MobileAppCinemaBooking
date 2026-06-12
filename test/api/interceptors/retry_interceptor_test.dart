import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:cine_book/api/interceptors/retry_interceptor.dart';
import 'package:cine_book/api/models/retry_policy.dart';

void main() {
  group('RetryInterceptor', () {
    late Dio dio;
    late RetryInterceptor interceptor;
    
    setUp(() {
      dio = Dio();
      interceptor = RetryInterceptor(
        dio: dio,
        policy: const RetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10), // Short delay for tests
          maxDelay: Duration(seconds: 1),
          backoffMultiplier: 2.0,
        ),
      );
    });
    
    group('Idempotent Method Check', () {
      test('should identify GET as retryable', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
        );
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        );
        
        expect(interceptor.isRetryable(error), isTrue);
      });
      
      test('should identify PUT as retryable', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'PUT',
        );
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        );
        
        expect(interceptor.isRetryable(error), isTrue);
      });
      
      test('should not retry POST requests (non-idempotent)', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'POST',
        );
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        );
        
        expect(interceptor.isRetryable(error), isFalse);
      });
    });
    
    group('Retryable Status Code Check', () {
      test('should retry on 408 Request Timeout', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
        );
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 408,
          ),
          type: DioExceptionType.badResponse,
        );
        
        expect(interceptor.isRetryable(error), isTrue);
      });
      
      test('should retry on 429 Too Many Requests', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
        );
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 429,
          ),
          type: DioExceptionType.badResponse,
        );
        
        expect(interceptor.isRetryable(error), isTrue);
      });
      
      test('should retry on 500 Internal Server Error', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
        );
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );
        
        expect(interceptor.isRetryable(error), isTrue);
      });
      
      test('should retry on 502 Bad Gateway', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
        );
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 502,
          ),
          type: DioExceptionType.badResponse,
        );
        
        expect(interceptor.isRetryable(error), isTrue);
      });
      
      test('should retry on 503 Service Unavailable', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
        );
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 503,
          ),
          type: DioExceptionType.badResponse,
        );
        
        expect(interceptor.isRetryable(error), isTrue);
      });
      
      test('should retry on 504 Gateway Timeout', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
        );
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 504,
          ),
          type: DioExceptionType.badResponse,
        );
        
        expect(interceptor.isRetryable(error), isTrue);
      });
      
      test('should not retry on 404 Not Found', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
        );
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        );
        
        expect(interceptor.isRetryable(error), isFalse);
      });
    });
    
    group('Retryable Error Type Check', () {
      test('should retry on connection timeout', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
        );
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        );
        
        expect(interceptor.isRetryable(error), isTrue);
      });
      
      test('should retry on connection error', () {
        final requestOptions = RequestOptions(
          path: '/test',
          method: 'GET',
        );
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        );
        
        expect(interceptor.isRetryable(error), isTrue);
      });
    });
    
    group('Retry Count Management', () {
      test('should initialize retry count to 0', () {
        final requestOptions = RequestOptions(path: '/test');
        
        expect(interceptor.getRetryCount(requestOptions), equals(0));
      });
      
      test('should increment retry count', () {
        final requestOptions = RequestOptions(path: '/test');
        
        interceptor.setRetryCount(requestOptions, 1);
        expect(interceptor.getRetryCount(requestOptions), equals(1));
        
        interceptor.setRetryCount(requestOptions, 2);
        expect(interceptor.getRetryCount(requestOptions), equals(2));
      });
      
      test('should store retry count in extra data', () {
        final requestOptions = RequestOptions(path: '/test');
        
        interceptor.setRetryCount(requestOptions, 5);
        
        expect(requestOptions.extra['retry_count'], equals(5));
      });
    });
  });
}
