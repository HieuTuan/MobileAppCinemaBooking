import 'package:flutter_test/flutter_test.dart';

import '../../lib/utils/circuit_breaker.dart';

/// Unit tests for CircuitBreaker pattern.
///
/// Requirements: 42.5, 49.7
void main() {
  group('CircuitBreaker', () {
    late CircuitBreaker breaker;

    setUp(() {
      breaker = CircuitBreaker(
        name: 'TestService',
        failureThreshold: 3,
        resetTimeout: const Duration(milliseconds: 100),
      );
    });

    test('initial state is closed', () {
      expect(breaker.state, CircuitState.closed);
    });

    test('successful call keeps circuit closed', () async {
      await breaker.execute(() async => 'success');
      expect(breaker.state, CircuitState.closed);
      expect(breaker.failureCount, 0);
    });

    test('failures below threshold keep circuit closed', () async {
      for (int i = 0; i < 2; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }
      expect(breaker.state, CircuitState.closed);
      expect(breaker.failureCount, 2);
    });

    test('failures at threshold open the circuit', () async {
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }
      expect(breaker.state, CircuitState.open);
    });

    test('open circuit rejects calls with CircuitOpenException', () async {
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }
      expect(
        () async => breaker.execute(() async => 'should not run'),
        throwsA(isA<CircuitOpenException>()),
      );
    });

    test('circuit transitions to half-open after reset timeout', () async {
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }
      expect(breaker.state, CircuitState.open);

      await Future.delayed(const Duration(milliseconds: 150));

      try {
        await breaker.execute(() async => 'recovery');
      } catch (_) {}

      await breaker.execute(() async => 'ok');
      expect(breaker.state, CircuitState.closed);
      expect(breaker.failureCount, 0);
    });

    test('reset() closes circuit manually', () async {
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }
      breaker.reset();
      expect(breaker.state, CircuitState.closed);
      expect(breaker.failureCount, 0);
    });

    test('CircuitBreakerRegistry returns same instance for same name', () {
      final reg = CircuitBreakerRegistry.instance;
      final b1 = reg.get('MyService');
      final b2 = reg.get('MyService');
      expect(identical(b1, b2), isTrue);
    });

    test('CircuitBreakerRegistry has well-known breakers', () {
      final reg = CircuitBreakerRegistry.instance;
      expect(reg.vnPayBreaker.name, CircuitBreakerRegistry.vnpay);
      expect(reg.fcmBreaker.name, CircuitBreakerRegistry.fcm);
      expect(reg.cdnBreaker.name, CircuitBreakerRegistry.cdn);
    });
  });
}
