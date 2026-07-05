import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/retry_policy.dart';

/// Retry interceptor that implements exponential backoff for network failures
///
/// Automatically retries failed requests based on configurable retry policy.
/// Handles transient failures like timeouts, server errors, and rate limits.
///
/// Retry Logic:
/// - Retries up to 3 attempts by default
/// - Uses exponential backoff: 1s → 2s → 4s → 8s
/// - Only retries idempotent methods (GET, HEAD, PUT, DELETE, OPTIONS, PATCH)
/// - Retries specific status codes: 408, 429, 500, 502, 503, 504
/// - Retries network errors (connection failures, timeouts)
///
/// Requirements: 33.7
class RetryInterceptor extends Interceptor {
  final RetryPolicy policy;
  final Dio dio;

  RetryInterceptor({RetryPolicy? policy, required this.dio})
    : policy = policy ?? const RetryPolicy();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_skipRetry(err.requestOptions)) {
      return handler.next(err);
    }

    final silent = _isSilentRequest(err.requestOptions);

    // Check if request is retryable
    if (!isRetryable(err)) {
      if (kDebugMode && !silent) {
        print(
          '❌ RetryInterceptor: Request not retryable - ${err.requestOptions.path}',
        );
      }
      return handler.next(err);
    }

    // Get current retry count from request options
    final currentAttempt = getRetryCount(err.requestOptions);

    // Check if we can retry
    if (!policy.canRetry(currentAttempt)) {
      if (kDebugMode && !silent) {
        print(
          '❌ RetryInterceptor: Max attempts reached ($currentAttempt/${policy.maxAttempts}) - ${err.requestOptions.path}',
        );
      }
      return handler.next(err);
    }

    // Calculate delay for this attempt
    final delay = policy.getDelayForAttempt(currentAttempt);

    if (kDebugMode && !silent) {
      print(
        '🔄 RetryInterceptor: Retrying request (attempt ${currentAttempt + 1}/${policy.maxAttempts}) '
        'after ${delay.inMilliseconds}ms - ${err.requestOptions.method} ${err.requestOptions.path}',
      );
      if (err.response?.statusCode != null) {
        print('   Status: ${err.response?.statusCode}');
      } else {
        print('   Error: ${err.type} - ${err.message}');
      }
    }

    // Wait before retry
    await Future.delayed(delay);

    // Increment retry count
    final newOptions = err.requestOptions;
    setRetryCount(newOptions, currentAttempt + 1);

    try {
      // Retry the request
      final response = await dio.fetch(newOptions);

      if (kDebugMode && !silent) {
        print('✅ RetryInterceptor: Retry successful - ${newOptions.path}');
      }

      return handler.resolve(response);
    } on DioException catch (retryError) {
      // Retry failed, pass to next error handler (may trigger another retry)
      if (kDebugMode && !silent) {
        print('⚠️ RetryInterceptor: Retry failed - ${newOptions.path}');
      }
      return handler.next(retryError);
    }
  }

  bool _skipRetry(RequestOptions options) {
    return options.extra['skipRetry'] == true;
  }

  bool _isSilentRequest(RequestOptions options) {
    return options.extra['silentRequest'] == true;
  }

  /// Check if a request is retryable based on method, error type, and status code
  @visibleForTesting
  bool isRetryable(DioException err) {
    // Only retry idempotent HTTP methods
    final method = err.requestOptions.method.toUpperCase();
    if (!_isIdempotentMethod(method)) {
      return false;
    }

    // Check if error type is retryable
    if (_isRetryableErrorType(err.type)) {
      return true;
    }

    // Check if status code is retryable
    if (err.response?.statusCode != null &&
        policy.isRetryableStatusCode(err.response?.statusCode)) {
      return true;
    }

    return false;
  }

  /// Check if HTTP method is idempotent (safe to retry)
  ///
  /// Idempotent methods: GET, HEAD, PUT, DELETE, OPTIONS, PATCH
  /// Non-idempotent: POST (may create duplicates)
  bool _isIdempotentMethod(String method) {
    return method == 'GET' ||
        method == 'HEAD' ||
        method == 'PUT' ||
        method == 'DELETE' ||
        method == 'OPTIONS' ||
        method == 'PATCH';
  }

  /// Check if error type warrants retry
  ///
  /// Retryable error types:
  /// - connectionTimeout: Connection establishment timeout
  /// - sendTimeout: Data send timeout
  /// - receiveTimeout: Response receive timeout
  /// - connectionError: Network connection error
  bool _isRetryableErrorType(DioExceptionType type) {
    return type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.connectionError;
  }

  /// Get retry count from request options extra data
  @visibleForTesting
  int getRetryCount(RequestOptions options) {
    return options.extra['retry_count'] as int? ?? 0;
  }

  /// Set retry count in request options extra data
  @visibleForTesting
  void setRetryCount(RequestOptions options, int count) {
    options.extra['retry_count'] = count;
  }
}
