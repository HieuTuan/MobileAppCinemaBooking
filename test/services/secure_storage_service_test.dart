import 'package:flutter_test/flutter_test.dart';
import 'package:cine_book/services/secure_storage_service.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService - Token Storage', () {
    late SecureStorageService secureStorageService;

    setUp(() {
      // Note: SecureStorageService uses singleton pattern
      secureStorageService = SecureStorageService();
    });

    test('saveAccessToken should store token with correct key', () async {
      // This is an integration test since SecureStorageService uses singleton
      // and directly instantiates FlutterSecureStorage
      
      const testToken = 'test_access_token_jwt_12345';
      
      // We can't easily mock the internal storage, but we can test
      // that save and retrieve work together
      await secureStorageService.saveAccessToken(testToken);
      final retrieved = await secureStorageService.getAccessToken();
      
      expect(retrieved, testToken);
    });

    test('saveRefreshToken should store token with correct key', () async {
      const testToken = 'test_refresh_token_xyz_67890';
      
      await secureStorageService.saveRefreshToken(testToken);
      final retrieved = await secureStorageService.getRefreshToken();
      
      expect(retrieved, testToken);
    });

    test('getAccessToken should return null when no token is stored', () async {
      // Clear any existing tokens first
      await secureStorageService.clearTokens();
      
      final token = await secureStorageService.getAccessToken();
      
      expect(token, isNull);
    });

    test('getRefreshToken should return null when no token is stored', () async {
      // Clear any existing tokens first
      await secureStorageService.clearTokens();
      
      final token = await secureStorageService.getRefreshToken();
      
      expect(token, isNull);
    });

    test('saveTokenExpiry should store expiry timestamp', () async {
      final testExpiry = DateTime.now().add(const Duration(minutes: 15));
      
      await secureStorageService.saveTokenExpiry(testExpiry);
      final retrieved = await secureStorageService.getTokenExpiry();
      
      expect(retrieved, isNotNull);
      // Compare with second precision since ISO8601 conversion may lose microseconds
      expect(retrieved!.difference(testExpiry).inSeconds.abs(), lessThan(2));
    });

    test('getTokenExpiry should return null when no expiry is stored', () async {
      await secureStorageService.clearTokens();
      
      final expiry = await secureStorageService.getTokenExpiry();
      
      expect(expiry, isNull);
    });

    test('hasAccessToken should return true when token exists', () async {
      await secureStorageService.saveAccessToken('test_token');
      
      final hasToken = await secureStorageService.hasAccessToken();
      
      expect(hasToken, isTrue);
    });

    test('hasAccessToken should return false when no token exists', () async {
      await secureStorageService.clearTokens();
      
      final hasToken = await secureStorageService.hasAccessToken();
      
      expect(hasToken, isFalse);
    });

    test('hasAccessToken should return false when token is empty string', () async {
      await secureStorageService.saveAccessToken('');
      
      final hasToken = await secureStorageService.hasAccessToken();
      
      expect(hasToken, isFalse);
    });
  });

  group('SecureStorageService - Token Expiry', () {
    late SecureStorageService secureStorageService;

    setUp(() {
      secureStorageService = SecureStorageService();
    });

    test('isTokenExpired should return true when no expiry is stored', () async {
      await secureStorageService.clearTokens();
      
      final isExpired = await secureStorageService.isTokenExpired();
      
      expect(isExpired, isTrue);
    });

    test('isTokenExpired should return false when token expires in 10 minutes', () async {
      final futureExpiry = DateTime.now().add(const Duration(minutes: 10));
      await secureStorageService.saveTokenExpiry(futureExpiry);
      
      final isExpired = await secureStorageService.isTokenExpired();
      
      expect(isExpired, isFalse);
    });

    test('isTokenExpired should return true when token expires in 3 minutes (within threshold)', () async {
      final soonExpiry = DateTime.now().add(const Duration(minutes: 3));
      await secureStorageService.saveTokenExpiry(soonExpiry);
      
      final isExpired = await secureStorageService.isTokenExpired();
      
      expect(isExpired, isTrue);
    });

    test('isTokenExpired should return true when token has already expired', () async {
      final pastExpiry = DateTime.now().subtract(const Duration(minutes: 10));
      await secureStorageService.saveTokenExpiry(pastExpiry);
      
      final isExpired = await secureStorageService.isTokenExpired();
      
      expect(isExpired, isTrue);
    });

    test('isTokenExpired should return true when token expires exactly at 5 minute threshold', () async {
      final thresholdExpiry = DateTime.now().add(const Duration(minutes: 5));
      await secureStorageService.saveTokenExpiry(thresholdExpiry);
      
      // Wait a moment to ensure threshold is crossed
      await Future.delayed(const Duration(milliseconds: 100));
      
      final isExpired = await secureStorageService.isTokenExpired();
      
      expect(isExpired, isTrue);
    });
  });

  group('SecureStorageService - Clear Tokens', () {
    late SecureStorageService secureStorageService;

    setUp(() {
      secureStorageService = SecureStorageService();
    });

    test('clearTokens should remove access token', () async {
      await secureStorageService.saveAccessToken('test_access_token');
      
      await secureStorageService.clearTokens();
      final token = await secureStorageService.getAccessToken();
      
      expect(token, isNull);
    });

    test('clearTokens should remove refresh token', () async {
      await secureStorageService.saveRefreshToken('test_refresh_token');
      
      await secureStorageService.clearTokens();
      final token = await secureStorageService.getRefreshToken();
      
      expect(token, isNull);
    });

    test('clearTokens should remove token expiry', () async {
      final expiry = DateTime.now().add(const Duration(minutes: 15));
      await secureStorageService.saveTokenExpiry(expiry);
      
      await secureStorageService.clearTokens();
      final storedExpiry = await secureStorageService.getTokenExpiry();
      
      expect(storedExpiry, isNull);
    });

    test('clearTokens should remove all tokens in single call', () async {
      // Set up all tokens
      await secureStorageService.saveAccessToken('access_token');
      await secureStorageService.saveRefreshToken('refresh_token');
      await secureStorageService.saveTokenExpiry(DateTime.now().add(const Duration(minutes: 15)));
      
      // Clear all
      await secureStorageService.clearTokens();
      
      // Verify all are cleared
      final accessToken = await secureStorageService.getAccessToken();
      final refreshToken = await secureStorageService.getRefreshToken();
      final expiry = await secureStorageService.getTokenExpiry();
      
      expect(accessToken, isNull);
      expect(refreshToken, isNull);
      expect(expiry, isNull);
    });
  });

  group('SecureStorageService - Singleton Pattern', () {
    test('should return same instance on multiple calls', () {
      final instance1 = SecureStorageService();
      final instance2 = SecureStorageService();
      
      expect(identical(instance1, instance2), isTrue);
    });

    test('should maintain state across different references', () async {
      final instance1 = SecureStorageService();
      final instance2 = SecureStorageService();
      
      const testToken = 'shared_state_token';
      await instance1.saveAccessToken(testToken);
      
      final retrieved = await instance2.getAccessToken();
      expect(retrieved, testToken);
    });
  });

  group('SecureStorageService - Platform Configuration', () {
    test('should handle empty string tokens correctly', () async {
      final service = SecureStorageService();
      
      await service.saveAccessToken('');
      final hasToken = await service.hasAccessToken();
      
      expect(hasToken, isFalse);
    });

    test('should handle special characters in tokens', () async {
      final service = SecureStorageService();
      const tokenWithSpecialChars = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      
      await service.saveAccessToken(tokenWithSpecialChars);
      final retrieved = await service.getAccessToken();
      
      expect(retrieved, tokenWithSpecialChars);
    });

    test('should handle very long tokens', () async {
      final service = SecureStorageService();
      final longToken = 'token_' + ('x' * 10000);
      
      await service.saveAccessToken(longToken);
      final retrieved = await service.getAccessToken();
      
      expect(retrieved, longToken);
    });
  });

  group('SecureStorageService - Logout Flow', () {
    late SecureStorageService secureStorageService;

    setUp(() {
      secureStorageService = SecureStorageService();
    });

    test('should support complete logout flow', () async {
      // Simulate authenticated state
      await secureStorageService.saveAccessToken('access_token_123');
      await secureStorageService.saveRefreshToken('refresh_token_456');
      await secureStorageService.saveTokenExpiry(
        DateTime.now().add(const Duration(minutes: 15)),
      );
      
      // Verify authenticated
      expect(await secureStorageService.hasAccessToken(), isTrue);
      expect(await secureStorageService.getRefreshToken(), isNotNull);
      
      // Logout
      await secureStorageService.clearTokens();
      
      // Verify logged out
      expect(await secureStorageService.hasAccessToken(), isFalse);
      expect(await secureStorageService.getAccessToken(), isNull);
      expect(await secureStorageService.getRefreshToken(), isNull);
      expect(await secureStorageService.getTokenExpiry(), isNull);
    });
  });
}
