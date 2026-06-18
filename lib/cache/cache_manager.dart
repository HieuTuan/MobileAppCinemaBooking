import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';

import '../models/booking_models.dart';
import '../models/movie.dart';
import 'cache_database.dart';

/// Package-private batch-transaction helper used by the Repository layer.
///
/// Marked [visibleForTesting] so unit tests can subclass or stub it, but the
/// `@visibleForTesting` annotation signals that **only Repositories** are
/// expected to depend on this class — screens and services should depend on
/// a Repository instead.
@visibleForTesting
class CacheManager {
  CacheManager._();

  static final CacheManager _instance = CacheManager._();
  factory CacheManager() => _instance;

  final CacheDatabase _database = CacheDatabase();

  Future<Database> get _db => _database.open();

  // ─── Movie batch ops ────────────────────────────────────────────

  /// Upserts [movies] in a single transaction. Sets `cached_at = now` for
  /// every row in the batch. Returns the number of rows written.
  Future<int> upsertMovies(List<Movie> movies) async {
    if (movies.isEmpty) return 0;
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction((txn) async {
      final batch = txn.batch();
      for (final m in movies) {
        batch.rawInsert(
          '''
          INSERT OR REPLACE INTO ${CacheDatabase.tableMovies}
            (${CacheDatabase.colMovieId},
             ${CacheDatabase.colData},
             ${CacheDatabase.colCachedAt})
          VALUES (?, ?, ?)
          ''',
          [m.id, jsonEncode(m.toJson()), now],
        );
      }
      final results = await batch.commit(noResult: false);
      return results.length;
    });
  }

  Future<List<Movie>> readMovies({int? limit}) async {
    final db = await _db;
    final rows = await db.query(
      CacheDatabase.tableMovies,
      orderBy: '${CacheDatabase.colCachedAt} DESC',
      limit: limit,
    );
    return rows
        .map((r) => Movie.fromJson(
              jsonDecode(r[CacheDatabase.colData] as String) as Map<String, dynamic>,
            ))
        .toList(growable: false);
  }

  Future<Movie?> readMovie(String movieId) async {
    final db = await _db;
    final rows = await db.query(
      CacheDatabase.tableMovies,
      where: '${CacheDatabase.colMovieId} = ?',
      whereArgs: [movieId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Movie.fromJson(
      jsonDecode(rows.first[CacheDatabase.colData] as String) as Map<String, dynamic>,
    );
  }

  Future<DateTime?> moviesLastWrittenAt() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT MAX(${CacheDatabase.colCachedAt}) AS m FROM ${CacheDatabase.tableMovies}',
    );
    final value = rows.first['m'] as int?;
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  Future<bool> isMoviesStale({Duration ttl = const Duration(hours: 1)}) async {
    final last = await moviesLastWrittenAt();
    if (last == null) return true;
    return DateTime.now().difference(last) > ttl;
  }

  Future<int> deleteStaleMovies(DateTime olderThan) async {
    final db = await _db;
    return db.delete(
      CacheDatabase.tableMovies,
      where: '${CacheDatabase.colCachedAt} < ?',
      whereArgs: [olderThan.millisecondsSinceEpoch],
    );
  }

  // ─── Booking batch ops ──────────────────────────────────────────

  Future<int> upsertBookings(List<BookingDetails> bookings) async {
    if (bookings.isEmpty) return 0;
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction((txn) async {
      final batch = txn.batch();
      for (final b in bookings) {
        batch.rawInsert(
          '''
          INSERT OR REPLACE INTO ${CacheDatabase.tableBookings}
            (${CacheDatabase.colBookingId},
             ${CacheDatabase.colData},
             ${CacheDatabase.colCachedAt})
          VALUES (?, ?, ?)
          ''',
          [b.bookingId, jsonEncode(b.toJson()), now],
        );
      }
      final results = await batch.commit(noResult: false);
      return results.length;
    });
  }

  Future<List<BookingDetails>> readBookings({String? status}) async {
    final db = await _db;
    final rows = await db.query(
      CacheDatabase.tableBookings,
      orderBy: '${CacheDatabase.colCachedAt} DESC',
    );
    final all = rows
        .map((r) => BookingDetails.fromJson(
              jsonDecode(r[CacheDatabase.colData] as String) as Map<String, dynamic>,
            ))
        .toList(growable: false);
    if (status == null) return all;
    return all.where((b) => b.status == status).toList(growable: false);
  }

  Future<BookingDetails?> readBooking(String bookingId) async {
    final db = await _db;
    final rows = await db.query(
      CacheDatabase.tableBookings,
      where: '${CacheDatabase.colBookingId} = ?',
      whereArgs: [bookingId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BookingDetails.fromJson(
      jsonDecode(rows.first[CacheDatabase.colData] as String) as Map<String, dynamic>,
    );
  }

  // ─── QR Code ops ────────────────────────────────────────────────

  Future<void> upsertQRCode(String bookingId, Uint8List image) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      CacheDatabase.tableQRCodes,
      {
        CacheDatabase.colBookingId: bookingId,
        CacheDatabase.colImageData: image,
        CacheDatabase.colCachedAt: now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Uint8List?> readQRCode(String bookingId) async {
    final db = await _db;
    final rows = await db.query(
      CacheDatabase.tableQRCodes,
      where: '${CacheDatabase.colBookingId} = ?',
      whereArgs: [bookingId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first[CacheDatabase.colImageData] as Uint8List;
  }

  // ─── Maintenance ────────────────────────────────────────────────

  Future<void> clearAll() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(CacheDatabase.tableMovies);
      await txn.delete(CacheDatabase.tableBookings);
      await txn.delete(CacheDatabase.tableQRCodes);
    });
  }

  Future<void> close() => _database.close();
}
