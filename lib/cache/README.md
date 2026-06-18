# Cache

Local persistence layer for offline access to bookings, movies, and QR codes.

## Public API

Only the **Repository layer** is part of the public API. Screens and
services should depend on a Repository, not on `CacheManager`.

| Class | Path | Purpose |
|---|---|---|
| `MovieRepository` | `lib/repositories/movie_repository.dart` | Movies with stale-while-revalidate fetch + auto-sync |
| `BookingRepository` | `lib/repositories/booking_repository.dart` | Bookings + QR code image caching + auto-sync |

### `MovieRepository`

```dart
final result = await MovieRepository().getMovies(
  status: 'nowShowing',
  forceRefresh: false,
);
// result.items       -> List<Movie>
// result.fromCache   -> bool
// result.cachedAt    -> DateTime?
```

- `getMovies(...)` — stale-while-revalidate. Falls back to cache on
  `ApiNetworkException`.
- `syncMovies()` — explicit API→cache sync. Returns `bool`.
- `startAutoSync()` / `stopAutoSync()` — subscribe to connectivity stream
  and re-sync on every online transition.
- `Stream<void> get changes` — broadcasts on every cache write.

### `BookingRepository`

```dart
final bookings = await BookingRepository().getUserBookings(
  userId,
  status: 'active',
);

final qr = await BookingRepository().getBookingQr(bookingId);
// On success, the QR is rendered to PNG and stored as a BLOB for offline use.
final cached = await BookingRepository().getCachedQRCode(bookingId);
// cached != null if a previous successful fetch cached the image.
```

- `getUserBookings(userId, ...)` — stale-while-revalidate. Falls back to
  cache on `ApiNetworkException`.
- `getBookingDetails(bookingId)` — single booking. Falls back to cache.
- `getBookingQr(bookingId)` — fetches QR via API and **transparently
  caches a 512×512 PNG** of the QR for offline display. Returns `null` on
  network failure.
- `getCachedQRCode(bookingId)` — direct read of the cached PNG bytes.
- `syncUserBookings(userId)` — explicit sync entry point.
- `startAutoSync()` / `stopAutoSync()` — auto-sync on connectivity change.
- `Stream<void> get changes`.

## Internal Layer (package-private)

| Class | Path | Purpose |
|---|---|---|
| `CacheDatabase` | `lib/cache/cache_database.dart` | sqflite open + versioned migration |
| `CacheManager` | `lib/cache/cache_manager.dart` | Batch-transaction helper used only by Repositories |

These are marked `@visibleForTesting` and should not be imported by UI or
service code. The Repositories are the only public surface.

## Storage Backend

- **Engine:** sqflite
- **File:** `cinema_cache.db` under `getApplicationDocumentsDirectory()`
- **Version:** 1 (`CacheDatabase._version`)

### Schema v1

| Table | Columns |
|---|---|
| `cached_movies` | `movie_id TEXT PK`, `data TEXT` (JSON), `cached_at INTEGER` |
| `cached_bookings` | `booking_id TEXT PK`, `data TEXT` (JSON), `cached_at INTEGER` |
| `cached_qr_codes` | `booking_id TEXT PK`, `image_data BLOB`, `cached_at INTEGER` |
| `idx_bookings_cached_at` | index on `cached_bookings.cached_at` |

### Migration policy

1. Bump `CacheDatabase._version`.
2. Add a step in `CacheDatabase._onUpgrade` that migrates from `oldV` to
   `oldV + 1` per version increment, inside a single `db.transaction`.

## Sync Strategy

- **Stale-While-Revalidate** — `MovieRepository.getMovies` returns cached
  data immediately when the cache is fresh, then refreshes in the
  background. The UI shows the cached data with a "Showing cached
  results" banner; when the background refresh lands, the
  `repository.changes` stream fires and the UI re-renders.
- **Connectivity-driven auto-sync** — each Repository exposes
  `startAutoSync()` which subscribes to `ConnectivityService`. On every
  online transition, the Repository re-syncs its data source. The
  service tracks which user IDs have been queried for booking auto-sync.
- **Batch transactions** — `CacheManager.upsertMovies` and
  `upsertBookings` open a single transaction and use `Batch.commit` for
  N rows, so large lists are written atomically.

## Offline Mode Features

### Supported Offline
- View booking history (`ApiTicketsScreen`).
- Display cached QR code ticket (`BookingConfirmationScreen`).
- Browse cached movie list and the "Showing cached results" banner
  (`MovieListScreen`).

### Indicators
- A compact amber/danger `CacheBanner` widget
  (`lib/src/shared/widgets/cache_banner.dart`) renders the offline state
  and last-sync timestamp.
- A "Cached" chip on individual booking cards.

### Not Supported Offline
- Seat selection and booking creation
- Payment processing
- Review submission
- Profile updates

## Related Modules

- `lib/repositories/` — public API for the cache layer
- `lib/models/` — data structures serialized into sqflite
- `lib/utils/connectivity_service.dart` — connectivity stream
- `lib/api/` — `APIClient` used by the Repositories for sync
- `lib/src/shared/widgets/cache_banner.dart` — the offline indicator UI
