import 'package:json_annotation/json_annotation.dart';

part 'update_profile_request.g.dart';

/// Request model for updating a user's profile information.
///
/// **Requirements Coverage:**
/// - Requirement 17.1: PUT /api/users/{userId}/profile with fullName, phone, and birthdate
/// - Requirement 17.2: Phone number must match format +84 or 0 followed by 9-10 digits
/// - Requirement 17.3: Birthdate must be a valid date and not in the future
///
/// Usage:
/// ```dart
/// final request = UpdateProfileRequest(
///   fullName: 'Nguyen Van A',
///   phone: '0901234567',
///   birthdate: DateTime(1995, 6, 15),
/// );
/// final json = request.toJson();
/// ```
@JsonSerializable(includeIfNull: false)
class UpdateProfileRequest {
  /// Updated full name of the user
  final String? fullName;

  /// Updated phone number (format: 0XXXXXXXXX or +84XXXXXXXXX)
  final String? phone;

  /// Updated date of birth (must not be in the future)
  final DateTime? birthdate;

  /// Updated email of the user
  final String? email;

  const UpdateProfileRequest({
    this.fullName,
    this.phone,
    this.birthdate,
    this.email,
  });

  /// Creates an instance from JSON map
  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestFromJson(json);

  /// Converts instance to JSON map
  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);

  /// Validates phone number format.
  ///
  /// Accepts:
  /// - 0 followed by exactly 9 digits (e.g., 0901234567)
  /// - +84 followed by exactly 9 digits (e.g., +84901234567)
  String? validatePhone() {
    if (phone == null) return null;
    final phoneRegex = RegExp(r'^(0[0-9]{9,10}|\+84[0-9]{9,10})$');
    if (!phoneRegex.hasMatch(phone!)) {
      return 'Số điện thoại phải bắt đầu bằng 0 hoặc +84 tiếp theo là 9–10 chữ số';
    }
    return null;
  }

  /// Validates that birthdate is not in the future.
  String? validateBirthdate() {
    if (birthdate == null) return null;
    if (birthdate!.isAfter(DateTime.now())) {
      return 'Ngày sinh không được ở tương lai';
    }
    return null;
  }

  /// Validates that email is format compliant.
  String? validateEmail() {
    if (email == null) return null;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email!)) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  /// Validates all fields and returns a list of error messages.
  List<String> validate() {
    final errors = <String>[];

    if (fullName != null && fullName!.trim().isEmpty) {
      errors.add('Họ và tên không được để trống');
    }

    final phoneError = validatePhone();
    if (phoneError != null) errors.add(phoneError);

    final birthdateError = validateBirthdate();
    if (birthdateError != null) errors.add(birthdateError);

    final emailError = validateEmail();
    if (emailError != null) errors.add(emailError);

    return errors;
  }

  /// Returns true when all provided fields pass validation.
  bool get isValid => validate().isEmpty;
}
