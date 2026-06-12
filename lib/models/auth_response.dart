import 'package:json_annotation/json_annotation.dart';
import 'user_profile.dart';

part 'auth_response.g.dart';

/// Authentication response model containing JWT tokens and user profile.
/// 
/// Returned by login and registration endpoints for both Google OAuth
/// and email/password authentication flows.
/// 
/// **Requirements Coverage:**
/// - Requirement 1.3: JWT_Token and Refresh_Token with user profile
/// - Requirement 2.3: Email/password authentication response
/// 
/// Usage:
/// ```dart
/// // From JSON
/// final authResponse = AuthResponse.fromJson(jsonMap);
/// 
/// // Access tokens
/// final accessToken = authResponse.accessToken;
/// final user = authResponse.user;
/// ```
@JsonSerializable(explicitToJson: true)
class AuthResponse {
  /// JWT access token for authenticated API requests (15 minute expiry)
  final String accessToken;
  
  /// Refresh token for obtaining new access tokens (7 day expiry)
  final String refreshToken;
  
  /// User profile information
  final UserProfile user;
  
  /// Timestamp when the access token expires
  final DateTime expiresAt;
  
  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
  });
  
  /// Creates an instance from JSON map
  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  
  /// Converts instance to JSON map
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
  
  /// Checks if the access token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  /// Returns time remaining until token expiration
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
}
