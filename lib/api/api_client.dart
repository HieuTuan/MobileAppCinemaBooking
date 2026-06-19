import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/secure_storage_service.dart';
import '../models/movie.dart';
import '../models/review.dart';
import '../models/showtime.dart';
import '../models/paginated_response.dart';
import '../models/booking_models.dart';
import '../models/notification_preferences.dart';
import '../models/user_profile.dart';
import '../models/update_profile_request.dart';
import '../models/admin_models.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'models/retry_policy.dart';

/// API Client for cinema booking backend integration
///
/// Provides a configured Dio instance with:
/// - Base URL configuration from environment
/// - Request/response logging interceptors
/// - Retry interceptor with exponential backoff for transient failures
/// - Authentication interceptor with automatic token management
/// - Error handling interceptor with typed exception mapping
/// - Configurable timeouts (30s standard, 60s payment operations)
///
/// Error Handling:
/// - Maps HTTP status codes to typed exceptions (ApiValidationException, ApiAuthException, etc.)
/// - Parses error response bodies into ApiError models
/// - Handles network errors and timeouts
///
/// Requirements: 33.1, 33.6, 33.2, 33.3, 33.4, 33.5, 33.7, 30.1, 30.2, 30.3, 30.4
class APIClient {
  late final Dio _dio;
  late final RetryInterceptor _retryInterceptor;
  late final AuthInterceptor _authInterceptor;
  late final ErrorInterceptor _errorInterceptor;
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Callback invoked when authentication fails and user needs to login
  Function()? onUnauthorized;

  /// Base URL for the API - loaded from environment variables
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Standard timeout for regular API requests (30 seconds)
  static const Duration _standardTimeout = Duration(seconds: 30);

  /// Extended timeout for payment operations (60 seconds)
  static const Duration _paymentTimeout = Duration(seconds: 60);

  /// Singleton instance
  static final APIClient _instance = APIClient._internal();

  /// Factory constructor returns singleton instance
  factory APIClient() {
    return _instance;
  }

  /// Private constructor for singleton
  APIClient._internal() {
    _initializeDio();
  }

