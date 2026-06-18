import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Centralized sqflite opening + version management for the cache layer.
///
/// Schema versioning follows this policy:
/// - Bump [_version] whenever a table is added, dropped, or its columns change.
/// - Add a step in [_onUpgrade] that migrates from `oldV` to `oldV + 1` per
///   version increment, inside a single `db.transaction` so partial upgrades
///   cannot leave the database in a half-migrated state.
class CacheDatabase {
  static const int _version = 1;
  static const String _dbName = 'cinema_cache.db';

  // Schema constants — referenced by [CacheManager] to avoid string drift.
  static const String tableMovies = 'cached_movies';
  static const String tableBookings = 'cached_bookings';
  static const String tableQRCodes = 'cached_qr_codes';

  static const String colId = 'id';
  static const String colMovieId = 'movie_id';
  static const String colBookingId = 'booking_id';
  static const String colData = 'data';
  static const String colImageData = 'image_data';
  static const String colCachedAt = 'cached_at';

  Database? _db;

  /// Returns an opened [Database], lazily creating it on first call.
  Future<Database> open() async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    final db = await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _db = db;
    return db;
  }

  /// Closes the underlying database handle. Idempotent.
  Future<void> close() async {
    final db = _db;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _db = null;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableMovies (
        $colMovieId TEXT PRIMARY KEY,
        $colData TEXT NOT NULL,
        $colCachedAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $tableBookings (
        $colBookingId TEXT PRIMARY KEY,
        $colData TEXT NOT NULL,
        $colCachedAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_bookings_cached_at
        ON $tableBookings ($colCachedAt)
    ''');
    await db.execute('''
      CREATE TABLE $tableQRCodes (
        $colBookingId TEXT PRIMARY KEY,
        $colImageData BLOB NOT NULL,
        $colCachedAt INTEGER NOT NULL
      )
    ''');
  }

  /// Migration ladder. Run each step inside a single transaction.
  /// Add a new step here every time [_version] is bumped.
  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    await db.transaction((txn) async {
      // No migration steps yet — single version.
      // Example for a future v1 → v2:
      //   if (oldV < 2) {
      //     await txn.execute('ALTER TABLE ...');
      //   }
    });
  }
}
