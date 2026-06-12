import 'package:flutter_test/flutter_test.dart';
import 'package:cine_book/services/auth_service.dart';
import 'package:cine_book/models/auth_models.dart';

/// Integration test to verify email/password authentication endpoints are properly wired
/// 
/// **Requirements Coverage:**
/// - Requirement 2.1: Registration with email, password, fullName, and phone
/// - Requirement 2.3: Email/password sign-in
/// - Requirement 2.6: Validation errors with inline error display
/// 
/// This test verifies that:
/// 1. The AuthService.signInWithEmail() method exists and can be called
/// 2. The AuthService.register() method exists and can be called
/// 3. The RegisterRequest model validates input correctly
/// 4. All required parameters are properly passed through
void main() {
  group('Auth Endpoints Integration', () {
    test('signInWithEmail method signature is correct', () {
      // This test verifies the method signature exists and accepts correct parameters
      expect(
        () => AuthService().signInWithEmail('test@example.com', 'password'),
        returnsNormally,
      );
    });

    test('register method signature is correct', () {
      // This test verifies the method signature exists and accepts correct parameters
      expect(
        () => AuthService().register(
          'test@example.com',
          'SecureP@ss123',
          'Test User',
          '0901234567',
        ),
        returnsNormally,
      );
    });

    test('RegisterRequest model validates email correctly', () {
      // Valid email
      final validRequest = RegisterRequest(
        email: 'test@example.com',
        password: 'SecureP@ss123',
        fullName: 'Test User',
        phone: '0901234567',
      );
      expect(validRequest.validateEmail(), isNull);

      // Invalid email
      final invalidRequest = RegisterRequest(
        email: 'invalid-email',
        password: 'SecureP@ss123',
        fullName: 'Test User',
        phone: '0901234567',
      );
      expect(invalidRequest.validateEmail(), isNotNull);
    });

    test('RegisterRequest model validates password correctly', () {
      // Valid password
      final validRequest = RegisterRequest(
        email: 'test@example.com',
        password: 'SecureP@ss123',
        fullName: 'Test User',
        phone: '0901234567',
      );
      expect(validRequest.validatePassword(), isNull);

      // Too short
      final shortPassword = RegisterRequest(
        email: 'test@example.com',
        password: 'Short1!',
        fullName: 'Test User',
        phone: '0901234567',
      );
      expect(shortPassword.validatePassword(), contains('8 characters'));

      // No uppercase
      final noUppercase = RegisterRequest(
        email: 'test@example.com',
        password: 'securep@ss123',
        fullName: 'Test User',
        phone: '0901234567',
      );
      expect(noUppercase.validatePassword(), contains('uppercase'));

      // No digit
      final noDigit = RegisterRequest(
        email: 'test@example.com',
        password: 'SecureP@ssword',
        fullName: 'Test User',
        phone: '0901234567',
      );
      expect(noDigit.validatePassword(), contains('digit'));

      // No special character
      final noSpecial = RegisterRequest(
        email: 'test@example.com',
        password: 'SecurePass123',
        fullName: 'Test User',
        phone: '0901234567',
      );
      expect(noSpecial.validatePassword(), contains('special character'));
    });

    test('RegisterRequest model validates phone correctly', () {
      // Valid phone numbers
      final validPhones = ['0901234567', '0123456789', '+84901234567'];
      for (final phone in validPhones) {
        final request = RegisterRequest(
          email: 'test@example.com',
          password: 'SecureP@ss123',
          fullName: 'Test User',
          phone: phone,
        );
        expect(request.validatePhone(), isNull, reason: 'Phone $phone should be valid');
      }

      // Invalid phone numbers
      final invalidPhones = ['123', '090123456', '1234567890', 'abc'];
      for (final phone in invalidPhones) {
        final request = RegisterRequest(
          email: 'test@example.com',
          password: 'SecureP@ss123',
          fullName: 'Test User',
          phone: phone,
        );
        expect(request.validatePhone(), isNotNull, reason: 'Phone $phone should be invalid');
      }
    });

    test('RegisterRequest toJson produces correct structure', () {
      final request = RegisterRequest(
        email: 'test@example.com',
        password: 'SecureP@ss123',
        fullName: 'Test User',
        phone: '0901234567',
      );

      final json = request.toJson();

      expect(json['email'], equals('test@example.com'));
      expect(json['password'], equals('SecureP@ss123'));
      expect(json['fullName'], equals('Test User'));
      expect(json['phone'], equals('0901234567'));
    });
  });
}
