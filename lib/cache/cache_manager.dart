import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/booking_models.dart';
import '../models/movie.dart';

/// Cache manager for offline data persistence.
///
/// **Requirements Coverage:**
/// - Requirement 35.1: Local caching for offline access
/// - Requirement 35.2: Cache bookings and movies for offline viewing
/// - Requirement 35.6: TTL management and staleness detection
///
/// Uses sqflite for local database storage with tables:
/// - cached_bookings: Booking records with timestamp
/// - cached_movies: Movie records with timestamp
/// - cached_qr_codes: QR code images as blobs
///
/// Usage:
/// ```dart
/// final cacheManager = CacheManager();
/// await cacheManager.initialize();
///
/// // Cache a booking
/// await cacheManager.cacheBooking(booking);
///
/// // Get cached bookings
/// final bookings = await cacheManager.getCachedBookings();
///
/// // Check if cache is stale
/// if (await cacheManager.isCacheStale()) {
///   // Refresh from API
/// }
/// ```
class CacheManager {
  static Database? _database;
  static const String _databaseName = 'cineluxe_cache.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _bookingsTable = 'cached_bookings';
  static const String _moviesTable = 'cached_movies';
  static const String _qrCodesTable = 'cached_qr_codes';

  // Cache TTL (Time To Live) - 1 hour for movies
  static const Duration movieCacheTTL = Duration(hours: 1);

