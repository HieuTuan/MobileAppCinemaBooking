import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/api_error.dart';
import '../exceptions/api_exceptions.dart';

/// Error handling interceptor for API requests
///
/// This interceptor:
/// - Maps HTTP status codes to typed exceptions
/// - Parses error response bodies into ApiError models
/// - Handles network errors and timeouts
/// - Provides structured error information for UI display
///
/// Requirements: 33.5, 30.1, 30.2, 30.3, 30.4
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor();

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Check if the response has an error status code
    // Even though validateStatus accepts these, we still want to convert them to exceptions
    if (_isErrorStatusCode(response.statusCode)) {
      // Create an exception for this error response
      final exception = _mapStatusCodeToException(response);

      if (kDebugMode && !_isSilentRequest(response.requestOptions)) {
        print('┌─────────────────────────────────────────────────');
        print('│ 🔥 ERROR INTERCEPTOR (Response)');
        print('│ Status: ${response.statusCode}');
        print('│ Exception: ${exception.runtimeType}');
        print('└─────────────────────────────────────────────────');
      }

      // Reject with a DioException containing our custom exception
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: exception,
          message: exception.toString(),
        ),
      );
      return;
    }

    // Normal successful response
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode && !_isSilentRequest(err.requestOptions)) {
      print('┌─────────────────────────────────────────────────');
      print('│ 🔥 ERROR INTERCEPTOR');
      print('│ Type: ${err.type}');
      print('│ Message: ${err.message}');
      print('│ Status: ${err.response?.statusCode}');
      print('└─────────────────────────────────────────────────');
    }

    // Handle different types of errors
    Exception exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = ApiTimeoutException(
          'Request timeout. Please check your internet connection and try again.',
        );
        break;

      case DioExceptionType.connectionError:
        exception = ApiNetworkException(
          'Network connection failed. Please check your internet connection.',
          err.error is Exception ? err.error as Exception : null,
        );
        break;

      case DioExceptionType.badResponse:
        // Map HTTP status codes to specific exceptions
        exception = _mapStatusCodeToException(err.response!);
        break;

      case DioExceptionType.cancel:
        exception = ApiNetworkException('Request was cancelled');
        break;

      case DioExceptionType.unknown:
      default:
        exception = ApiNetworkException(
          'An unexpected error occurred: ${err.message}',
          err.error is Exception ? err.error as Exception : null,
        );
        break;
    }

    // Create a new DioException with our custom exception
    final wrappedException = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: exception,
      message: exception.toString(),
    );

    handler.reject(wrappedException);
  }

  bool _isSilentRequest(RequestOptions options) {
    return options.extra['silentRequest'] == true;
  }

  /// Check if status code represents an error
  bool _isErrorStatusCode(int? statusCode) {
    if (statusCode == null) return false;
    return statusCode >= 400;
  }

  /// Map HTTP status code to appropriate exception type
  ///
  /// Requirements: 30.2, 30.3, 30.4, 30.5, 30.6, 31.3
  Exception _mapStatusCodeToException(Response response) {
    final statusCode = response.statusCode;
    final data = response.data;

    // Try to parse ApiError from response body
    ApiError? apiError;
    try {
      if (data is Map) {
        apiError = _parseApiError(data, response.requestOptions.path);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to parse ApiError: $e');
      }
    }

    // If we couldn't parse the error, create a generic one
    apiError ??= ApiError(
      code: (statusCode ?? 500).toString(),
      message: _getDefaultMessageForStatus(statusCode ?? 500),
      timestamp: DateTime.now(),
      path: response.requestOptions.path,
    );

    // Map status code to exception type
    switch (statusCode) {
      case 400:
        // Bad Request - Validation error
        // Requirements: 30.2
        return ApiValidationException(apiError);

      case 401:
        // Unauthorized - Authentication error
        // Requirements: 30.3
        return ApiAuthException(apiError);

      case 403:
        // Forbidden - Authorization error
        // Requirements: 30.4
        return ApiAuthorizationException(apiError);

      case 404:
        // Not Found
        // Requirements: 30.5
        return ApiNotFoundException(apiError);

      case 409:
        // Conflict - Resource conflict (e.g., seat already booked)
        // Requirements: 30.1
        final unavailableSeats = data is Map<String, dynamic>
            ? List<String>.from(
                data['unavailableSeats'] as List<dynamic>? ?? const [],
              )
            : const <String>[];
        return ApiConflictException(
          apiError,
          unavailableSeats: unavailableSeats,
        );

      case 429:
        // Too Many Requests - Rate limit exceeded
        // Requirements: 31.3
        final retryAfter = _parseRetryAfter(response);
        return ApiRateLimitException(apiError, retryAfter);

      case 500:
      case 502:
      case 503:
      case 504:
        // Server errors
        // Requirements: 30.6
        return ApiServerException(apiError);

      default:
        // For any other status code, treat as server error
        return ApiServerException(apiError);
    }
  }

  /// Parse ApiError from response data
  ///
  /// Handles both standard error format and variations
  ApiError _parseApiError(Map data, String path) {
    // Handle standard format with all fields
    if (data.containsKey('code') && data.containsKey('message')) {
      return ApiError.fromJson({
        'code': data['code']?.toString() ?? 'ERROR',
        'message': data['message']?.toString() ?? 'An error occurred',
        'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
        'path': data['path']?.toString() ?? path,
        'fieldErrors': _normalizeFieldErrors(data['fieldErrors']),
      });
    }

    // Handle simplified error format with just message
    if (data.containsKey('error') || data.containsKey('message')) {
      return ApiError(
        code: 'ERROR',
        message: (data['error'] ?? data['message'] ?? 'An error occurred')
            .toString(),
        timestamp: DateTime.now(),
        path: path,
        fieldErrors: _normalizeFieldErrors(data['fieldErrors']),
      );
    }

    // Fallback: try to extract any useful information
    return ApiError(
      code: 'UNKNOWN_ERROR',
      message: data.toString(),
      timestamp: DateTime.now(),
      path: path,
    );
  }

  Map<String, dynamic>? _normalizeFieldErrors(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List) {
      final normalized = <String, dynamic>{};
      for (final item in raw) {
        if (item is Map) {
          final field = item['field']?.toString();
          final message = item['message']?.toString();
          if (field != null && message != null) {
            normalized[field] = message;
          }
        }
      }
      return normalized.isEmpty ? null : normalized;
    }
    return null;
  }

  /// Get default error message for HTTP status code
  String _getDefaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Invalid or expired authentication token.';
      case 403:
        return 'Insufficient permissions to access this resource.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'The request conflicts with the current state of the resource.';
      case 429:
        return 'Too many requests. Please wait and try again.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. The server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. The server took too long to respond.';
      default:
        return 'An unexpected error occurred.';
    }
  }

  /// Parse Retry-After header for rate limit errors
  ///
  /// Requirements: 31.3
  ///
  /// The Retry-After header can be in two formats:
  /// - HTTP-date: "Wed, 21 Oct 2015 07:28:00 GMT"
  /// - Delay-seconds: "120"
  DateTime _parseRetryAfter(Response response) {
    final retryAfterHeader = response.headers.value('retry-after');

    if (retryAfterHeader == null) {
      // Default to 60 seconds from now if no header
      return DateTime.now().add(const Duration(seconds: 60));
    }

    // Try to parse as delay-seconds (integer)
    final delaySeconds = int.tryParse(retryAfterHeader);
    if (delaySeconds != null) {
      return DateTime.now().add(Duration(seconds: delaySeconds));
    }

    // Try to parse as HTTP-date
    try {
      return DateTime.parse(retryAfterHeader);
    } catch (e) {
      // Fallback to 60 seconds if parsing fails
      return DateTime.now().add(const Duration(seconds: 60));
    }
  }
}
