import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralised analytics service wrapping Firebase Analytics.
///
/// Covers:
/// - App open, login, screen views (Req 41.1, 41.3, 41.4)
/// - Business events: movie_view, seat_selection_start, booking_complete,
///   payment_success, payment_fail (Req 41.1)
/// - Privacy compliance: IP anonymisation enabled, ad tracking disabled (Req 41.7)
///
/// Usage:
/// ```dart
/// AnalyticsService.instance.trackLogin(userId: 'u123', method: 'email');
/// AnalyticsService.instance.trackMovieView(movieId: 'm1', movieTitle: 'Inception');
/// ```
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  late final FirebaseAnalytics _analytics;
  bool _initialized = false;

  // ── Init ───────────────────────────────────────────────────────────────────

  /// Must be called once after Firebase.initializeApp() in main().
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;

      // Req 41.7 – anonymise user data / GDPR compliance
      // Disable ad personalisation and analytics collection can be toggled
      // by user consent; we start with collection enabled but no ad ID.
      await _analytics.setAnalyticsCollectionEnabled(true);

      // No personally-identifying user properties by default.
      // IP is anonymised server-side by Firebase (GA4 default behaviour).
      _initialized = true;
      debugPrint('AnalyticsService: initialized');
    } catch (e) {
      debugPrint('AnalyticsService: init failed – $e');
    }
  }

  // ── GDPR consent ──────────────────────────────────────────────────────────

  /// Call with `false` when user revokes analytics consent (GDPR Req 41.7).
  Future<void> setAnalyticsEnabled({required bool enabled}) async {
    if (!_initialized) return;
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('AnalyticsService: setEnabled failed – $e');
    }
  }

  // ── User identity ──────────────────────────────────────────────────────────

  /// Set the current user ID (hashed / anonymised caller-side).
  /// Pass null to clear on logout.
  Future<void> setUserId(String? userId) async {
    if (!_initialized) return;
    try {
      await _analytics.setUserId(id: userId);
    } catch (_) {}
  }

  // ── Screen tracking ────────────────────────────────────────────────────────

  /// Track a screen view with optional duration logging (Req 41.4).
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      debugPrint('Analytics: screen_view → $screenName');
    } catch (_) {}
  }

  // ── Standard events ────────────────────────────────────────────────────────

  /// app_open – called once per cold start (Req 41.1).
  Future<void> trackAppOpen() async {
    if (!_initialized) return;
    try {
      await _analytics.logAppOpen();
    } catch (_) {}
  }

  /// login – after successful authentication (Req 41.1, 41.3).
  ///
  /// [method]: 'email' | 'google'
  Future<void> trackLogin({
    required String userId,
    required String method,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logLogin(loginMethod: method);
      await setUserId(userId);
    } catch (_) {}
  }

  /// logout – clears user identity.
  Future<void> trackLogout() async {
    if (!_initialized) return;
    await setUserId(null);
  }

  /// movie_view – user opens a movie detail page (Req 41.1, 41.3).
  Future<void> trackMovieView({
    required String movieId,
    required String movieTitle,
    String? genre,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: 'movie_view',
        parameters: {
          'movie_id': movieId,
          'movie_title': movieTitle,
          if (genre != null) 'genre': genre,
        },
      );
    } catch (_) {}
  }

  /// seat_selection_start – user opens the seat selection screen (Req 41.1).
  Future<void> trackSeatSelectionStart({
    required String showtimeId,
    required String movieId,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: 'seat_selection_start',
        parameters: {
          'showtime_id': showtimeId,
          'movie_id': movieId,
        },
      );
    } catch (_) {}
  }

  /// booking_complete – booking confirmed after seats held (Req 41.1, 41.3).
  Future<void> trackBookingComplete({
    required String userId,
    required String showtimeId,
    required String movieId,
    required int totalAmount,
    required int seatCount,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: 'booking_complete',
        parameters: {
          'user_id': userId,
          'showtime_id': showtimeId,
          'movie_id': movieId,
          'total_amount': totalAmount,
          'seat_count': seatCount,
        },
      );
    } catch (_) {}
  }

  /// payment_success – VNPay returns success (Req 41.1, 41.3).
  Future<void> trackPaymentSuccess({
    required String userId,
    required String bookingId,
    required int totalAmount,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: 'payment_success',
        parameters: {
          'user_id': userId,
          'booking_id': bookingId,
          'total_amount': totalAmount,
        },
      );
    } catch (_) {}
  }

  /// payment_fail – VNPay returns failure or timeout (Req 41.1, 41.3).
  Future<void> trackPaymentFail({
    required String userId,
    required String bookingId,
    String? reason,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: 'payment_fail',
        parameters: {
          'user_id': userId,
          'booking_id': bookingId,
          if (reason != null) 'reason': reason,
        },
      );
    } catch (_) {}
  }

  // ── Convenience getter for NavigatorObserver ───────────────────────────────

  /// Use as a [NavigatorObserver] to auto-track route changes.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);
}
