import 'dart:math' as math;

/// Retry policy configuration for API requests with exponential backoff
///
/// Defines retry behavior for transient network failures and server errors.
/// Implements exponential backoff strategy to avoid overwhelming servers.
///
/// Requirements: 33.7
class RetryPolicy {
  /// Maximum number of retry attempts (default: 3)
  final int maxAttempts;

  /// Initial delay before first retry (default: 1 second)
  final Duration initialDelay;

  /// Maximum delay between retries (default: 30 seconds)
  final Duration maxDelay;

  /// Multiplier for exponential backoff (default: 2.0)
  final double backoffMultiplier;

  /// HTTP status codes that trigger retry
  /// Default: 408, 429, 500, 502, 503, 504
  final Set<int> retryableStatusCodes;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryableStatusCodes = const {
      408, // Request Timeout
      429, // Too Many Requests
      500, // Internal Server Error
      502, // Bad Gateway
      503, // Service Unavailable
      504, // Gateway Timeout
    },
  });

  /// Calculate delay for a given retry attempt using exponential backoff
  ///
  /// Formula: min(initialDelay * (backoffMultiplier ^ attempt), maxDelay)
  ///
  /// Example with defaults:
  /// - Attempt 0: 1s * (2 ^ 0) = 1s
  /// - Attempt 1: 1s * (2 ^ 1) = 2s
  /// - Attempt 2: 1s * (2 ^ 2) = 4s
  /// - Attempt 3: 1s * (2 ^ 3) = 8s
  Duration getDelayForAttempt(int attempt) {
    if (attempt < 0) return Duration.zero;

    // Calculate: initialDelay * (backoffMultiplier ^ attempt)
    final multiplier = math.pow(backoffMultiplier, attempt);
    final delayMillis = initialDelay.inMilliseconds * multiplier;

    final calculatedDelay = Duration(milliseconds: delayMillis.toInt());

    // Cap at maxDelay
    if (calculatedDelay > maxDelay) {
      return maxDelay;
    }

    return calculatedDelay;
  }

  /// Check if a status code is retryable
  bool isRetryableStatusCode(int? statusCode) {
    if (statusCode == null) return false;
    return retryableStatusCodes.contains(statusCode);
  }

  /// Check if more retry attempts are available
  bool canRetry(int currentAttempt) {
    return currentAttempt < maxAttempts;
  }

  /// Create a copy with modified values
  RetryPolicy copyWith({
    int? maxAttempts,
    Duration? initialDelay,
    Duration? maxDelay,
    double? backoffMultiplier,
    Set<int>? retryableStatusCodes,
  }) {
    return RetryPolicy(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      initialDelay: initialDelay ?? this.initialDelay,
      maxDelay: maxDelay ?? this.maxDelay,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      retryableStatusCodes: retryableStatusCodes ?? this.retryableStatusCodes,
    );
  }

  @override
  String toString() {
    return 'RetryPolicy(maxAttempts: $maxAttempts, initialDelay: $initialDelay, '
        'maxDelay: $maxDelay, backoffMultiplier: $backoffMultiplier, '
        'retryableStatusCodes: $retryableStatusCodes)';
  }
}
