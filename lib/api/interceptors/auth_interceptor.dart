// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/locale_service.dart';
import '../../services/secure_storage_service.dart';

/// Authentication interceptor for automatic token management
///
/// Provides:
/// - Automatic JWT token attachment to Authorization header
/// - Automatic token refresh on 401 responses
/// - Retry logic for original request after token refresh
/// - Session clearing and navigation to login on refresh failure
///
/// Requirements: 33.2, 33.3, 33.4
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final Dio _dio;
  final Function()? onUnauthorized;

  /// Flag to prevent infinite refresh loops
  bool _isRefreshing = false;

  /// Queue of requests waiting for token refresh
  final List<_RequestRetry> _requestQueue = [];

  AuthInterceptor({
    required SecureStorageService secureStorage,
    required Dio dio,
    this.onUnauthorized,
  }) : _secureStorage = secureStorage,
       _dio = dio;

  // ============================================================================
  // Request Interceptor - Attach JWT Token
  // ============================================================================

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token attachment for authentication endpoints
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    try {
      // Get access token from secure storage
      final accessToken = await _secureStorage.getAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        // Attach JWT token to Authorization header
        // Requirements: 33.2 - "Bearer {token}" format
        options.headers['Authorization'] = 'Bearer $accessToken';

        if (kDebugMode && !_isSilentRequest(options)) {
          print('🔐 AuthInterceptor: Added Authorization header');
        }
      }

      // Req 39.6 – send Accept-Language header so backend can respond
      // in the user's selected language (vi or en).
      final langCode = LocaleService.instance.locale.languageCode;
      options.headers['Accept-Language'] = langCode;

      handler.next(options);
    } catch (e) {
      if (kDebugMode && !_isSilentRequest(options)) {
        print('❌ AuthInterceptor: Error attaching token: $e');
      }
      handler.next(options);
    }
  }

  // ============================================================================
  // Response Interceptor - Handle 401 and Refresh Token
  // ============================================================================

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if this is a 401 Unauthorized error
    if (err.response?.statusCode == 401) {
      if (kDebugMode && !_isSilentRequest(err.requestOptions)) {
        print('🔒 AuthInterceptor: Received 401 Unauthorized');
      }

      // Skip refresh for authentication endpoints
      if (_isAuthEndpoint(err.requestOptions.path)) {
        return handler.next(err);
      }

      // Attempt to refresh token and retry request
      // Requirements: 33.3 - Automatic token refresh on 401 responses
      final retryResult = await _handleUnauthorized(err.requestOptions, err);

      if (retryResult != null) {
        // Successfully refreshed and retried
        return handler.resolve(retryResult);
      } else {
        // Token refresh failed - clear session and notify
        // Requirements: 33.4 - Handle refresh failure
        await _handleRefreshFailure();
        return handler.next(err);
      }
    }

    // Not a 401 error, pass through
    handler.next(err);
  }

  bool _isSilentRequest(RequestOptions options) {
    return options.extra['silentRequest'] == true;
  }

  // ============================================================================
  // Token Refresh Logic
  // ============================================================================

  /// Handle 401 Unauthorized by refreshing token and retrying request
  ///
  /// Returns Response if successful, null if refresh fails
  Future<Response?> _handleUnauthorized(
    RequestOptions requestOptions,
    DioException error,
  ) async {
    // If already refreshing, queue this request
    if (_isRefreshing) {
      if (kDebugMode) {
        print('⏳ AuthInterceptor: Token refresh in progress, queueing request');
      }
      return await _queueRequest(requestOptions);
    }

    // Start token refresh process
    _isRefreshing = true;

    try {
      if (kDebugMode) {
        print('🔄 AuthInterceptor: Attempting to refresh token');
      }

      // Get refresh token from secure storage
      final refreshToken = await _secureStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        if (kDebugMode) {
          print('❌ AuthInterceptor: No refresh token available');
        }
        return null;
      }

      // Call refresh token endpoint
      final response = await _refreshAccessToken(refreshToken);

      if (response != null) {
        if (kDebugMode) {
          print('✅ AuthInterceptor: Token refresh successful');
        }

        // Save new tokens
        await _saveTokensFromResponse(response.data);

        // Retry original request with new token
        // Requirements: 33.3 - Retry logic for original request
        final retryResponse = await _retryRequest(requestOptions);

        // Process queued requests
        await _processQueue();

        return retryResponse;
      } else {
        if (kDebugMode) {
          print('❌ AuthInterceptor: Token refresh failed');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthInterceptor: Error during token refresh: $e');
      }
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Call the refresh token API endpoint
  ///
  /// Returns Response if successful, null if refresh fails
  Future<Response?> _refreshAccessToken(String refreshToken) async {
    try {
      // Create a new Dio instance to avoid interceptor loops
      final refreshDio = Dio(
        _dio.options.copyWith(baseUrl: _dio.options.baseUrl),
      );

      final response = await refreshDio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        return response;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthInterceptor: Refresh API call failed: $e');
      }
      return null;
    }
  }

  /// Save tokens from refresh response
  Future<void> _saveTokensFromResponse(dynamic data) async {
    try {
      if (data is Map<String, dynamic>) {
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final expiresAt = data['expiresAt'] as String?;

        if (accessToken != null) {
          await _secureStorage.saveAccessToken(accessToken);
        }

        if (refreshToken != null) {
          await _secureStorage.saveRefreshToken(refreshToken);
        }

        if (expiresAt != null) {
          final expiry = DateTime.parse(expiresAt);
          await _secureStorage.saveTokenExpiry(expiry);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthInterceptor: Error saving tokens: $e');
      }
    }
  }

  /// Retry the original request with new token
  ///
  /// Requirements: 33.3 - Implement retry logic for original request
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    // Get new access token
    final newAccessToken = await _secureStorage.getAccessToken();

    // Update Authorization header with new token
    if (newAccessToken != null) {
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
    }

    if (kDebugMode) {
      print('🔄 AuthInterceptor: Retrying original request');
    }

    // Retry the request
    return await _dio.fetch(requestOptions);
  }

  // ============================================================================
  // Request Queue Management
  // ============================================================================

  /// Queue a request while token refresh is in progress
  Future<Response?> _queueRequest(RequestOptions options) async {
    final completer = _RequestRetry(options);
    _requestQueue.add(completer);
    return await completer.future;
  }

  /// Process all queued requests after successful token refresh
  Future<void> _processQueue() async {
    if (kDebugMode) {
      print(
        '🔄 AuthInterceptor: Processing ${_requestQueue.length} queued requests',
      );
    }

    for (final retry in _requestQueue) {
      try {
        final response = await _retryRequest(retry.options);
        retry.complete(response);
      } catch (e) {
        retry.completeError(e);
      }
    }

    _requestQueue.clear();
  }

  // ============================================================================
  // Session Cleanup
  // ============================================================================

  /// Handle token refresh failure by clearing session
  ///
  /// Requirements: 33.4 - Clear session and redirect to login on refresh failure
  Future<void> _handleRefreshFailure() async {
    if (kDebugMode) {
      print('🔒 AuthInterceptor: Token refresh failed, clearing session');
    }

    try {
      // Clear all stored tokens
      await _secureStorage.clearTokens();

      // Clear request queue
      for (final retry in _requestQueue) {
        retry.completeError(
          DioException(
            requestOptions: retry.options,
            error: 'Session expired',
            type: DioExceptionType.cancel,
          ),
        );
      }
      _requestQueue.clear();

      // Notify app to redirect to login
      // This callback should be set by the app to navigate to login screen
      onUnauthorized?.call();
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthInterceptor: Error during session cleanup: $e');
      }
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Check if the request is for an authentication endpoint
  ///
  /// Skip token attachment and refresh logic for auth endpoints
  bool _isAuthEndpoint(String path) {
    return path.contains('/api/auth/login') ||
        path.contains('/api/auth/register') ||
        path.contains('/api/auth/verify-registration') ||
        path.contains('/api/auth/resend-registration-otp') ||
        path.contains('/api/auth/refresh') ||
        path.contains('/api/auth/forgot-password') ||
        path.contains('/api/auth/reset-password') ||
        path.contains('/api/auth/google');
  }
}

/// Helper class to manage request retry with Future completion
class _RequestRetry {
  final RequestOptions options;
  final _completer = Completer<Response>();

  _RequestRetry(this.options);

  Future<Response> get future => _completer.future;

  void complete(Response response) {
    if (!_completer.isCompleted) {
      _completer.complete(response);
    }
  }

  void completeError(Object error) {
    if (!_completer.isCompleted) {
      _completer.completeError(error);
    }
  }
}