  /// Initialize the database. Must be called before any other operations.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database with tables
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Cached bookings table
    await db.execute('''
      CREATE TABLE $_bookingsTable (
        booking_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        showtime_id TEXT NOT NULL,
        movie_title TEXT NOT NULL,
        room_name TEXT NOT NULL,
        cinema_name TEXT NOT NULL,
        showtime_date_time INTEGER NOT NULL,
        seat_codes TEXT NOT NULL,
        combos TEXT NOT NULL,
        total_amount INTEGER NOT NULL,
        status TEXT NOT NULL,
        payment_status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        qr_code TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Cached movies table
    await db.execute('''
      CREATE TABLE $_moviesTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        genres TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        director TEXT NOT NULL,
        cast TEXT NOT NULL,
        poster_url TEXT NOT NULL,
        trailer_url TEXT NOT NULL,
        rating REAL NOT NULL,
        age_rating TEXT NOT NULL,
        release_date INTEGER NOT NULL,
        status TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Cached QR codes table
    await db.execute('''
      CREATE TABLE $_qrCodesTable (
        booking_id TEXT PRIMARY KEY,
        qr_code_data BLOB NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for faster queries
    await db.execute(
      'CREATE INDEX idx_bookings_user ON $_bookingsTable(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_bookings_showtime ON $_bookingsTable(showtime_id)',
    );
    await db.execute(
      'CREATE INDEX idx_movies_status ON $_moviesTable(status)',
    );
  }

  // ============================================================================
  // Booking Cache Operations - Requirements 35.1, 35.2
  // ============================================================================

  /// Cache a single booking for offline access.
  ///
  /// **Requirement 35.1**: Store booking locally for offline viewing
  Future<void> cacheBooking(BookingDetails booking) async {
    final db = await database;
    await db.insert(
      _bookingsTable,
      {
        'booking_id': booking.bookingId,
        'user_id': booking.userId,
        'showtime_id': booking.showtimeId,
        'movie_title': booking.movieTitle,
        'room_name': booking.roomName,
        'cinema_name': booking.cinemaName,
        'showtime_date_time': booking.showtimeDateTime.millisecondsSinceEpoch,
        'seat_codes': jsonEncode(booking.seatCodes),
        'combos': jsonEncode(booking.combos),
        'total_amount': booking.totalAmount,
        'status': booking.status,
        'payment_status': booking.paymentStatus,
        'created_at': booking.createdAt.millisecondsSinceEpoch,
        'qr_code': booking.qrCode,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all cached bookings for offline viewing.
  ///
  /// **Requirement 35.2**: Retrieve cached bookings when offline
  ///
  /// Returns list of all cached bookings, ordered by showtime date (newest first).
  Future<List<BookingDetails>> getCachedBookings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _bookingsTable,
      orderBy: 'showtime_date_time DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return BookingDetails(
        bookingId: map['booking_id'] as String,
        userId: map['user_id'] as String,
        showtimeId: map['showtime_id'] as String,
        movieTitle: map['movie_title'] as String,
        roomName: map['room_name'] as String,
        cinemaName: map['cinema_name'] as String,
        showtimeDateTime: DateTime.fromMillisecondsSinceEpoch(
            map['showtime_date_time'] as int),
        seatCodes: List<String>.from(jsonDecode(map['seat_codes'] as String)),
        combos: List<String>.from(jsonDecode(map['combos'] as String)),
        totalAmount: map['total_amount'] as int,
        status: map['status'] as String,
        paymentStatus: map['payment_status'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        qrCode: map['qr_code'] as String?,
      );
    });
  }

  /// Get a specific cached booking by ID.
  ///
  /// Returns null if booking not found in cache.
  Future<BookingDetails?> getCachedBooking(String bookingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _bookingsTable,
      where: 'booking_id = ?',
      whereArgs: [bookingId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps[0];
    return BookingDetails(
      bookingId: map['booking_id'] as String,
      userId: map['user_id'] as String,
      showtimeId: map['showtime_id'] as String,
      movieTitle: map['movie_title'] as String,
      roomName: map['room_name'] as String,
      cinemaName: map['cinema_name'] as String,
      showtimeDateTime: DateTime.fromMillisecondsSinceEpoch(
          map['showtime_date_time'] as int),
      seatCodes: List<String>.from(jsonDecode(map['seat_codes'] as String)),
      combos: List<String>.from(jsonDecode(map['combos'] as String)),
      totalAmount: map['total_amount'] as int,
      status: map['status'] as String,
      paymentStatus: map['payment_status'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      qrCode: map['qr_code'] as String?,
    );
  }

  /// Clear all cached bookings.
  Future<void> clearBookingCache() async {
    final db = await database;
    await db.delete(_bookingsTable);
  }

  // ============================================================================
  // Movie Cache Operations - Requirements 35.1, 35.2, 35.6
  // ============================================================================

  /// Cache multiple movies for offline browsing.
  ///
  /// **Requirement 35.2**: Store movies locally for offline viewing
  Future<void> cacheMovies(List<Movie> movies) async {
    final db = await database;
    final batch = db.batch();

    for (final movie in movies) {
      batch.insert(
        _moviesTable,
        {
          'id': movie.id,
          'title': movie.title,
          'description': movie.description,
          'genres': jsonEncode(movie.genres),
          'duration_minutes': movie.durationMinutes,
          'director': movie.director,
          'cast': jsonEncode(movie.cast),
          'poster_url': movie.posterUrl,
          'trailer_url': movie.trailerUrl,
          'rating': movie.rating,
          'age_rating': movie.ageRating,
          'release_date': movie.releaseDate.millisecondsSinceEpoch,
          'status': movie.status,
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get all cached movies.
  ///
  /// **Requirement 35.2**: Retrieve cached movies when offline
  ///
  /// Returns list of all cached movies, ordered by release date (newest first).
  Future<List<Movie>> getCachedMovies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _moviesTable,
      orderBy: 'release_date DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return Movie(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        genres: List<String>.from(jsonDecode(map['genres'] as String)),
        durationMinutes: map['duration_minutes'] as int,
        director: map['director'] as String,
        cast: List<String>.from(jsonDecode(map['cast'] as String)),
        posterUrl: map['poster_url'] as String,
        trailerUrl: map['trailer_url'] as String,
        rating: map['rating'] as double,
        ageRating: map['age_rating'] as String,
        releaseDate:
            DateTime.fromMillisecondsSinceEpoch(map['release_date'] as int),
        status: map['status'] as String,
      );
    });
  }

  /// Check if movie cache is stale (older than 1 hour).
  ///
  /// **Requirement 35.6**: TTL management and staleness detection
  ///
  /// Returns true if cache should be refreshed from API.
  Future<bool> isCacheStale() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      _moviesTable,
      columns: ['MAX(cached_at) as latest_cache'],
    );

    if (result.isEmpty || result[0]['latest_cache'] == null) {
      return true; // No cache exists
    }

    final latestCacheTime =
        DateTime.fromMillisecondsSinceEpoch(result[0]['latest_cache'] as int);
    final now = DateTime.now();
    final age = now.difference(latestCacheTime);

    return age > movieCacheTTL;
  }

  /// Clear all cached movies.
  Future<void> clearMovieCache() async {
    final db = await database;
    await db.delete(_moviesTable);
  }

  // ============================================================================
  // QR Code Cache Operations - Requirements 10.7, 35.1
  // ============================================================================

  /// Cache QR code image for offline ticket display.
  ///
  /// **Requirements:**
  /// - 10.7: Enable offline QR code display by caching image locally
  /// - 35.1: Store QR code PNG as blob in database
  ///
  /// Stores QR code image data as binary blob for offline access.
  /// Critical for entering cinema with unstable connectivity.
  ///
  /// Parameters:
  /// - [bookingId]: The booking ID associated with this QR code
  /// - [imageData]: QR code image as PNG bytes
  ///
  /// Example:
  /// ```dart
  /// final qrImage = await generateQRCode(bookingId);
  /// await cacheManager.cacheQRCode(bookingId, qrImage);
  /// ```
  Future<void> cacheQRCode(String bookingId, List<int> imageData) async {
    final db = await database;
    await db.insert(
      _qrCodesTable,
      {
        'booking_id': bookingId,
        'qr_code_data': imageData,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve cached QR code image for offline display.
  ///
  /// **Requirements:**
  /// - 10.7: Load QR code from cache for offline ticket display
  /// - 35.1: Retrieve QR code PNG blob from database
  ///
  /// Returns QR code image as PNG bytes, or null if not found in cache.
  ///
  /// Example:
  /// ```dart
  /// final qrImage = await cacheManager.getCachedQRCode(bookingId);
  /// if (qrImage != null) {
  ///   // Display QR code from cache
  ///   Image.memory(Uint8List.fromList(qrImage));
  /// } else {
  ///   // Fetch from API
  /// }
  /// ```
  Future<List<int>?> getCachedQRCode(String bookingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _qrCodesTable,
      columns: ['qr_code_data'],
      where: 'booking_id = ?',
      whereArgs: [bookingId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return maps[0]['qr_code_data'] as List<int>;
  }

  /// Delete a specific cached QR code.
  ///
  /// Useful for clearing outdated or cancelled booking QR codes.
  Future<void> deleteCachedQRCode(String bookingId) async {
    final db = await database;
    await db.delete(
      _qrCodesTable,
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );
  }

  /// Get the timestamp when a QR code was cached.
  ///
  /// Returns null if QR code not found in cache.
  Future<DateTime?> getQRCodeCacheTime(String bookingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _qrCodesTable,
      columns: ['cached_at'],
      where: 'booking_id = ?',
      whereArgs: [bookingId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return DateTime.fromMillisecondsSinceEpoch(maps[0]['cached_at'] as int);
  }

  // ============================================================================
  // General Cache Operations
  // ============================================================================

  /// Get cache statistics.
  ///
  /// Returns a map with cache statistics including:
  /// - bookingsCount: Number of cached bookings
  /// - moviesCount: Number of cached movies
  /// - qrCodesCount: Number of cached QR codes
  /// - totalSize: Approximate size in bytes
  Future<Map<String, dynamic>> getCacheStats() async {
    final db = await database;

    final bookingsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_bookingsTable'),
    );
    final moviesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_moviesTable'),
    );
    final qrCodesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_qrCodesTable'),
    );

    return {
      'bookingsCount': bookingsCount ?? 0,
      'moviesCount': moviesCount ?? 0,
      'qrCodesCount': qrCodesCount ?? 0,
      'cacheStale': await isCacheStale(),
    };
  }

  /// Clear all cache data.
  Future<void> clearAllCache() async {
    await clearBookingCache();
    await clearMovieCache();
    final db = await database;
    await db.delete(_qrCodesTable);
  }

  /// Close the database connection.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
