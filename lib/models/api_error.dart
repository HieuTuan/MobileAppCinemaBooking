import 'package:json_annotation/json_annotation.dart';

part 'api_error.g.dart';

/// Structured API error response model
/// 
/// Represents a standardized error response from the backend API
/// containing error code, message, timestamp, request path, and optional
/// field-specific validation errors.
/// 
/// Requirements: 30.1, 30.2
@JsonSerializable()
class ApiError {
  /// Error code identifying the type of error (e.g., "VALIDATION_ERROR", "AUTH_FAILED")
  final String code;
  
  /// Human-readable error message describing what went wrong
  final String message;
  
  /// Timestamp when the error occurred on the server
  final DateTime timestamp;
  
  /// API path where the error occurred (e.g., "/api/bookings/123")
  final String path;
  
  /// Optional map of field-specific validation errors
  /// Key is the field name, value is the error message for that field
  /// Example: {"email": "Email already exists", "phone": "Invalid format"}
  final Map<String, dynamic>? fieldErrors;
  
  ApiError({
    required this.code,
    required this.message,
    required this.timestamp,
    required this.path,
    this.fieldErrors,
  });
  
  /// Create ApiError from JSON response
  factory ApiError.fromJson(Map<String, dynamic> json) => 
      _$ApiErrorFromJson(json);
  
  /// Convert ApiError to JSON
  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);
  
  @override
  String toString() {
    return 'ApiError(code: $code, message: $message, path: $path, timestamp: $timestamp)';
  }
}
