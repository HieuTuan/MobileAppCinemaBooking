import 'dart:async';

/// Circuit breaker states
enum CircuitState { closed, open, halfOpen }

/// Circuit breaker pattern for protecting external service calls.
///
/// Requirements: 49.7
/// - Open circuit after 5 consecutive failures.
/// - Reset (half-open) after 30-second timeout.
/// - In half-open state: allow one test request.
///   If it succeeds, close circuit. If it fails, re-open.
///
/// Usage:
/// ```dart
/// final breaker = CircuitBreaker(name: 'VNPay', failureThreshold: 5);
///
/// try {
///   final result = await breaker.execute(() => vnPayService.pay(...));
/// } on CircuitOpenException catch (_) {
///   // Circuit is open - use fallback
/// }
/// ```
class CircuitBreaker {
  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
  });

  final String name;
  final int failureThreshold;
  final Duration resetTimeout;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _openedAt;

  CircuitState get state => _state;
  int get failureCount => _failureCount;

  /// Execute [action] through the circuit breaker.
  ///
  /// Throws [CircuitOpenException] when circuit is open.
  /// Propagates any exception from [action] and records a failure.
  Future<T> execute<T>(Future<T> Function() action) async {
    _maybeTransitionToHalfOpen();

    if (_state == CircuitState.open) {
      throw CircuitOpenException(name);
    }

    try {
      final result = await action();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  void _maybeTransitionToHalfOpen() {
    if (_state == CircuitState.open && _openedAt != null) {
      final elapsed = DateTime.now().difference(_openedAt!);
      if (elapsed >= resetTimeout) {
        _state = CircuitState.halfOpen;
      }
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitState.closed;
    _openedAt = null;
  }

  void _onFailure() {
    _failureCount++;
    if (_state == CircuitState.halfOpen ||
        _failureCount >= failureThreshold) {
      _state = CircuitState.open;
      _openedAt = DateTime.now();
    }
  }

  /// Manually reset the circuit to closed state (for testing or admin override).
  void reset() {
    _failureCount = 0;
    _state = CircuitState.closed;
    _openedAt = null;
  }
}

/// Thrown when the circuit is open and the call is rejected.
class CircuitOpenException implements Exception {
  CircuitOpenException(this.serviceName);

  final String serviceName;

  @override
  String toString() =>
      'CircuitOpenException: $serviceName circuit is open. '
      'Service is temporarily unavailable.';
}

/// Registry holding named circuit breakers for VNPay, FCM, CDN.
///
/// Requirements: 49.7
class CircuitBreakerRegistry {
  CircuitBreakerRegistry._();
  static final CircuitBreakerRegistry instance = CircuitBreakerRegistry._();

  final _breakers = <String, CircuitBreaker>{};

  /// Get or create a circuit breaker for [name].
  CircuitBreaker get(
    String name, {
    int failureThreshold = 5,
    Duration resetTimeout = const Duration(seconds: 30),
  }) {
    return _breakers.putIfAbsent(
      name,
      () => CircuitBreaker(
        name: name,
        failureThreshold: failureThreshold,
        resetTimeout: resetTimeout,
      ),
    );
  }

  /// Well-known circuit breaker names
  static const String vnpay = 'VNPay';
  static const String fcm = 'FCM';
  static const String cdn = 'CDN';

  /// Convenience getters for standard external services
  CircuitBreaker get vnPayBreaker => get(vnpay);
  CircuitBreaker get fcmBreaker => get(fcm);
  CircuitBreaker get cdnBreaker => get(cdn);
}
