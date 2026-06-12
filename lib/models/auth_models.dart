/// Authentication data models for the Cinema Booking API Integration.
/// 
/// This file exports all authentication-related models:
/// - [AuthResponse]: JWT token response from login/register endpoints
/// - [UserProfile]: User profile data with membership and role information
/// - [RegisterRequest]: Registration request payload with validation
/// 
/// **Requirements Coverage:**
/// - Requirement 1.3: Google OAuth authentication models
/// - Requirement 2.3: Email/password authentication models
/// 
/// Usage:
/// ```dart
/// import 'package:cine_book/models/auth_models.dart';
/// 
/// // All authentication models are now available
/// final authResponse = AuthResponse.fromJson(jsonData);
/// final profile = authResponse.user;
/// ```
library auth_models;

export 'auth_response.dart';
export 'user_profile.dart';
export 'register_request.dart';
