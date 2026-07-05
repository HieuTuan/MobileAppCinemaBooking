import 'package:json_annotation/json_annotation.dart';

part 'update_profile_request.g.dart';

/// Request model for updating a user's profile information.
///
/// **Requirements Coverage:**
/// - Requirement 17.1: PUT /api/users/{userId}/profile with fullName, phone, and birthdate
/// - Requirement 17.2: Phone number must be 10 digits and start with 03/05/07/08/09
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

  /// Updated phone number (10 digits, prefix 03/05/07/08/09)
  final String? phone;

  /// Updated date of birth (must not be in the future)
  final DateTime? birthdate;

  const UpdateProfileRequest({this.fullName, this.phone, this.birthdate});

  /// Creates an instance from JSON map
  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestFromJson(json);

  /// Converts instance to JSON map.
  ///
  /// Backend expects LocalDate for birthdate, so send yyyy-MM-dd instead of
  /// a full ISO timestamp.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (fullName != null) json['fullName'] = fullName;
    if (phone != null) json['phone'] = phone;
    final date = birthdate;
    if (date != null) {
      json['birthdate'] =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }
    return json;
  }

  /// Validates phone number format.
  ///
  String? validatePhone() {
    if (phone == null) return null;
    final phoneRegex = RegExp(r'^(03|05|07|08|09)[0-9]{8}$');
    if (!phoneRegex.hasMatch(phone!)) {
      return 'Số điện thoại phải gồm 10 số và bắt đầu bằng 03, 05, 07, 08 hoặc 09';
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
