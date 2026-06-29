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

  const UpdateProfileRequest({
    this.fullName,
    this.phone,
    this.birthdate,
  });

  /// Creates an instance from JSON map
  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestFromJson(json);

  /// Converts instance to JSON map
  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);

  /// Validates full name when provided.
  String? validateFullName() {
    if (fullName == null) return null;
    if (fullName!.trim().isEmpty) {
      return 'Full name cannot be empty';
    }
    return null;
  }

  /// Validates phone number format.
  ///
  /// Accepts:
  /// - 0 followed by exactly 9 digits (e.g., 0901234567)
  /// - +84 followed by exactly 9 digits (e.g., +84901234567)
  String? validatePhone() {
    if (phone == null) return null;
    final phoneRegex = RegExp(r'^(0[0-9]{9}|\+84[0-9]{9})$');
    if (!phoneRegex.hasMatch(phone!)) {
      return 'Phone number must start with 0 or +84 followed by 9 digits';
    }
    return null;
  }

  /// Validates that birthdate is not in the future.
  String? validateBirthdate() {
    if (birthdate == null) return null;
    if (birthdate!.isAfter(DateTime.now())) {
      return 'Birthdate cannot be in the future';
    }
    return null;
  }

  /// Validates all fields and returns a list of error messages.
  List<String> validate() {
    final errors = <String>[];

    if (fullName != null && fullName!.trim().isEmpty) {
      errors.add('Full name cannot be empty');
    }

    final phoneError = validatePhone();
    if (phoneError != null) errors.add(phoneError);

    final birthdateError = validateBirthdate();
    if (birthdateError != null) errors.add(birthdateError);

    return errors;
  }

  /// Returns true when all provided fields pass validation.
  bool get isValid => validate().isEmpty;
}