  /// Initialize Dio with base configuration and interceptors
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _defaultBaseUrl,
        connectTimeout: _standardTimeout,
        receiveTimeout: _standardTimeout,
        sendTimeout: _standardTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Accept all status codes to handle them in interceptors
          return status != null;
        },
      ),
    );

    // Add logging interceptor first (to log all requests/responses)
    _dio.interceptors.add(_createLoggingInterceptor());

    // Add retry interceptor before auth and error interceptors
    // This ensures retries happen at the network level before other processing
    // Requirements: 33.7
    _retryInterceptor = RetryInterceptor(
      dio: _dio,
      policy: const RetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 30),
        backoffMultiplier: 2.0,
        retryableStatusCodes: {408, 429, 500, 502, 503, 504},
      ),
    );
    _dio.interceptors.add(_retryInterceptor);

    // Add authentication interceptor for token management
    // Requirements: 33.2, 33.3, 33.4
    _authInterceptor = AuthInterceptor(
      secureStorage: _secureStorage,
      dio: _dio,
      onUnauthorized: _handleUnauthorized,
    );
    _dio.interceptors.add(_authInterceptor);

    // Add error interceptor to map status codes to typed exceptions
    // Requirements: 33.5, 30.1, 30.2, 30.3, 30.4
    _errorInterceptor = ErrorInterceptor();
    _dio.interceptors.add(_errorInterceptor);
  }

  /// Handle unauthorized state by invoking the registered callback
  ///
  /// This callback should be set by the app to navigate to login screen
  /// Requirements: 33.4
  void _handleUnauthorized() {
    onUnauthorized?.call();
  }

  /// Create logging interceptor for request/response debugging
  ///
  /// Logs:
  /// - Request: method, path, headers, body
  /// - Response: status, duration, body
  /// - Errors: error message and stack trace
  Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          print('┌─────────────────────────────────────────────────');
          print('│ 🌐 REQUEST: ${options.method} ${options.path}');
          print('│ Headers: ${options.headers}');
          if (options.queryParameters.isNotEmpty) {
            print('│ Query Parameters: ${options.queryParameters}');
          }
          if (options.data != null) {
            print('│ Body: ${options.data}');
          }
          print('└─────────────────────────────────────────────────');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('┌─────────────────────────────────────────────────');
          print(
            '│ ✅ RESPONSE: ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}',
          );
          print('│ Duration: ${response.requestOptions.receiveTimeout}');
          print('│ Data: ${response.data}');
          print('└─────────────────────────────────────────────────');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('┌─────────────────────────────────────────────────');
          print(
            '│ ❌ ERROR: ${error.requestOptions.method} ${error.requestOptions.path}',
          );
          print('│ Status: ${error.response?.statusCode}');
          print('│ Message: ${error.message}');
          if (error.response?.data != null) {
            print('│ Error Data: ${error.response?.data}');
          }
          print('└─────────────────────────────────────────────────');
        }
        handler.next(error);
      },
    );
  }

  /// Get the configured Dio instance
  Dio get dio => _dio;

  /// Update base URL (useful for testing or multi-environment setup)
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// Create options with standard timeout
  Options createStandardOptions({
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    String? contentType,
  }) {
    return Options(
      headers: headers,
      responseType: responseType,
      contentType: contentType,
      sendTimeout: _standardTimeout,
      receiveTimeout: _standardTimeout,
    );
  }

  /// Create options with extended timeout for payment operations
  ///
  /// Requirements: 33.6 - 60 second timeout for payment operations
  Options createPaymentOptions({
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    String? contentType,
  }) {
    return Options(
      headers: headers,
      responseType: responseType,
      contentType: contentType,
      sendTimeout: _paymentTimeout,
      receiveTimeout: _paymentTimeout,
    );
  }

  // ============================================================================
  // HTTP Methods - to be used by service layer
  // ============================================================================

  /// GET request with standard timeout
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options ?? createStandardOptions(),
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// POST request with standard timeout
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options ?? createStandardOptions(),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// POST request with payment timeout (60 seconds)
  Future<Response<T>> postPayment<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: createPaymentOptions(),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// PUT request with standard timeout
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options ?? createStandardOptions(),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// PATCH request with standard timeout
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options ?? createStandardOptions(),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// DELETE request with standard timeout
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options ?? createStandardOptions(),
      cancelToken: cancelToken,
    );
  }

  // ============================================================================
  // Movie Endpoints - Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.8
  // ============================================================================

  /// Get movies with optional search, genre, and status filters.
  ///
  /// Supports pagination with page and pageSize parameters.
  ///
  /// **Requirements:**
  /// - 3.1: Movie search and filtering with complete movie data
  /// - 3.2: Search matches against title, director, cast members, and genres
  /// - 3.3: Genre filter returns only movies containing that genre
  /// - 3.4: Status filter for "nowShowing" movies
  /// - 3.5: Status filter for "comingSoon" movies
  /// - 3.6: Returns all active movies sorted by releaseDate descending when no filters
  /// - 3.8: Pagination support with default page 1 and pageSize 20
  ///
  /// Parameters:
  /// - [search]: Optional search text (case-insensitive, searches title/director/cast/genres)
  /// - [genre]: Optional genre filter
  /// - [status]: Optional status filter ("nowShowing" or "comingSoon")
  /// - [page]: Page number (default: 1)
  /// - [pageSize]: Items per page (default: 20)
  ///
  /// Returns paginated list of movies matching the filters.
  ///
  /// Example:
  /// ```dart
  /// // Search for action movies currently showing
  /// final response = await apiClient.getMovies(
  ///   search: 'avengers',
  ///   genre: 'Action',
  ///   status: 'nowShowing',
  ///   page: 1,
  /// );
  /// ```
  Future<PaginatedResponse<Movie>> getMovies({
    String? search,
    String? genre,
    String? status,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (genre != null && genre.isNotEmpty) {
      queryParameters['genre'] = genre;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final response = await get<Map<String, dynamic>>(
      '/api/movies',
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );

    return PaginatedResponse<Movie>.fromJson(
      response.data!,
      (json) => Movie.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Get detailed information for a specific movie.
  ///
  /// **Requirements:**
  /// - 3.1: Movie details with complete movie data
  ///
  /// Parameters:
  /// - [movieId]: Unique movie identifier
  ///
  /// Returns complete movie details including all fields.
  ///
  /// Example:
  /// ```dart
  /// final movie = await apiClient.getMovieDetails('movie-123');
  /// print('${movie.title} - ${movie.formattedDuration}');
  /// ```
  Future<Movie> getMovieDetails(
    String movieId, {
    CancelToken? cancelToken,
  }) async {
    final response = await get<Map<String, dynamic>>(
      '/api/movies/$movieId',
      cancelToken: cancelToken,
    );

    return Movie.fromJson(response.data!);
  }

  /// Create a review for a movie.
  ///
  /// **Requirements:**
  /// - 14.1: Authenticated customers can submit reviews via POST /api/reviews
  /// - 14.2: Returns 403 Forbidden if the user has not watched the movie
  /// - 14.3: Request body includes userId, movieId, rating (1-5), and comment
  ///
  /// Parameters:
  /// - [movieId]: ID of the movie to review
  /// - [rating]: Integer rating from 1 to 5
  /// - [comment]: Review text (10–500 characters)
  ///
  /// Throws [ApiAuthorizationException] (403) when the user has not watched the movie.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final review = await apiClient.createReview(
  ///     movieId: 'movie-123',
  ///     rating: 4,
  ///     comment: 'Great film with wonderful visuals!',
  ///   );
  /// } on ApiAuthorizationException catch (e) {
  ///   // User hasn't watched the movie yet
  ///   showError('Bạn cần xem phim trước khi đánh giá');
  /// }
  /// ```
  Future<Review> createReview({
    required String userId,
    required String movieId,
    required int rating,
    required String comment,
    CancelToken? cancelToken,
  }) async {
    final request = CreateReviewRequest(
      userId: userId,
      movieId: movieId,
      rating: rating,
      comment: comment,
    );

    final response = await post<Map<String, dynamic>>(
      '/api/reviews',
      data: request.toJson(),
      cancelToken: cancelToken,
    );

    return Review.fromJson(response.data!);
  }

  /// Get reviews for a specific movie with pagination.
  ///
  /// **Requirements:**
  /// - 3.1: Movie reviews with verification status
  /// - 3.8: Pagination support with default page 1 and pageSize 20
  ///
  /// Parameters:
  /// - [movieId]: Unique movie identifier
  /// - [page]: Page number (default: 1)
  /// - [pageSize]: Items per page (default: 20)
  ///
  /// Returns paginated list of reviews with user info and verification status.
  ///
  /// Example:
  /// ```dart
  /// final response = await apiClient.getMovieReviews('movie-123', page: 1);
  /// for (var review in response.data) {
  ///   print('${review.userName}: ${review.rating}/5');
  ///   if (review.isVerified) print('✓ Verified viewer');
  /// }
  /// ```
  Future<PaginatedResponse<Review>> getMovieReviews(
    String movieId, {
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    final response = await get<Map<String, dynamic>>(
      '/api/movies/$movieId/reviews',
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );

    return PaginatedResponse<Review>.fromJson(
      response.data!,
      (json) => Review.fromJson(json as Map<String, dynamic>),
    );
  }

  // ============================================================================
  // Showtime Endpoints - Requirements 3.1, 3.7
  // ============================================================================

  /// Get showtimes for a specific movie with optional date filtering.
  ///
  /// **Requirements:**
  /// - 3.1: Showtime retrieval for movie screenings
  /// - 3.7: Complete showtime information including movie, room, timing, and pricing
  ///
  /// Parameters:
  /// - [movieId]: Unique movie identifier
  /// - [date]: Optional date filter to get showtimes for specific day (filters by start date)
  ///
  /// Returns list of showtimes matching the movie and date criteria.
  ///
  /// Example:
  /// ```dart
  /// // Get all showtimes for a movie
  /// final showtimes = await apiClient.getShowtimes('movie-123');
  ///
  /// // Get showtimes for a specific date
  /// final todayShowtimes = await apiClient.getShowtimes(
  ///   'movie-123',
  ///   date: DateTime.now(),
  /// );
  /// ```
  Future<List<Showtime>> getShowtimes(
    String movieId, {
    DateTime? date,
    CancelToken? cancelToken,
  }) async {
    final queryParameters = <String, dynamic>{'movieId': movieId};

    // Add date filter if provided
    // Format DateTime to ISO 8601 date string (YYYY-MM-DD) for consistent API parsing
    if (date != null) {
      // Use UTC to avoid timezone issues and format as date only
      final dateString =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      queryParameters['date'] = dateString;
    }

    final response = await get<List<dynamic>>(
      '/api/showtimes',
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );

    return (response.data as List<dynamic>)
        .map((json) => Showtime.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<SeatMap> getSeats(String showtimeId) async {
    final response = await get<Map<String, dynamic>>(
      '/api/showtimes/$showtimeId/seats',
    );
    return SeatMap.fromJson(response.data!);
  }

  Future<HoldResponse> holdSeats(
    String showtimeId,
    List<String> seatCodes, {
    String? userId,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/showtimes/$showtimeId/seats/hold',
      data: {'seatCodes': seatCodes, if (userId != null) 'userId': userId},
    );
    return HoldResponse.fromJson(response.data!);
  }

  Future<List<FoodCombo>> getFoodCombos() async {
    final response = await get<List<dynamic>>('/api/food-combos');
    return response.data!
        .map((item) => FoodCombo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BookingResponse> createBooking(CreateBookingRequest request) async {
    final response = await postPayment<Map<String, dynamic>>(
      '/api/bookings',
      data: request.toJson(),
    );
    return BookingResponse.fromJson(response.data!);
  }

  Future<BookingDetails> getBookingDetails(String bookingId) async {
    final response = await get<Map<String, dynamic>>(
      '/api/bookings/$bookingId',
    );
    return BookingDetails.fromJson(response.data!);
  }

  Future<List<BookingDetails>> getUserBookings(
    String userId, {
    String? status,
  }) async {
    final response = await get<List<dynamic>>(
      '/api/users/$userId/bookings',
      queryParameters: {if (status != null) 'status': status},
    );
    return response.data!
        .map((item) => BookingDetails.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BookingQr> getBookingQr(String bookingId) async {
    final response = await get<Map<String, dynamic>>(
      '/api/bookings/$bookingId/qr',
    );
    return BookingQr.fromJson(response.data!);
  }

  Future<CancelBookingResponse> cancelBooking(
    String bookingId, {
    String? userId,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/bookings/$bookingId/cancel',
      data: {if (userId != null) 'userId': userId},
    );
    return CancelBookingResponse.fromJson(response.data!);
  }

  Future<PaymentStatusResult> getPaymentStatus(String bookingId) async {
    final response = await get<Map<String, dynamic>>(
      '/api/bookings/$bookingId/payment-status',
    );
    return PaymentStatusResult.fromJson(response.data!);
  }

  Future<ValidationResult> validateTicket(
    String bookingId,
    String expectedShowtimeId, {
    String? staffId,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/bookings/$bookingId/validate',
      data: {
        'expectedShowtimeId': expectedShowtimeId,
        if (staffId != null) 'staffId': staffId,
      },
      options: createStandardOptions(
        headers: {if (staffId != null) 'X-Staff-Id': staffId},
      ),
    );
    return ValidationResult.fromJson(response.data!);
  }

  /// Search bookings by booking ID or customer name for staff operations.
  ///
  /// **Requirements:**
  /// - 12.1: Staff can search by booking ID using GET /api/bookings/search?bookingId={id}
  /// - 12.2: Staff can search by customer name using GET /api/bookings/search?customerName={name}
  /// - 12.3: Returns booking details with status, movieTitle, showtimeDateTime, seats, and qrCode
  /// - 12.4: Returns empty array when no bookings match the search criteria
  /// - 12.5: Limits results to bookings for showtimes within 24 hours (before/after current time)
  ///
  /// Parameters:
  /// - [bookingId]: Optional booking ID to search for
  /// - [customerName]: Optional customer name to search for
  ///
  /// At least one search parameter must be provided.
  ///
  /// Returns list of matching bookings limited to showtimes within 24 hours.
  /// Returns empty list if no matches found.
  ///
  /// Example:
  /// ```dart
  /// // Search by booking ID
  /// final bookings = await apiClient.searchBookings(bookingId: 'BK123456');
  ///
  /// // Search by customer name
  /// final bookings = await apiClient.searchBookings(customerName: 'John Doe');
  /// ```
  Future<List<BookingDetails>> searchBookings({
    String? bookingId,
    String? customerName,
    CancelToken? cancelToken,
  }) async {
    final queryParameters = <String, dynamic>{};

    if (bookingId != null && bookingId.isNotEmpty) {
      queryParameters['bookingId'] = bookingId;
    }
    if (customerName != null && customerName.isNotEmpty) {
      queryParameters['customerName'] = customerName;
    }

    final response = await get<List<dynamic>>(
      '/api/bookings/search',
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );

    return (response.data as List<dynamic>)
        .map((json) => BookingDetails.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================================
  // Push Notification Device Registration - Requirements 37.3, 37.5
  // ============================================================================

  /// Register device for push notifications.
  ///
  /// **Requirements:**
  /// - 37.3: POST /api/users/{userId}/devices with deviceToken, platform, and deviceModel
  /// - 37.5: Update registration when device token changes (app reinstall)
  ///
  /// Parameters:
  /// - [userId]: User ID to register device for
  /// - [deviceToken]: FCM token (Android) or APNs token (iOS)
  /// - [platform]: Platform identifier ("android" or "ios")
  /// - [deviceModel]: Device model information (optional)
  ///
  /// Returns void on success, throws exception on failure.
  ///
  /// Example:
  /// ```dart
  /// await apiClient.registerDevice(
  ///   userId: 'user-123',
  ///   deviceToken: 'fcm-token-...',
  ///   platform: 'android',
  ///   deviceModel: 'Samsung Galaxy S21',
  /// );
  /// ```
  Future<void> registerDevice({
    required String userId,
    required String deviceToken,
    required String platform,
    String? deviceModel,
    CancelToken? cancelToken,
  }) async {
    await post(
      '/api/users/$userId/devices',
      data: {
        'deviceToken': deviceToken,
        'platform': platform,
        if (deviceModel != null) 'deviceModel': deviceModel,
      },
      cancelToken: cancelToken,
    );
  }

  /// Unregister device from push notifications
  ///
  /// **Requirement 37.6**: DELETE /api/users/{userId}/devices/{deviceToken} to stop notifications
  ///
  /// This should be called when user logs out to stop sending notifications to the device.
  ///
  /// Parameters:
  /// - [userId]: User ID whose device to unregister
  /// - [deviceToken]: Device token to unregister
  /// - [cancelToken]: Optional Dio cancel token for request cancellation
  ///
  /// Returns void on success, throws exception on failure.
  ///
  /// Example:
  /// ```dart
  /// await apiClient.unregisterDevice(
  ///   userId: 'user-123',
  ///   deviceToken: 'fcm-token-...',
  /// );
  /// ```
  Future<void> unregisterDevice({
    required String userId,
    required String deviceToken,
    CancelToken? cancelToken,
  }) async {
    await delete(
      '/api/users/$userId/devices/$deviceToken',
      cancelToken: cancelToken,
    );
  }

  // ============================================================================
  // Notification Preferences - Requirements 38.1, 38.2, 38.3
  // ============================================================================

  /// Get notification preferences for a user.
  ///
  /// **Requirements:**
  /// - 38.1: GET /api/users/{userId}/notification-preferences when customer opens settings
  /// - 38.2: Returns preferences with categories (showtimeReminders, promotions, newMovies, bookingUpdates)
  ///
  /// Parameters:
  /// - [userId]: User ID to fetch preferences for
  /// - [cancelToken]: Optional Dio cancel token for request cancellation
  ///
  /// Returns notification preferences with all category toggles.
  ///
  /// Example:
  /// ```dart
  /// final prefs = await apiClient.getNotificationPreferences('user-123');
  /// print('Showtime reminders: ${prefs.showtimeReminders}');
  /// ```
  Future<NotificationPreferences> getNotificationPreferences(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    final response = await get<Map<String, dynamic>>(
      '/api/users/$userId/notification-preferences',
      cancelToken: cancelToken,
    );

    return NotificationPreferences.fromJson(response.data!);
  }

  /// Update notification preferences for a user.
  ///
  /// **Requirements:**
  /// - 38.3: PATCH /api/users/{userId}/notification-preferences with updated category
  ///
  /// Parameters:
  /// - [userId]: User ID to update preferences for
  /// - [preferences]: Updated notification preferences
  /// - [cancelToken]: Optional Dio cancel token for request cancellation
  ///
  /// Returns void on success, throws exception on failure.
  ///
  /// Example:
  /// ```dart
  /// final updated = prefs.copyWith(promotions: false);
  /// await apiClient.updateNotificationPreferences('user-123', updated);
  /// ```
  Future<void> updateNotificationPreferences(
    String userId,
    NotificationPreferences preferences, {
    CancelToken? cancelToken,
  }) async {
    await patch(
      '/api/users/$userId/notification-preferences',
      data: preferences.toJson(),
      cancelToken: cancelToken,
    );
  }

  // ============================================================================
  // User Profile Endpoints - Requirements 17.1, 17.6, 17.7
  // ============================================================================

  /// Get profile data for a user.
  ///
  /// **Requirements:**
  /// - 17.7: GET /api/users/{userId}/profile returns UserProfile with memberRank and points
  /// - 17.6: Display profile fields including fullName, phone, birthdate, memberRank, points
  ///
  /// Parameters:
  /// - [userId]: User ID to fetch profile for
  /// - [cancelToken]: Optional Dio cancel token for request cancellation
  ///
  /// Returns [UserProfile] with all account and membership details.
  ///
  /// Example:
  /// ```dart
  /// final profile = await apiClient.getProfile('user-123');
  /// print('Rank: ${profile.memberRank}, Points: ${profile.points}');
  /// ```
  Future<UserProfile> getProfile(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    final response = await get<Map<String, dynamic>>(
      '/api/users/$userId/profile',
      cancelToken: cancelToken,
    );
    return UserProfile.fromJson(response.data!);
  }

  /// Update profile data for a user.
  ///
  /// **Requirements:**
  /// - 17.1: PUT /api/users/{userId}/profile with fullName, phone, and birthdate
  /// - 17.2: Phone number must match format +84 or 0 followed by 9-10 digits
  /// - 17.3: Birthdate must be a valid date and not in the future
  ///
  /// Parameters:
  /// - [userId]: User ID to update profile for
  /// - [request]: Update payload with optional fullName, phone, birthdate
  /// - [cancelToken]: Optional Dio cancel token for request cancellation
  ///
  /// Returns updated [UserProfile] on success, throws exception on failure.
  ///
  /// Example:
  /// ```dart
  /// final request = UpdateProfileRequest(
  ///   fullName: 'Nguyen Van A',
  ///   phone: '0901234567',
  ///   birthdate: DateTime(1995, 6, 15),
  /// );
  /// final updated = await apiClient.updateProfile('user-123', request);
  /// ```
  Future<UserProfile> updateProfile(
    String userId,
    UpdateProfileRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await put<Map<String, dynamic>>(
      '/api/users/$userId/profile',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return UserProfile.fromJson(response.data!);
  }

  // ============================================================================
  // Admin Dashboard Endpoints - Requirements 25.1, 25.2, 25.3, 25.4, 25.5
  // ============================================================================

  /// Get dashboard metrics for admin overview.
  ///
  /// **Requirements:**
  /// - 25.1: Today's revenue and booking count
  /// - 25.2: Active and concurrent user counts
  /// - 25.3: Upcoming showtimes with occupancy rates
  /// - 25.4: Top 5 movies by sales
  /// - 25.5: Last 10 recent bookings
  ///
  /// Returns [DashboardMetrics] with all aggregated statistics.
  ///
  /// Example:
  /// ```dart
  /// final metrics = await apiClient.getDashboardMetrics();
  /// print('Today revenue: ${metrics.todayRevenue}');
  /// ```
  Future<DashboardMetrics> getDashboardMetrics({
    CancelToken? cancelToken,
  }) async {
    final response = await get<Map<String, dynamic>>(
      '/api/admin/dashboard/metrics',
      cancelToken: cancelToken,
    );
    return DashboardMetrics.fromJson(response.data!);
  }

  // ============================================================================
  // Revenue Report Endpoint — Requirements 24.1, 24.2, 24.3, 24.4
  // ============================================================================

  /// Get a revenue report for a date range.
  ///
  /// **Requirements:**
  /// - 24.1: Revenue breakdown by payment method
  /// - 24.2: Daily revenue time series
  /// - 24.3: Summary totals (total revenue, total bookings, average booking value)
  /// - 24.4: Date range filter via startDate / endDate query params
  ///
  /// Parameters:
  /// - [startDate]: Beginning of the report period (inclusive)
  /// - [endDate]: End of the report period (inclusive)
  /// - [cancelToken]: Optional Dio cancel token for request cancellation
  ///
  /// Returns [RevenueReport] with totals, per-method breakdown, and daily series.
  ///
  /// Example:
  /// ```dart
  /// final report = await apiClient.getRevenueReport(
  ///   DateTime.now().subtract(const Duration(days: 30)),
  ///   DateTime.now(),
  /// );
  /// print('Total revenue: \${report.totalRevenue}');
  /// ```
  Future<RevenueReport> getRevenueReport(
    DateTime startDate,
    DateTime endDate, {
    CancelToken? cancelToken,
  }) async {
    String fmtDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final response = await get<Map<String, dynamic>>(
      '/api/admin/reports/revenue',
      queryParameters: {
        'startDate': fmtDate(startDate),
        'endDate': fmtDate(endDate),
      },
      cancelToken: cancelToken,
    );
    return RevenueReport.fromJson(response.data!);
  }

  // ============================================================================
  // Booking Report Endpoint — Requirements 24.5, 24.6, 24.7, 24.8, 24.9
  // ============================================================================

  /// Get a booking report for a date range.
  ///
  /// **Requirements:**
  /// - 24.5: Booking status breakdown (total, confirmed, cancelled, refunded)
  /// - 24.6: Movie rankings by ticket sales and revenue
  /// - 24.7: Theater occupancy rates
  /// - 24.8: Date range filter via startDate / endDate query params
  /// - 24.9: Summary statistics across the report period
  ///
  /// Parameters:
  /// - [startDate]: Beginning of the report period (inclusive)
  /// - [endDate]: End of the report period (inclusive)
  /// - [cancelToken]: Optional Dio cancel token for request cancellation
  ///
  /// Returns [BookingReport] with stats, movie rankings, and theater occupancy.
  ///
  /// Example:
  /// ```dart
  /// final report = await apiClient.getBookingReport(
  ///   DateTime.now().subtract(const Duration(days: 30)),
  ///   DateTime.now(),
  /// );
  /// print('Total bookings: \${report.stats.total}');
  /// ```
  Future<BookingReport> getBookingReport(
    DateTime startDate,
    DateTime endDate, {
    CancelToken? cancelToken,
  }) async {
    String fmtDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final response = await get<Map<String, dynamic>>(
      '/api/admin/reports/bookings',
      queryParameters: {
        'startDate': fmtDate(startDate),
        'endDate': fmtDate(endDate),
      },
      cancelToken: cancelToken,
    );
    return BookingReport.fromJson(response.data!);
  }

  // ============================================================================
  // Admin CRUD Endpoints — Requirements 19.x, 20.x, 21.x, 22.x, 23.x
  // ============================================================================

  Future<Movie> createAdminMovie(
    MovieManagementRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/admin/movies',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return Movie.fromJson(response.data!);
  }

  Future<Movie> updateAdminMovie(
    String movieId,
    MovieManagementRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await put<Map<String, dynamic>>(
      '/api/admin/movies/$movieId',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return Movie.fromJson(response.data!);
  }

  Future<void> deleteAdminMovie(
    String movieId, {
    CancelToken? cancelToken,
  }) async {
    await delete('/api/admin/movies/$movieId', cancelToken: cancelToken);
  }

  Future<FoodCombo> createAdminFoodCombo(
    FoodComboManagementRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/admin/food-combos',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return FoodCombo.fromJson(response.data!);
  }

  Future<FoodCombo> updateAdminFoodCombo(
    String comboId,
    FoodComboManagementRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await put<Map<String, dynamic>>(
      '/api/admin/food-combos/$comboId',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return FoodCombo.fromJson(response.data!);
  }

  Future<FoodCombo> setAdminFoodComboActive(
    String comboId,
    bool active, {
    CancelToken? cancelToken,
  }) async {
    final response = await patch<Map<String, dynamic>>(
      '/api/admin/food-combos/$comboId',
      data: {'active': active},
      cancelToken: cancelToken,
    );
    return FoodCombo.fromJson(response.data!);
  }

  Future<Theater> createAdminTheater(
    TheaterRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/admin/theaters',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return Theater.fromJson(response.data!);
  }

  Future<Room> createAdminRoom(
    RoomRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/admin/rooms',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return Room.fromJson(response.data!);
  }

  Future<Room> updateAdminRoomStatus(
    String roomId,
    String status, {
    CancelToken? cancelToken,
  }) async {
    final response = await patch<Map<String, dynamic>>(
      '/api/admin/rooms/$roomId/status',
      data: {'status': status},
      cancelToken: cancelToken,
    );
    return Room.fromJson(response.data!);
  }

  Future<Showtime> createAdminShowtime(
    ShowtimeScheduleRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/admin/showtimes',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return Showtime.fromJson(response.data!);
  }

  Future<Showtime> updateAdminShowtime(
    String showtimeId,
    ShowtimeScheduleRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await put<Map<String, dynamic>>(
      '/api/admin/showtimes/$showtimeId',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return Showtime.fromJson(response.data!);
  }

  Future<void> deleteAdminShowtime(
    String showtimeId, {
    CancelToken? cancelToken,
  }) async {
    await delete('/api/admin/showtimes/$showtimeId', cancelToken: cancelToken);
  }

  Future<PaginatedResponse<AdminUser>> getAdminUsers({
    String? role,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await get<Map<String, dynamic>>(
      '/api/admin/users',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (role != null && role.isNotEmpty) 'role': role,
      },
      cancelToken: cancelToken,
    );
    return PaginatedResponse<AdminUser>.fromJson(
      response.data!,
      (json) => AdminUser.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<StaffAccountCreationResult> createAdminUser(
    CreateStaffUserRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/admin/users',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return StaffAccountCreationResult.fromJson(response.data!);
  }

  Future<AdminUser> updateAdminUserStatus(
    String userId,
    bool active, {
    CancelToken? cancelToken,
  }) async {
    final response = await patch<Map<String, dynamic>>(
      '/api/admin/users/$userId/status',
      data: {'active': active},
      cancelToken: cancelToken,
    );
    return AdminUser.fromJson(response.data!);
  }

  Future<AdminUser> updateAdminUserPermissions(
    String userId,
    List<String> permissions, {
    CancelToken? cancelToken,
  }) async {
    final response = await patch<Map<String, dynamic>>(
      '/api/admin/users/$userId/permissions',
      data: {'permissions': permissions},
      cancelToken: cancelToken,
    );
    return AdminUser.fromJson(response.data!);
  }

  Future<void> deleteAdminUser(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    await delete('/api/admin/users/$userId', cancelToken: cancelToken);
  }

  // ============================================================================
  // Staff Room Status Endpoints — Requirements 27.x
  // ============================================================================

  Future<TechnicalIssue> reportRoomMaintenance(
    String roomId,
    RoomMaintenanceRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/staff/rooms/$roomId/maintenance',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return TechnicalIssue.fromJson(response.data!);
  }

  Future<TechnicalIssue> markRoomReady(
    String roomId,
    RoomReadyRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/staff/rooms/$roomId/ready',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return TechnicalIssue.fromJson(response.data!);
  }

  // ============================================================================
  // Staff Customer Support Endpoints — Requirements 28.x
  // ============================================================================

  Future<BookingModificationResult> modifyBookingSeats(
    String bookingId,
    ModifySeatsRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/staff/bookings/$bookingId/modify-seats',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return BookingModificationResult.fromJson(response.data!);
  }

  Future<BookingModificationResult> modifyBookingCombos(
    String bookingId,
    ModifyCombosRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/api/staff/bookings/$bookingId/modify-combos',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return BookingModificationResult.fromJson(response.data!);
  }

  // ============================================================================
  // Admin Payment Settings Endpoints — Requirements 26.x
  // ============================================================================

  Future<PaymentSettings> getPaymentSettings({CancelToken? cancelToken}) async {
    final response = await get<Map<String, dynamic>>(
      '/api/admin/settings/payment',
      cancelToken: cancelToken,
    );
    return PaymentSettings.fromJson(response.data!);
  }

  Future<PaymentSettings> updatePaymentSettings(
    UpdatePaymentSettingsRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await put<Map<String, dynamic>>(
      '/api/admin/settings/payment',
      data: request.toJson(),
      cancelToken: cancelToken,
    );
    return PaymentSettings.fromJson(response.data!);
  }
}
