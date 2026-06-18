import 'dart:async';

import '../api/api_client.dart';
import '../api/exceptions/api_exceptions.dart';
import '../cache/cache_manager.dart';
import '../models/movie.dart';
import '../models/paginated_response.dart';
import '../utils/connectivity_service.dart';

/// Result of a movie fetch — `fromCache` lets the UI render the
/// "Showing cached results" indicator when applicable.
class MovieResult {
  const MovieResult({
    required this.items,
    required this.fromCache,
    this.cachedAt,
  });

  final List<Movie> items;
  final bool fromCache;
  final DateTime? cachedAt;
}

/// Repository for movies. Single concrete class (no interface per project
/// convention; the public API is the class itself). Owns its sync logic
/// and stale-while-revalidate behavior.
///
/// Usage:
/// ```dart
/// final result = await MovieRepository().getMovies(status: 'nowShowing');
/// // result.items       → list of movies
/// // result.fromCache   → true if served from sqflite
/// // result.cachedAt    → timestamp of last cache write
/// ```
class MovieRepository {
  MovieRepository._({
    APIClient? api,
    CacheManager? cache,
    ConnectivityService? connectivity,
  })  : _api = api ?? APIClient(),
        _cache = cache ?? CacheManager(),
        _connectivity = connectivity ?? ConnectivityService();

  static MovieRepository? _instance;
  factory MovieRepository() =>
      _instance ??= MovieRepository._();

  final APIClient _api;
  final CacheManager _cache;
  final ConnectivityService _connectivity;

  final StreamController<void> _changes = StreamController<void>.broadcast();
  StreamSubscription? _connSub;

  /// Broadcasts a `null` event whenever the cache is written, so screens
  /// can re-render without polling.
  Stream<void> get changes => _changes.stream;

  /// Fetches movies with stale-while-revalidate semantics.
  ///
  /// - If [forceRefresh] is `true`, always hits the API.
  /// - Otherwise: if offline or cache is fresh, returns cached data
  ///   immediately and triggers a background sync.
  /// - If API call fails, falls back to the cache (even if the cache
  ///   would normally have been considered stale).
  Future<MovieResult> getMovies({
    String? search,
    String? genre,
    String? status,
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    final online = _connectivity.isOnline;
    final stale = await _cache.isMoviesStale();
    final lastWritten = await _cache.moviesLastWrittenAt();

    if (!forceRefresh && (!online || !stale)) {
      // Background refresh — fire-and-forget, don't block the UI.
      if (online) {
        unawaited(_backgroundSync(search: search, genre: genre, status: status,
            page: page, pageSize: pageSize));
      }
      final cached = await _cache.readMovies(limit: pageSize);
      return MovieResult(
        items: cached,
        fromCache: true,
        cachedAt: lastWritten,
      );
    }

    try {
      final response = await _api.getMovies(
        search: search,
        genre: genre,
        status: status,
        page: page,
        pageSize: pageSize,
      );
      return await _writeAndReturn(response, lastWritten);
    } on ApiNetworkException {
      final cached = await _cache.readMovies(limit: pageSize);
      return MovieResult(
        items: cached,
        fromCache: true,
        cachedAt: lastWritten,
      );
    }
  }

  Future<MovieResult> _writeAndReturn(
    PaginatedResponse<Movie> response,
    DateTime? previousCachedAt,
  ) async {
    final now = DateTime.now();
    await _cache.upsertMovies(response.data);
    if (!_changes.isClosed) _changes.add(null);
    return MovieResult(
      items: response.data,
      fromCache: false,
      cachedAt: now,
    );
  }

  /// Background sync — used by the stale-while-revalidate path. Errors
  /// are swallowed because this is fire-and-forget.
  Future<void> _backgroundSync({
    String? search,
    String? genre,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _api.getMovies(
        search: search,
        genre: genre,
        status: status,
        page: page,
        pageSize: pageSize,
      );
      await _cache.upsertMovies(response.data);
      if (!_changes.isClosed) _changes.add(null);
    } catch (_) {
      // Background sync is best-effort.
    }
  }

  /// Public sync entry point — explicitly fetches from the API and updates
  /// the cache. Returns `true` if the sync succeeded.
  Future<bool> syncMovies() async {
    try {
      final response = await _api.getMovies();
      await _cache.upsertMovies(response.data);
      if (!_changes.isClosed) _changes.add(null);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Subscribes to connectivity changes; triggers a sync on every
  /// online transition. Idempotent — calling twice is a no-op.
  void startAutoSync() {
    if (_connSub != null) return;
    _connSub = _connectivity.connectivityStream.listen((online) {
      if (online) {
        unawaited(syncMovies());
      }
    });
  }

  /// Cancels the connectivity subscription. Safe to call multiple times.
  Future<void> stopAutoSync() async {
    await _connSub?.cancel();
    _connSub = null;
  }

  Future<void> dispose() async {
    await stopAutoSync();
    await _changes.close();
  }
}
