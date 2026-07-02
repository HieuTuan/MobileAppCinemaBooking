import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/exceptions/api_exceptions.dart';
import '../cache/cache_manager.dart';
import '../models/booking_models.dart';
import '../utils/connectivity_service.dart';

/// Result of a booking fetch.
class BookingResult {
  const BookingResult({
    required this.items,
    required this.fromCache,
    this.cachedAt,
  });

  final List<BookingDetails> items;
  final bool fromCache;
  final DateTime? cachedAt;
}

/// Repository for bookings + QR codes. Single concrete class.
///
/// Responsibilities:
/// - Stale-while-revalidate fetch of a user's bookings
/// - QR code fetching **with** automatic PNG blob caching for offline use
/// - Auto-sync on connectivity restoration (per-user tracking)
class BookingRepository {
  BookingRepository._({
    APIClient? api,
    CacheManager? cache,
    ConnectivityService? connectivity,
  })  : _api = api ?? APIClient(),
        _cache = cache ?? CacheManager(),
        _connectivity = connectivity ?? ConnectivityService();

  static BookingRepository? _instance;
  factory BookingRepository() =>
      _instance ??= BookingRepository._();

  final APIClient _api;
  final CacheManager _cache;
  final ConnectivityService _connectivity;

  final StreamController<void> _changes = StreamController<void>.broadcast();
  StreamSubscription? _connSub;

  /// Tracks user IDs that have been queried so auto-sync can re-fetch them
  /// on reconnect.
  final Set<String> _trackedUserIds = <String>{};

  /// Broadcasts a `null` event whenever the cache is written.
  Stream<void> get changes => _changes.stream;

  /// Fetches a user's bookings with stale-while-revalidate semantics.
  Future<BookingResult> getUserBookings(
    String userId, {
    String? status,
    bool forceRefresh = false,
  }) async {
    _trackedUserIds.add(userId);

    if (!forceRefresh && !_connectivity.isOnline) {
      final cached = await _cache.readBookings(status: status);
      return BookingResult(
        items: cached,
        fromCache: true,
        cachedAt: null,
      );
    }

    try {
      final bookings = await _api.getUserBookings(userId, status: status);
      await _cache.upsertBookings(bookings);
      if (!_changes.isClosed) _changes.add(null);
      return BookingResult(
        items: bookings,
        fromCache: false,
        cachedAt: DateTime.now(),
      );
    } on ApiNetworkException {
      final cached = await _cache.readBookings(status: status);
      return BookingResult(
        items: cached,
        fromCache: true,
        cachedAt: null,
      );
    }
  }

  /// Fetches a booking's details. Falls back to cache on network error.
  Future<BookingDetails?> getBookingDetails(String bookingId) async {
    try {
      final details = await _api.getBookingDetails(bookingId);
      await _cache.upsertBookings([details]);
      if (!_changes.isClosed) _changes.add(null);
      return details;
    } on ApiNetworkException {
      return _cache.readBooking(bookingId);
    }
  }

  /// Fetches the QR code ticket and **transparently caches** a rendered
  /// PNG image so it can be displayed offline later.
  ///
  /// Returns `null` on network error (caller should fall back to
  /// [getCachedQRCode] if it has a `bookingId` to look up).
  Future<BookingQr?> getBookingQr(String bookingId) async {
    try {
      final qr = await _api.getBookingQr(bookingId);
      Uint8List? bytes;
      if (qr.qrCodeUrl != null && qr.qrCodeUrl!.isNotEmpty) {
        try {
          final dio = Dio();
          final response = await dio.get<List<int>>(
            qr.qrCodeUrl!,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.statusCode == 200 && response.data != null) {
            bytes = Uint8List.fromList(response.data!);
          }
        } catch (e) {
          // fallback to local rendering if download fails
        }
      }
      if (bytes == null) {
        bytes = await _renderQrPng(qr.qrCode);
      }
      if (bytes != null) {
        await _cache.upsertQRCode(bookingId, bytes);
      }
      return qr;
    } on ApiNetworkException {
      return null;
    }
  }

  /// Returns the cached QR PNG bytes for [bookingId], or `null` if none.
  Future<Uint8List?> getCachedQRCode(String bookingId) {
    return _cache.readQRCode(bookingId);
  }

  /// Public sync entry point — fetches all tracked users' bookings.
  Future<bool> syncUserBookings(String userId) async {
    try {
      final bookings = await _api.getUserBookings(userId);
      await _cache.upsertBookings(bookings);
      if (!_changes.isClosed) _changes.add(null);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Renders [data] as a 512x512 PNG using `qr_flutter`'s QrPainter.
  /// Returns `null` if rendering fails (e.g., on headless test).
  Future<Uint8List?> _renderQrPng(String data) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF141822),
        emptyColor: const Color(0xFFFFFFFF),
      );
      final imageSize = 512.0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      painter.paint(canvas, Size(imageSize, imageSize));
      final picture = recorder.endRecording();
      final image = await picture.toImage(imageSize.toInt(), imageSize.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Subscribes to connectivity changes; re-syncs every tracked user on
  /// online transitions. Idempotent.
  void startAutoSync() {
    if (_connSub != null) return;
    _connSub = _connectivity.connectivityStream.listen((online) {
      if (!online) return;
      for (final userId in _trackedUserIds) {
        unawaited(syncUserBookings(userId));
      }
    });
  }

  Future<void> stopAutoSync() async {
    await _connSub?.cancel();
    _connSub = null;
  }

  Future<void> dispose() async {
    await stopAutoSync();
    await _changes.close();
  }
}
