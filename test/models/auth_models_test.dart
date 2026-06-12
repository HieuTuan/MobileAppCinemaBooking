import 'package:flutter_test/flutter_test.dart';
import 'package:cine_book/models/auth_models.dart';

void main() {
  group('AuthResponse', () {
    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        'refreshToken': 'refresh_token_example',
        'user': {
          'id': 'user123',
          'email': 'test@example.com',
          'fullName': 'Test User',
          'phone': '0901234567',
          'memberRank': 'silver',
          'points': 100,
          'role': 'customer',
          'isActive': true,
          'createdAt': '2024-01-01T00:00:00.000Z',
        },
        'expiresAt': '2024-01-01T00:15:00.000Z',
      };

      // Act
      final authResponse = AuthResponse.fromJson(json);

      // Assert
      expect(authResponse.accessToken, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...');
      expect(authResponse.refreshToken, 'refresh_token_example');
      expect(authResponse.user.id, 'user123');
      expect(authResponse.user.email, 'test@example.com');
      expect(authResponse.user.fullName, 'Test User');
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final authResponse = AuthResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          memberRank: 'silver',
          points: 0,
          role: 'customer',
          isActive: true,
          createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        ),
        expiresAt: DateTime.parse('2024-01-01T00:15:00.000Z'),
      );

      // Act
      final json = authResponse.toJson();

      // Assert
      expect(json['accessToken'], 'access_token');
      expect(json['refreshToken'], 'refresh_token');
      expect(json['user']['id'], 'user123');
      expect(json['expiresAt'], '2024-01-01T00:15:00.000Z');
    });

    test('should correctly identify expired tokens', () {
      // Arrange
      final expiredAuth = AuthResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        user: UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          memberRank: 'silver',
          points: 0,
          role: 'customer',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final validAuth = AuthResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        user: UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          memberRank: 'silver',
          points: 0,
          role: 'customer',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      // Assert
      expect(expiredAuth.isExpired, true);
      expect(validAuth.isExpired, false);
    });
  });

  group('UserProfile', () {
    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'id': 'user123',
        'email': 'test@example.com',
        'fullName': 'Test User',
        'phone': '0901234567',
        'birthdate': '1990-01-01T00:00:00.000Z',
        'avatarUrl': 'https://example.com/avatar.jpg',
        'memberRank': 'gold',
        'points': 2500,
        'role': 'customer',
        'permissions': null,
        'isActive': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
      };

      // Act
      final profile = UserProfile.fromJson(json);

      // Assert
      expect(profile.id, 'user123');
      expect(profile.email, 'test@example.com');
      expect(profile.fullName, 'Test User');
      expect(profile.phone, '0901234567');
      expect(profile.memberRank, 'gold');
      expect(profile.points, 2500);
      expect(profile.role, 'customer');
    });

    test('should correctly identify role types', () {
      // Arrange
      final customer = UserProfile(
        id: 'user1',
        email: 'customer@example.com',
        fullName: 'Customer',
        memberRank: 'silver',
        points: 0,
        role: 'customer',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final staff = UserProfile(
        id: 'user2',
        email: 'staff@example.com',
        fullName: 'Staff',
        memberRank: 'silver',
        points: 0,
        role: 'staff',
        permissions: ['Soát vé', 'Quản lý phòng'],
        isActive: true,
        createdAt: DateTime.now(),
      );

      final admin = UserProfile(
        id: 'user3',
        email: 'admin@example.com',
        fullName: 'Admin',
        memberRank: 'platinum',
        points: 10000,
        role: 'admin',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Assert
      expect(customer.isCustomer, true);
      expect(customer.isStaff, false);
      expect(customer.isAdmin, false);

      expect(staff.isCustomer, false);
      expect(staff.isStaff, true);
      expect(staff.isAdmin, false);

      expect(admin.isCustomer, false);
      expect(admin.isStaff, false);
      expect(admin.isAdmin, true);
    });

    test('should correctly calculate age and adult status', () {
      // Arrange
      final adultProfile = UserProfile(
        id: 'user1',
        email: 'adult@example.com',
        fullName: 'Adult User',
        birthdate: DateTime.now().subtract(const Duration(days: 365 * 25)),
        memberRank: 'silver',
        points: 0,
        role: 'customer',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final minorProfile = UserProfile(
        id: 'user2',
        email: 'minor@example.com',
        fullName: 'Minor User',
        birthdate: DateTime.now().subtract(const Duration(days: 365 * 15)),
        memberRank: 'silver',
        points: 0,
        role: 'customer',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final noBirthdateProfile = UserProfile(
        id: 'user3',
        email: 'nobirth@example.com',
        fullName: 'No Birthdate User',
        memberRank: 'silver',
        points: 0,
        role: 'customer',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Assert
      expect(adultProfile.isAdult, true);
      expect(adultProfile.age, greaterThanOrEqualTo(25));

      expect(minorProfile.isAdult, false);
      expect(minorProfile.age, greaterThanOrEqualTo(15));

      expect(noBirthdateProfile.isAdult, false);
      expect(noBirthdateProfile.age, null);
    });
  });

  group('RegisterRequest', () {
    test('should serialize to JSON correctly', () {
      // Arrange
      final request = RegisterRequest(
        email: 'newuser@example.com',
        password: 'SecureP@ss123',
        fullName: 'New User',
        phone: '0901234567',
        birthdate: DateTime.parse('1990-01-01'),
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['email'], 'newuser@example.com');
      expect(json['password'], 'SecureP@ss123');
      expect(json['fullName'], 'New User');
      expect(json['phone'], '0901234567');
      expect(json['birthdate'], '1990-01-01T00:00:00.000');
    });

    test('should validate password correctly', () {
      // Valid password
      final validRequest = RegisterRequest(
        email: 'test@example.com',
        password: 'SecureP@ss123',
        fullName: 'Test',
        phone: '0901234567',
      );

      expect(validRequest.validatePassword(), null);

      // Too short
      final shortPassword = RegisterRequest(
        email: 'test@example.com',
        password: 'Short1!',
        fullName: 'Test',
        phone: '0901234567',
      );
      expect(shortPassword.validatePassword(), isNotNull);

      // No uppercase
      final noUppercase = RegisterRequest(
        email: 'test@example.com',
        password: 'securep@ss123',
        fullName: 'Test',
        phone: '0901234567',
      );
      expect(noUppercase.validatePassword(), contains('uppercase'));

      // No lowercase
      final noLowercase = RegisterRequest(
        email: 'test@example.com',
        password: 'SECUREP@SS123',
        fullName: 'Test',
        phone: '0901234567',
      );
      expect(noLowercase.validatePassword(), contains('lowercase'));

      // No digit
      final noDigit = RegisterRequest(
        email: 'test@example.com',
        password: 'SecureP@ssword',
        fullName: 'Test',
        phone: '0901234567',
      );
      expect(noDigit.validatePassword(), contains('digit'));

      // No special character
      final noSpecial = RegisterRequest(
        email: 'test@example.com',
        password: 'SecurePass123',
        fullName: 'Test',
        phone: '0901234567',
      );
      expect(noSpecial.validatePassword(), contains('special'));
    });

    test('should validate email correctly', () {
      // Valid email
      final validRequest = RegisterRequest(
        email: 'valid@example.com',
        password: 'SecureP@ss123',
        fullName: 'Test',
        phone: '0901234567',
      );
      expect(validRequest.validateEmail(), null);

      // Invalid emails
      final invalidEmails = [
        'invalid.com',
        '@example.com',
        'test@',
        'test @example.com',
        'test@example',
      ];

      for (final email in invalidEmails) {
        final request = RegisterRequest(
          email: email,
          password: 'SecureP@ss123',
          fullName: 'Test',
          phone: '0901234567',
        );
        expect(request.validateEmail(), isNotNull, reason: 'Failed for: $email');
      }
    });

    test('should validate phone correctly', () {
      // Valid phones (0 + 9 digits or +84 + 9 digits)
      final validPhones = [
        '0901234567',  // 10 digits total
        '0912345678',  // 10 digits total
        '+84901234567', // +84 + 9 digits
        '+84912345678', // +84 + 9 digits
      ];

      for (final phone in validPhones) {
        final request = RegisterRequest(
          email: 'test@example.com',
          password: 'SecureP@ss123',
          fullName: 'Test',
          phone: phone,
        );
        expect(request.validatePhone(), null, reason: 'Failed for: $phone');
      }

      // Invalid phones
      final invalidPhones = [
        '123',
        'abcdefghij',
        '090123456', // Too short (9 digits with 0)
        '09012345678', // Too long (11 digits with 0)
        '+8412345', // Too short for +84 prefix
        '+849012345678', // Too long for +84 prefix
      ];

      for (final phone in invalidPhones) {
        final request = RegisterRequest(
          email: 'test@example.com',
          password: 'SecureP@ss123',
          fullName: 'Test',
          phone: phone,
        );
        expect(request.validatePhone(), isNotNull, reason: 'Failed for: $phone');
      }
    });

    test('should validate all fields and report errors', () {
      // All valid
      final validRequest = RegisterRequest(
        email: 'valid@example.com',
        password: 'SecureP@ss123',
        fullName: 'Test User',
        phone: '0901234567',
      );
      expect(validRequest.validate(), isEmpty);
      expect(validRequest.isValid, true);

      // Multiple errors
      final invalidRequest = RegisterRequest(
        email: 'invalid-email',
        password: 'weak',
        fullName: '',
        phone: '123',
      );
      final errors = invalidRequest.validate();
      expect(errors.length, greaterThan(0));
      expect(invalidRequest.isValid, false);
    });
  });
}
