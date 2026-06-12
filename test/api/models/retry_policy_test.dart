import 'package:flutter_test/flutter_test.dart';
import 'package:cine_book/api/models/retry_policy.dart';

void main() {
  group('RetryPolicy', () {
    group('Default Configuration', () {
      test('should have correct default values', () {
        const policy = RetryPolicy();
        
        expect(policy.maxAttempts, equals(3));
        expect(policy.initialDelay, equals(Duration(seconds: 1)));
        expect(policy.maxDelay, equals(Duration(seconds: 30)));
        expect(policy.backoffMultiplier, equals(2.0));
        expect(policy.retryableStatusCodes, equals({408, 429, 500, 502, 503, 504}));
      });
      
      test('should include all required retryable status codes', () {
        const policy = RetryPolicy();
        
        // Requirement 33.7: 408, 429, 500, 502, 503, 504
        expect(policy.retryableStatusCodes.contains(408), isTrue); // Request Timeout
        expect(policy.retryableStatusCodes.contains(429), isTrue); // Too Many Requests
        expect(policy.retryableStatusCodes.contains(500), isTrue); // Internal Server Error
        expect(policy.retryableStatusCodes.contains(502), isTrue); // Bad Gateway
        expect(policy.retryableStatusCodes.contains(503), isTrue); // Service Unavailable
        expect(policy.retryableStatusCodes.contains(504), isTrue); // Gateway Timeout
      });
    });
    
    group('Exponential Backoff Calculation', () {
      test('should calculate correct delay for first attempt', () {
        const policy = RetryPolicy();
        
        final delay = policy.getDelayForAttempt(0);
        
        expect(delay, equals(Duration(seconds: 1)));
      });
      
      test('should calculate correct delay for second attempt', () {
        const policy = RetryPolicy();
        
        final delay = policy.getDelayForAttempt(1);
        
        expect(delay, equals(Duration(seconds: 2)));
      });
      
      test('should calculate correct delay for third attempt', () {
        const policy = RetryPolicy();
        
        final delay = policy.getDelayForAttempt(2);
        
        expect(delay, equals(Duration(seconds: 4)));
      });
      
      test('should calculate correct delay for fourth attempt', () {
        const policy = RetryPolicy();
        
        final delay = policy.getDelayForAttempt(3);
        
        expect(delay, equals(Duration(seconds: 8)));
      });
      
      test('should cap delay at maxDelay', () {
        const policy = RetryPolicy(
          initialDelay: Duration(seconds: 10),
          maxDelay: Duration(seconds: 15),
          backoffMultiplier: 2.0,
        );
        
        final delay = policy.getDelayForAttempt(5); // Would be 320s without cap
        
        expect(delay, equals(Duration(seconds: 15)));
      });
      
      test('should return zero duration for negative attempt', () {
        const policy = RetryPolicy();
        
        final delay = policy.getDelayForAttempt(-1);
        
        expect(delay, equals(Duration.zero));
      });
      
      test('should handle custom backoff multiplier', () {
        const policy = RetryPolicy(
          initialDelay: Duration(seconds: 1),
          backoffMultiplier: 3.0,
        );
        
        expect(policy.getDelayForAttempt(0), equals(Duration(seconds: 1)));
        expect(policy.getDelayForAttempt(1), equals(Duration(seconds: 3)));
        expect(policy.getDelayForAttempt(2), equals(Duration(seconds: 9)));
      });
    });
    
    group('Retryable Status Code Check', () {
      test('should return true for 408 Request Timeout', () {
        const policy = RetryPolicy();
        
        expect(policy.isRetryableStatusCode(408), isTrue);
      });
      
      test('should return true for 429 Too Many Requests', () {
        const policy = RetryPolicy();
        
        expect(policy.isRetryableStatusCode(429), isTrue);
      });
      
      test('should return true for 500 Internal Server Error', () {
        const policy = RetryPolicy();
        
        expect(policy.isRetryableStatusCode(500), isTrue);
      });
      
      test('should return true for 502 Bad Gateway', () {
        const policy = RetryPolicy();
        
        expect(policy.isRetryableStatusCode(502), isTrue);
      });
      
      test('should return true for 503 Service Unavailable', () {
        const policy = RetryPolicy();
        
        expect(policy.isRetryableStatusCode(503), isTrue);
      });
      
      test('should return true for 504 Gateway Timeout', () {
        const policy = RetryPolicy();
        
        expect(policy.isRetryableStatusCode(504), isTrue);
      });
      
      test('should return false for 400 Bad Request', () {
        const policy = RetryPolicy();
        
        expect(policy.isRetryableStatusCode(400), isFalse);
      });
      
      test('should return false for 401 Unauthorized', () {
        const policy = RetryPolicy();
        
        expect(policy.isRetryableStatusCode(401), isFalse);
      });
      
      test('should return false for 404 Not Found', () {
        const policy = RetryPolicy();
        
        expect(policy.isRetryableStatusCode(404), isFalse);
      });
      
      test('should return false for 200 OK', () {
        const policy = RetryPolicy();
        
        expect(policy.isRetryableStatusCode(200), isFalse);
      });
      
      test('should return false for null status code', () {
        const policy = RetryPolicy();
        
        expect(policy.isRetryableStatusCode(null), isFalse);
      });
    });
    
    group('Retry Attempt Check', () {
      test('should allow retry when current attempt is less than max', () {
        const policy = RetryPolicy(maxAttempts: 3);
        
        expect(policy.canRetry(0), isTrue);
        expect(policy.canRetry(1), isTrue);
        expect(policy.canRetry(2), isTrue);
      });
      
      test('should not allow retry when current attempt equals max', () {
        const policy = RetryPolicy(maxAttempts: 3);
        
        expect(policy.canRetry(3), isFalse);
      });
      
      test('should not allow retry when current attempt exceeds max', () {
        const policy = RetryPolicy(maxAttempts: 3);
        
        expect(policy.canRetry(4), isFalse);
        expect(policy.canRetry(10), isFalse);
      });
    });
    
    group('Copy With', () {
      test('should create copy with modified maxAttempts', () {
        const policy = RetryPolicy();
        
        final newPolicy = policy.copyWith(maxAttempts: 5);
        
        expect(newPolicy.maxAttempts, equals(5));
        expect(newPolicy.initialDelay, equals(policy.initialDelay));
        expect(newPolicy.maxDelay, equals(policy.maxDelay));
        expect(newPolicy.backoffMultiplier, equals(policy.backoffMultiplier));
      });
      
      test('should create copy with modified initialDelay', () {
        const policy = RetryPolicy();
        
        final newPolicy = policy.copyWith(initialDelay: Duration(seconds: 2));
        
        expect(newPolicy.initialDelay, equals(Duration(seconds: 2)));
        expect(newPolicy.maxAttempts, equals(policy.maxAttempts));
      });
      
      test('should create copy with modified retryableStatusCodes', () {
        const policy = RetryPolicy();
        
        final newPolicy = policy.copyWith(retryableStatusCodes: {500, 502});
        
        expect(newPolicy.retryableStatusCodes, equals({500, 502}));
        expect(newPolicy.maxAttempts, equals(policy.maxAttempts));
      });
      
      test('should preserve original when no parameters provided', () {
        const policy = RetryPolicy();
        
        final newPolicy = policy.copyWith();
        
        expect(newPolicy.maxAttempts, equals(policy.maxAttempts));
        expect(newPolicy.initialDelay, equals(policy.initialDelay));
        expect(newPolicy.maxDelay, equals(policy.maxDelay));
        expect(newPolicy.backoffMultiplier, equals(policy.backoffMultiplier));
        expect(newPolicy.retryableStatusCodes, equals(policy.retryableStatusCodes));
      });
    });
    
    group('String Representation', () {
      test('should provide readable toString', () {
        const policy = RetryPolicy();
        
        final str = policy.toString();
        
        expect(str, contains('RetryPolicy'));
        expect(str, contains('maxAttempts: 3'));
        expect(str, contains('initialDelay:'));
        expect(str, contains('backoffMultiplier: 2.0'));
      });
    });
  });
}
