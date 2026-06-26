import 'dart:async';

import '../api/api_client.dart';
import '../api/exceptions/api_exceptions.dart';
import '../cache/cache_manager.dart';
import '../models/movie.dart';
import '../models/paginated_response.dart';
import '../utils/connectivity_service.dart';

/// Result of a movie fetch. `fromCache` lets the UI render the
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
/// // result.items       -> list of movies
/// // result.fromCache   -> true if served from sqflite
/// // result.cachedAt    -> timestamp of last cache write
/// ```
class MovieRepository {
  MovieRepository._({
    APIClient? api,
    CacheManager? cache,
    ConnectivityService? connectivity,
  }) : _api = api ?? APIClient(),
       _cache = cache ?? CacheManager(),
       _connectivity = connectivity ?? ConnectivityService();

  static MovieRepository? _instance;
  factory MovieRepository() => _instance ??= MovieRepository._();

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
  /// - Otherwise: if offline or cache is fresh, returns cached data immediately.
  /// - If API call fails, falls back to the cache.
  Future<MovieResult> getMovies({
    String? search,
    String? genre,
    String? status,
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    final online = _connectivity.isOnline;
    var stale = true;
    DateTime? lastWritten;
    try {
      stale = await _cache.isMoviesStale();
      lastWritten = await _cache.moviesLastWrittenAt();
    } catch (_) {
      // Cache backends are optional on web/local runs. A cache failure should
      // not block fresh API data from rendering.
    }

    if (!forceRefresh && (!online || !stale)) {
      try {
        final cached = await _cache.readMovies(limit: pageSize);
        return MovieResult(
          items: cached,
          fromCache: true,
          cachedAt: lastWritten,
        );
      } catch (_) {
        if (!online) rethrow;
      }
    }

    try {
      final response = await _api.getMovies(
        search: search,
        genre: genre,
        status: status,
        page: page,
        pageSize: pageSize,
      );
      return await _writeAndReturn(response);
    } on ApiNetworkException {
      try {
        final cached = await _cache.readMovies(limit: pageSize);
        return MovieResult(
          items: cached,
          fromCache: true,
          cachedAt: lastWritten,
        );
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<MovieResult> _writeAndReturn(PaginatedResponse<Movie> response) async {
    final now = DateTime.now();
    try {
      await _cache.upsertMovies(response.data);
    } catch (_) {
      return MovieResult(
        items: response.data,
        fromCache: false,
        cachedAt: null,
      );
    }
    return MovieResult(items: response.data, fromCache: false, cachedAt: now);
  }

  /// Explicitly fetches from the API and updates the cache.
  /// Returns `true` if the sync succeeded.
  Future<bool> syncMovies() async {
    try {
      final cached = await _cache.readMovies();
      final response = await _api.getMovies();
      await _cache.upsertMovies(response.data);
      if (!_changes.isClosed && _movieListsDiffer(cached, response.data)) {
        _changes.add(null);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _movieListsDiffer(List<Movie> previous, List<Movie> next) {
    if (previous.length != next.length) return true;
    for (var i = 0; i < previous.length; i++) {
      if (_movieFingerprint(previous[i]) != _movieFingerprint(next[i])) {
        return true;
      }
    }
    return false;
  }

  String _movieFingerprint(Movie movie) {
    return [
      movie.id,
      movie.title,
      movie.description,
      movie.genres.join('|'),
      movie.durationMinutes,
      movie.director,
      movie.cast.join('|'),
      movie.posterUrl,
      movie.trailerUrl,
      movie.rating,
      movie.ageRating,
      movie.releaseDate.toIso8601String(),
      movie.status,
    ].join('::');
  }

  /// Subscribes to connectivity changes; triggers a sync on every
  /// online transition. Idempotent: calling twice is a no-op.
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
