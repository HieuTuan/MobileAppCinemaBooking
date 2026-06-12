import 'package:cine_book/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('APIClient', () {
    late APIClient apiClient;

    setUp(() {
      apiClient = APIClient();
    });

    test('should create singleton instance', () {
      final instance1 = APIClient();
      final instance2 = APIClient();

      expect(instance1, same(instance2));
    });

    test('should have Dio instance configured with base URL', () {
      expect(apiClient.dio, isA<Dio>());
      expect(apiClient.dio.options.baseUrl, isNotEmpty);
    });

    test('should have standard timeout configured (30 seconds)', () {
      final standardOptions = apiClient.createStandardOptions();

      expect(standardOptions.sendTimeout, equals(const Duration(seconds: 30)));
      expect(
        standardOptions.receiveTimeout,
        equals(const Duration(seconds: 30)),
      );
    });

    test('should have payment timeout configured (60 seconds)', () {
      final paymentOptions = apiClient.createPaymentOptions();

      expect(paymentOptions.sendTimeout, equals(const Duration(seconds: 60)));
      expect(
        paymentOptions.receiveTimeout,
        equals(const Duration(seconds: 60)),
      );
    });

    test('should have default headers configured', () {
      final headers = apiClient.dio.options.headers;

      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['Accept'], equals('application/json'));
    });

    test('should allow updating base URL', () {
      const newBaseUrl = 'https://test.api.com';
      apiClient.updateBaseUrl(newBaseUrl);

      expect(apiClient.dio.options.baseUrl, equals(newBaseUrl));
    });

    test('should have interceptors added (auth + logging)', () {
      // Should have at least 2 interceptors: AuthInterceptor and LoggingInterceptor
      expect(apiClient.dio.interceptors.length, greaterThanOrEqualTo(2));
    });

    test('should have onUnauthorized callback settable', () {
      bool callbackInvoked = false;
      apiClient.onUnauthorized = () {
        callbackInvoked = true;
      };

      // Manually invoke to test
      apiClient.onUnauthorized?.call();

      expect(callbackInvoked, isTrue);
    });

    test('createStandardOptions should allow custom headers', () {
      final options = apiClient.createStandardOptions(
        headers: {'Authorization': 'Bearer test-token'},
      );

      expect(options.headers, isNotNull);
      expect(options.headers!['Authorization'], equals('Bearer test-token'));
    });

    test('createPaymentOptions should allow custom headers', () {
      final options = apiClient.createPaymentOptions(
        headers: {'Custom-Header': 'value'},
      );

      expect(options.headers, isNotNull);
      expect(options.headers!['Custom-Header'], equals('value'));
    });

    test('should configure Dio to accept all status codes for typed mapping', () {
      // Responses are accepted so interceptors can map them to typed exceptions.
      final validateStatus = apiClient.dio.options.validateStatus;

      expect(validateStatus, isNotNull);
      if (validateStatus != null) {
        expect(validateStatus(200), isTrue);
        expect(validateStatus(400), isTrue);
        expect(validateStatus(401), isTrue);
        expect(validateStatus(404), isTrue);
        expect(validateStatus(409), isTrue);
        expect(validateStatus(499), isTrue);
        expect(validateStatus(500), isTrue);
      }
    });

    test('should have correct base configuration timeouts', () {
      final baseOptions = apiClient.dio.options;

      expect(baseOptions.connectTimeout, equals(const Duration(seconds: 30)));
      expect(baseOptions.receiveTimeout, equals(const Duration(seconds: 30)));
      expect(baseOptions.sendTimeout, equals(const Duration(seconds: 30)));
    });
  });

  group('APIClient HTTP Methods', () {
    late APIClient apiClient;

    setUp(() {
      apiClient = APIClient();
    });

    test('get method should be available', () {
      expect(apiClient.get, isA<Function>());
    });

    test('post method should be available', () {
      expect(apiClient.post, isA<Function>());
    });

    test('postPayment method should be available', () {
      expect(apiClient.postPayment, isA<Function>());
    });

    test('put method should be available', () {
      expect(apiClient.put, isA<Function>());
    });

    test('patch method should be available', () {
      expect(apiClient.patch, isA<Function>());
    });

    test('delete method should be available', () {
      expect(apiClient.delete, isA<Function>());
    });
  });
}
