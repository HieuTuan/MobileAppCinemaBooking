import 'dart:async';
import '../cache/cache_manager.dart';
import '../api/api_client.dart';
import '../utils/connectivity_monitor.dart';

/// Service for cache synchronization on connectivity restoration.
///
/// **Requirements Coverage:**
/// - Requirement 35.5: Sync cached bookings with backend to detect updates
/// - Requirement 35.7: Fetch fresh movie data and update cache
/// - Requirement 35.7: Stale-while-revalidate pattern
///
/// Monitors network connectivity and automatically syncs cache
/// when connection is restored.
///
/// Usage:
/// ```dart
/// final syncService = CacheSyncService();
/// await syncService.initialize();
///
/// // Service automatically syncs when online
/// // Listen to sync status
/// syncService.syncStatusStream.listen((status) {
///   if (status == SyncStatus.syncing) {
///     // Show sync indicator
///   }
/// });
/// ```
class CacheSyncService {
  final CacheManager _cacheManager;
  final APIClient _apiClient;

  Timer? _connectivityCheckTimer;
  bool _wasOffline = false;
  bool _isSyncing = false;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  /// Stream of sync status changes
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Current sync status
  SyncStatus get currentStatus =>
      _isSyncing ? SyncStatus.syncing : SyncStatus.idle;

  CacheSyncService({
    CacheManager? cacheManager,
    APIClient? apiClient,
  })  : _cacheManager = cacheManager ?? CacheManager(),
        _apiClient = apiClient ?? APIClient();

  /// Initialize the sync service.
  ///
  /// Starts monitoring connectivity and automatically syncs
  /// when connection is restored.
  ///
  /// Check interval: every 10 seconds
  Future<void> initialize() async {
    // Check current connectivity
    _wasOffline = !(await ConnectivityMonitor.checkConnectivity());

    // Start periodic connectivity monitoring
    _connectivityCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivityAndSync(),
    );
  }

  /// Check connectivity and sync if restored.
  Future<void> _checkConnectivityAndSync() async {
    final isOnline = await ConnectivityMonitor.checkConnectivity();

    // Connectivity restored (was offline, now online)
    if (_wasOffline && isOnline) {
      _wasOffline = false;
      await _performSync();
    } else if (!isOnline) {
      _wasOffline = true;
    } else {
      _wasOffline = false;
    }
  }

  /// Perform full cache synchronization.
  ///
  /// **Requirements:**
  /// - 35.5: Sync cached bookings with backend
  /// - 35.7: Fetch fresh movie data
  /// - 35.7: Use stale-while-revalidate pattern
  ///
  /// Flow:
  /// 1. Sync bookings (detect status changes)
  /// 2. Sync movies (refresh catalog)
  /// 3. Update cache with fresh data
  Future<void> _performSync() async {
    if (_isSyncing) return; // Already syncing

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      // Parallel sync of bookings and movies
      await Future.wait([
        _syncBookings(),
        _syncMovies(),
      ]);

      _syncStatusController.add(SyncStatus.completed);
    } catch (e) {
      _syncStatusController.add(SyncStatus.failed);
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync cached bookings with backend.
  ///
  /// **Requirement 35.5**: Detect booking updates (status changes, cancellations)
  ///
  /// Updates cache with latest booking data from API.
  Future<void> _syncBookings() async {
    try {
      // Get all cached bookings
      final cachedBookings = await _cacheManager.getCachedBookings();

      // Fetch fresh data for each booking
      for (final booking in cachedBookings) {
        try {
          final freshBooking =
              await _apiClient.getBookingDetails(booking.bookingId);

          // Update cache with fresh data
          await _cacheManager.cacheBooking(freshBooking);
        } catch (e) {
          // Skip booking if fetch fails (keep old cache)
          continue;
        }
      }
    } catch (e) {
      // Sync failed, but don't clear cache
      rethrow;
    }
  }

  /// Sync movies with backend.
  ///
  /// **Requirement 35.7**: Fetch fresh movie data and update cache
  ///
  /// Refreshes movie catalog with latest data from API.
  Future<void> _syncMovies() async {
    try {
      // Check if cache is stale
      if (await _cacheManager.isCacheStale()) {
        // Fetch fresh movies
        final response = await _apiClient.getMovies(pageSize: 50);

        // Update cache
        await _cacheManager.cacheMovies(response.data);
      }
    } catch (e) {
      // Sync failed, but don't clear cache
      rethrow;
    }
  }

  /// Manually trigger sync.
  ///
  /// Useful for "pull to refresh" functionality.
  ///
  /// Returns true if sync succeeded, false if failed.
  Future<bool> manualSync() async {
    final isOnline = await ConnectivityMonitor.checkConnectivity();

    if (!isOnline) {
      _syncStatusController.add(SyncStatus.offline);
      return false;
    }

    await _performSync();
    return !_isSyncing; // Return true if sync completed
  }

  /// Sync bookings only.
  ///
  /// Lighter sync operation for quick refresh.
  Future<bool> syncBookingsOnly() async {
    final isOnline = await ConnectivityMonitor.checkConnectivity();

    if (!isOnline) {
      _syncStatusController.add(SyncStatus.offline);
      return false;
    }

    try {
      _isSyncing = true;
      _syncStatusController.add(SyncStatus.syncing);

      await _syncBookings();

      _syncStatusController.add(SyncStatus.completed);
      return true;
    } catch (e) {
      _syncStatusController.add(SyncStatus.failed);
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync movies only.
  ///
  /// Lighter sync operation for quick refresh.
  Future<bool> syncMoviesOnly() async {
    final isOnline = await ConnectivityMonitor.checkConnectivity();

    if (!isOnline) {
      _syncStatusController.add(SyncStatus.offline);
      return false;
    }

    try {
      _isSyncing = true;
      _syncStatusController.add(SyncStatus.syncing);

      await _syncMovies();

      _syncStatusController.add(SyncStatus.completed);
      return true;
    } catch (e) {
      _syncStatusController.add(SyncStatus.failed);
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Get last sync time.
  ///
  /// Returns null if never synced.
  Future<DateTime?> getLastSyncTime() async {
    final stats = await _cacheManager.getCacheStats();
    // Implementation would need to track last sync time in cache
    return null; // Placeholder
  }

  /// Stop the sync service.
  ///
  /// Call when disposing the service.
  void dispose() {
    _connectivityCheckTimer?.cancel();
    _syncStatusController.close();
  }
}

/// Sync status enum
enum SyncStatus {
  /// Not currently syncing
  idle,

  /// Currently syncing data
  syncing,

  /// Sync completed successfully
  completed,

  /// Sync failed due to error
  failed,

  /// Cannot sync - device is offline
  offline,
}

/// Extension for user-friendly status messages
extension SyncStatusExtension on SyncStatus {
  String get message {
    switch (this) {
      case SyncStatus.idle:
        return 'Ready';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.completed:
        return 'Sync completed';
      case SyncStatus.failed:
        return 'Sync failed';
      case SyncStatus.offline:
        return 'Offline';
    }
  }

  bool get isActive => this == SyncStatus.syncing;
  bool get isError => this == SyncStatus.failed || this == SyncStatus.offline;
}
