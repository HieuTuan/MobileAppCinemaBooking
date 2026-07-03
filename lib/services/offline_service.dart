import '../cache/cache_manager.dart';
import '../api/api_client.dart';
import '../models/booking_models.dart';
import '../models/movie.dart';
import '../utils/connectivity_monitor.dart';

/// Service for managing offline data with cache fallback.
///
/// **Requirements Coverage:**
/// - Requirement 35.3: Display cached bookings with offline indicator
/// - Requirement 35.4: Display cached movies with "Showing cached results" banner
/// - Requirement 35.8: Load QR code from cache for offline ticket display
///
/// Provides seamless online/offline data access with automatic fallback.
///
/// Usage:
/// ```dart
/// final service = OfflineService();
///
/// // Get bookings (online or cached)
/// final result = await service.getBookings(userId);
/// if (result.isFromCache) {
///   // Show offline banner
/// }
/// ```
class OfflineService {
  final CacheManager _cacheManager;
  final APIClient _apiClient;

  OfflineService({
    CacheManager? cacheManager,
    APIClient? apiClient,
  })  : _cacheManager = cacheManager ?? CacheManager(),
        _apiClient = apiClient ?? APIClient();

  /// Get bookings with offline fallback.
  ///
  /// **Requirement 35.3**: Display cached bookings when network unavailable
  ///
  /// Flow:
  /// 1. Check connectivity
  /// 2. If online: fetch from API and cache
  /// 3. If offline: load from cache
  ///
  /// Returns OfflineResult with data and cache status.
  Future<OfflineResult<List<BookingDetails>>> getBookings(
    String userId, {
    String? status,
  }) async {
    final isOnline = await ConnectivityMonitor.checkConnectivity();

    if (isOnline) {
      try {
        // Fetch fresh data from API
        final response = await _apiClient.getUserBookings(userId, status: status);
        final bookings = response.data;

        // Cache each booking for offline access
        for (final booking in bookings) {
          await _cacheManager.cacheBooking(booking);
        }

        return OfflineResult<List<BookingDetails>>(
          data: bookings,
          isFromCache: false,
          timestamp: DateTime.now(),
        );
      } catch (e) {
        // API failed, fall back to cache
        final cachedBookings = await _cacheManager.getCachedBookings();
        return OfflineResult<List<BookingDetails>>(
          data: cachedBookings,
          isFromCache: true,
          timestamp: null,
          error: e.toString(),
        );
      }
    } else {
      // Offline mode - load from cache
      final cachedBookings = await _cacheManager.getCachedBookings();
      return OfflineResult<List<BookingDetails>>(
        data: cachedBookings,
        isFromCache: true,
        timestamp: null,
      );
    }
  }

  /// Get movies with offline fallback.
  ///
  /// **Requirement 35.4**: Display cached movies with "Showing cached results" banner
  ///
  /// Flow:
  /// 1. Check connectivity
  /// 2. If online: fetch from API and cache
  /// 3. If offline: load from cache
  ///
  /// Returns OfflineResult with data and cache status.
  Future<OfflineResult<List<Movie>>> getMovies({
    String? search,
    String? genre,
    String? status,
  }) async {
    final isOnline = await ConnectivityMonitor.checkConnectivity();

    if (isOnline) {
      try {
        // Fetch fresh data from API
        final response = await _apiClient.getMovies(
          search: search,
          genre: genre,
          status: status,
        );

        // Cache movies for offline access
        await _cacheManager.cacheMovies(response.data);

        return OfflineResult<List<Movie>>(
          data: response.data,
          isFromCache: false,
          timestamp: DateTime.now(),
        );
      } catch (e) {
        // API failed, fall back to cache
        final cachedMovies = await _cacheManager.getCachedMovies();
        return OfflineResult<List<Movie>>(
          data: cachedMovies,
          isFromCache: true,
          timestamp: null,
          error: e.toString(),
        );
      }
    } else {
      // Offline mode - load from cache
      final cachedMovies = await _cacheManager.getCachedMovies();
      return OfflineResult<List<Movie>>(
        data: cachedMovies,
        isFromCache: true,
        timestamp: null,
      );
    }
  }

  /// Get a specific booking with offline fallback.
  ///
  /// **Requirement 35.3**: Display cached booking details when offline
  ///
  /// Useful for booking detail screens.
  Future<OfflineResult<BookingDetails?>> getBookingDetails(
    String bookingId,
  ) async {
    final isOnline = await ConnectivityMonitor.checkConnectivity();

    if (isOnline) {
      try {
        // Fetch fresh data from API
        final booking = await _apiClient.getBookingDetails(bookingId);

        // Cache for offline access
        await _cacheManager.cacheBooking(booking);

        return OfflineResult<BookingDetails?>(
          data: booking,
          isFromCache: false,
          timestamp: DateTime.now(),
        );
      } catch (e) {
        // API failed, fall back to cache
        final cachedBooking = await _cacheManager.getCachedBooking(bookingId);
        return OfflineResult<BookingDetails?>(
          data: cachedBooking,
          isFromCache: true,
          timestamp: null,
          error: e.toString(),
        );
      }
    } else {
      // Offline mode - load from cache
      final cachedBooking = await _cacheManager.getCachedBooking(bookingId);
      return OfflineResult<BookingDetails?>(
        data: cachedBooking,
        isFromCache: true,
        timestamp: null,
      );
    }
  }

  /// Check if device is currently online.
  ///
  /// Helper method for UI to show/hide offline banners.
  Future<bool> isOnline() async {
    return await ConnectivityMonitor.checkConnectivity();
  }

  /// Get cache statistics.
  ///
  /// Useful for settings screen to show cache status.
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheManager.getCacheStats();
  }

  /// Check if movie cache is stale and should be refreshed.
  ///
  /// **Requirement 35.6**: TTL management
  Future<bool> shouldRefreshMovieCache() async {
    return await _cacheManager.isCacheStale();
  }

  /// Clear all cached data.
  ///
  /// Useful for "Clear Cache" button in settings.
  Future<void> clearAllCache() async {
    await _cacheManager.clearAllCache();
  }
}

/// Result wrapper for offline operations.
///
/// Contains data and metadata about cache status.
class OfflineResult<T> {
  /// The actual data (from API or cache)
  final T data;

  /// Whether data was loaded from cache (true) or API (false)
  final bool isFromCache;

  /// Timestamp of when data was fetched from API (null if from cache)
  final DateTime? timestamp;

  /// Error message if API failed and fell back to cache
  final String? error;

  OfflineResult({
    required this.data,
    required this.isFromCache,
    this.timestamp,
    this.error,
  });

  /// Whether this is fresh data from API
  bool get isFresh => !isFromCache;

  /// Whether API failed and fell back to cache
  bool get hadError => error != null;
}
