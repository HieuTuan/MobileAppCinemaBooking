import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

/// Registration request model for email/password account creation.
///
/// **Requirements Coverage:**
/// - Requirement 2.1: Registration with email, password, fullName, and phone
/// - Requirement 2.7: Password minimum 8 characters with complexity rules
///
/// Usage:
/// ```dart
/// // Create request
/// final request = RegisterRequest(
///   email: 'user@example.com',
///   password: 'SecureP@ss123',
///   fullName: 'John Doe',
///   phone: '0901234567',
/// );
///
/// // Convert to JSON
/// final json = request.toJson();
/// ```
@JsonSerializable()
class RegisterRequest {
  /// User's email address (must be unique and valid format)
  final String email;

  /// User's password (minimum 8 chars, must contain uppercase, lowercase, digit, special char)
  final String password;

  /// User's full name
  final String fullName;

  /// User's phone number
  final String phone;

  /// Optional birthdate (required for T18 movie bookings later)
  final DateTime? birthdate;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    this.birthdate,
  });

  /// Creates an instance from JSON map
  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  /// Converts instance to JSON map
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);

  /// Validates password meets complexity requirements
  ///
  /// Password must:
  /// - Be at least 8 characters long
  /// - Contain at least one uppercase letter
  /// - Contain at least one lowercase letter
  /// - Contain at least one digit
  /// - Contain at least one special character
  String? validatePassword() {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one digit';
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null; // Valid
  }

  /// Validates email format
  String? validateEmail() {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null; // Valid
  }

  /// Validates Vietnamese mobile phone format: 10 digits, prefix 03/05/07/08/09.
  String? validatePhone() {
    final phoneRegex = RegExp(r'^(03|05|07|08|09)[0-9]{8}$');

    if (!phoneRegex.hasMatch(phone)) {
      return 'Số điện thoại phải gồm 10 số và bắt đầu bằng 03, 05, 07, 08 hoặc 09';
    }

    return null; // Valid
  }

  /// Validates all fields and returns list of errors
  List<String> validate() {
    final errors = <String>[];

    final emailError = validateEmail();
    if (emailError != null) errors.add(emailError);

    final passwordError = validatePassword();
    if (passwordError != null) errors.add(passwordError);

    final phoneError = validatePhone();
    if (phoneError != null) errors.add(phoneError);

    if (fullName.trim().isEmpty) {
      errors.add('Full name is required');
    }

    return errors;
  }

  /// Checks if all fields are valid
  bool get isValid => validate().isEmpty;
}
