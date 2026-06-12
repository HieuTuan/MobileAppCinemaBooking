import '../../models/api_error.dart';

/// Base class for API exceptions
///
/// All API exceptions contain an ApiError object with details about what went wrong.
abstract class ApiException implements Exception {
  final ApiError error;

  ApiException(this.error);

  @override
  String toString() => error.toString();
}

/// Exception thrown for validation errors (400 Bad Request)
///
/// Indicates that the request was malformed or contained invalid data.
/// Check the fieldErrors property in the ApiError for specific validation failures.
///
/// Requirements: 30.2
///
/// Example:
/// ```dart
/// try {
///   await apiClient.post('/api/bookings', data: invalidData);
/// } on ApiValidationException catch (e) {
///   print('Validation failed: ${e.error.message}');
///   if (e.error.fieldErrors != null) {
///     e.error.fieldErrors!.forEach((field, message) {
///       print('$field: $message');
///     });
///   }
/// }
/// ```
class ApiValidationException extends ApiException {
  ApiValidationException(super.error);
}

/// Exception thrown for authentication errors (401 Unauthorized)
///
/// Indicates that the request requires authentication or the provided
/// authentication token is invalid or expired.
///
/// Requirements: 30.3
///
/// Example:
/// ```dart
/// try {
///   await apiClient.get('/api/bookings');
/// } on ApiAuthException catch (e) {
///   print('Authentication failed: ${e.error.message}');
///   // Navigate to login screen
/// }
/// ```
class ApiAuthException extends ApiException {
  ApiAuthException(super.error);
}

/// Exception thrown for authorization errors (403 Forbidden)
///
/// Indicates that the authenticated user does not have permission
/// to access the requested resource.
///
/// Requirements: 30.4
///
/// Example:
/// ```dart
/// try {
///   await apiClient.delete('/api/admin/movies/123');
/// } on ApiAuthorizationException catch (e) {
///   print('Insufficient permissions: ${e.error.message}');
/// }
/// ```
class ApiAuthorizationException extends ApiException {
  ApiAuthorizationException(super.error);
}

/// Exception thrown when a resource is not found (404 Not Found)
///
/// Indicates that the requested resource does not exist or is not available.
///
/// Requirements: 30.5
///
/// Example:
/// ```dart
/// try {
///   await apiClient.get('/api/movies/invalid-id');
/// } on ApiNotFoundException catch (e) {
///   print('Not found: ${e.error.message}');
/// }
/// ```
class ApiNotFoundException extends ApiException {
  ApiNotFoundException(super.error);
}

/// Exception thrown for conflict errors (409 Conflict)
///
/// Indicates a conflict with the current state of the resource.
/// Common scenarios:
/// - Seat already booked by another user
/// - Email already exists during registration
/// - Movie has active showtimes and cannot be deleted
///
/// Requirements: 30.1
///
/// Example:
/// ```dart
/// try {
///   await apiClient.post('/api/showtimes/123/seats/hold',
///       data: {'seatCodes': ['A1']});
/// } on ApiConflictException catch (e) {
///   print('Conflict: ${e.error.message}');
///   // Handle seat already taken scenario
/// }
/// ```
class ApiConflictException extends ApiException {
  final List<String> unavailableSeats;

  ApiConflictException(super.error, {this.unavailableSeats = const []});
}

/// Exception thrown for server errors (500 Internal Server Error)
///
/// Indicates an unexpected error occurred on the server.
/// These errors should be logged and reported.
///
/// Requirements: 30.6
///
/// Example:
/// ```dart
/// try {
///   await apiClient.post('/api/bookings', data: bookingData);
/// } on ApiServerException catch (e) {
///   print('Server error: ${e.error.message}');
///   // Show generic error message to user
///   // Log error for debugging
/// }
/// ```
class ApiServerException extends ApiException {
  ApiServerException(super.error);
}

/// Exception thrown when rate limit is exceeded (429 Too Many Requests)
///
/// Indicates that the client has sent too many requests in a given time period.
/// The retryAfter property indicates when the client can retry the request.
///
/// Requirements: 31.3
///
/// Example:
/// ```dart
/// try {
///   await apiClient.get('/api/movies');
/// } on ApiRateLimitException catch (e) {
///   print('Rate limit exceeded: ${e.error.message}');
///   print('Retry after: ${e.retryAfter}');
///   // Wait until retryAfter before making another request
/// }
/// ```
class ApiRateLimitException extends ApiException {
  /// DateTime indicating when the client can retry the request
  final DateTime retryAfter;

  ApiRateLimitException(super.error, this.retryAfter);

  @override
  String toString() => '${error.toString()}, retryAfter: $retryAfter';
}

/// Exception thrown for network connectivity errors
///
/// Indicates that the request failed due to network issues such as
/// no internet connection, DNS resolution failure, or connection timeout.
///
/// Example:
/// ```dart
/// try {
///   await apiClient.get('/api/movies');
/// } on ApiNetworkException catch (e) {
///   print('Network error: ${e.message}');
///   // Show offline indicator
/// }
/// ```
class ApiNetworkException implements Exception {
  final String message;
  final Exception? originalException;

  ApiNetworkException(this.message, [this.originalException]);

  @override
  String toString() => 'ApiNetworkException: $message';
}

/// Exception thrown for timeout errors
///
/// Indicates that the request took longer than the configured timeout period.
///
/// Example:
/// ```dart
/// try {
///   await apiClient.post('/api/payment', data: paymentData);
/// } on ApiTimeoutException catch (e) {
///   print('Request timeout: ${e.message}');
///   // Offer to retry
/// }
/// ```
class ApiTimeoutException implements Exception {
  final String message;

  ApiTimeoutException(this.message);

  @override
  String toString() => 'ApiTimeoutException: $message';
}
