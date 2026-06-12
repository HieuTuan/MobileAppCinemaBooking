import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/secure_storage_service.dart';
import '../models/movie.dart';
import '../models/review.dart';
import '../models/showtime.dart';
import '../models/paginated_response.dart';
import '../models/booking_models.dart';
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
}
