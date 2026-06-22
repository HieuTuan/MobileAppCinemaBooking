import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import '../cache/cache_manager.dart';
import '../api/api_client.dart';

/// Service for caching and retrieving QR codes with offline support.
///
/// **Requirements Coverage:**
/// - Requirement 10.7: Enable offline QR code display by caching image locally
/// - Requirement 35.1: Store QR code PNG as blob in database
///
/// Provides seamless integration between API, QR code generation, and cache.
/// Automatically caches QR codes when fetched from API for offline access.
///
/// Usage:
/// ```dart
/// final service = QRCacheService();
///
/// // Get QR code (from cache or API)
/// final qrImage = await service.getQRCodeImage(bookingId);
///
/// // Preload and cache for offline use
/// await service.preloadQRCode(bookingId);
///
/// // Check if QR code is cached
/// final isCached = await service.isQRCodeCached(bookingId);
/// ```
class QRCacheService {
  final CacheManager _cacheManager;
  final APIClient _apiClient;

  QRCacheService({
    CacheManager? cacheManager,
    APIClient? apiClient,
  })  : _cacheManager = cacheManager ?? CacheManager(),
        _apiClient = apiClient ?? APIClient();

  /// Get QR code image bytes with offline fallback.
  ///
  /// **Requirements:**
  /// - 10.7: Try cache first for offline access
  /// - 10.7: Fall back to API if not cached
  /// - 35.1: Automatically cache when fetched from API
  ///
  /// Flow:
  /// 1. Check cache first (for offline support)
  /// 2. If not cached, fetch from API
  /// 3. Generate QR code image from data
  /// 4. Cache for future offline use
  ///
  /// Returns QR code image as PNG bytes.
  Future<Uint8List> getQRCodeImage(String bookingId) async {
    // Try to get from cache first (offline support)
    final cachedImage = await _cacheManager.getCachedQRCode(bookingId);
    if (cachedImage != null) {
      return Uint8List.fromList(cachedImage);
    }

    // Not in cache, fetch from API
    final qrData = await _apiClient.getBookingQr(bookingId);

    // Generate QR code image
    final qrImage = await _generateQRCodeImage(qrData.qrCode);

    // Cache for offline access
    await _cacheManager.cacheQRCode(bookingId, qrImage);

    return qrImage;
  }

  /// Generate QR code PNG image from string data.
  ///
  /// Converts QR code string into actual image bytes (PNG format)
  /// using the qr_flutter package.
  ///
  /// Size: 512x512 pixels for good quality scanning.
  Future<Uint8List> _generateQRCodeImage(String data) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );

    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCode = qrValidationResult.qrCode!;
      
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const ui.Color(0xFF000000),
        emptyColor: const ui.Color(0xFFFFFFFF),
        gapless: true,
      );

      // Generate image with 512x512 size
      final picData = await painter.toImageData(
        512.0,
        format: ui.ImageByteFormat.png,
      );

      return picData!.buffer.asUint8List();
    }

    throw Exception('Invalid QR code data');
  }

  /// Preload QR code into cache for offline use.
  ///
  /// **Requirement 10.7**: Proactively cache QR codes for upcoming bookings
  ///
  /// Useful for:
  /// - Caching QR codes immediately after booking payment
  /// - Bulk caching all user bookings for offline trip
  /// - Background refresh of cached QR codes
  ///
  /// Returns true if successfully cached, false if already cached.
  Future<bool> preloadQRCode(String bookingId) async {
    // Check if already cached
    if (await isQRCodeCached(bookingId)) {
      return false; // Already cached
    }

    // Fetch and cache
    await getQRCodeImage(bookingId);
    return true;
  }

  /// Check if QR code is available in cache.
  ///
  /// Useful for showing offline indicators in UI.
  Future<bool> isQRCodeCached(String bookingId) async {
    final cachedImage = await _cacheManager.getCachedQRCode(bookingId);
    return cachedImage != null;
  }

  /// Get the age of cached QR code.
  ///
  /// Returns null if not cached.
  /// Useful for determining if cache should be refreshed.
  Future<Duration?> getCachedQRCodeAge(String bookingId) async {
    final cacheTime = await _cacheManager.getQRCodeCacheTime(bookingId);
    if (cacheTime == null) return null;

    return DateTime.now().difference(cacheTime);
  }

  /// Refresh cached QR code from API.
  ///
  /// Forces re-fetch from API and updates cache.
  /// Useful when QR code data might have changed.
  Future<Uint8List> refreshQRCode(String bookingId) async {
    // Delete old cache
    await _cacheManager.deleteCachedQRCode(bookingId);

    // Fetch fresh from API and cache
    return await getQRCodeImage(bookingId);
  }

  /// Preload QR codes for multiple bookings.
  ///
  /// Bulk operation to cache QR codes for offline access.
  /// Useful before going offline (e.g., before a trip to cinema).
  ///
  /// Returns map of bookingId -> success status.
  Future<Map<String, bool>> preloadMultipleQRCodes(
    List<String> bookingIds,
  ) async {
    final results = <String, bool>{};

    for (final bookingId in bookingIds) {
      try {
        final success = await preloadQRCode(bookingId);
        results[bookingId] = success;
      } catch (e) {
        results[bookingId] = false;
      }
    }

    return results;
  }

  /// Clear cached QR code for a specific booking.
  ///
  /// Useful when booking is cancelled or refunded.
  Future<void> clearQRCode(String bookingId) async {
    await _cacheManager.deleteCachedQRCode(bookingId);
  }
}
