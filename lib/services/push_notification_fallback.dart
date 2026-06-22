import 'dart:async';

/// Push notification fallback service.
///
/// Requirements: 49.4
/// When FCM/APNs registration fails:
/// - Log the failure and continue booking flow without blocking.
/// - Fall back to in-app polling for notifications every 5 minutes.
class PushNotificationFallback {
  PushNotificationFallback({
    Duration pollInterval = const Duration(minutes: 5),
  }) : _pollInterval = pollInterval;

  final Duration _pollInterval;

  Timer? _pollingTimer;
  bool _isPollingActive = false;
  bool _disposed = false;

  final _notificationController =
      StreamController<InAppNotification>.broadcast();

  /// Stream of in-app notifications delivered via polling.
  Stream<InAppNotification> get notificationStream =>
      _notificationController.stream;

  bool get isPollingActive => _isPollingActive;

  /// Called when FCM/APNs registration fails.
  ///
  /// Logs the failure and activates polling fallback.
  /// Does NOT throw - caller should continue the booking flow.
  void onRegistrationFailure(Object error) {
    // Log failure (non-blocking)
    // ignore: avoid_print
    print('[PushNotificationFallback] FCM/APNs registration failed: $error');
    // Activate polling fallback
    _startPolling();
  }

  /// Start in-app notification polling every [_pollInterval].
  void _startPolling() {
    if (_isPollingActive || _disposed) return;
    _isPollingActive = true;
    _pollingTimer = Timer.periodic(_pollInterval, (_) => _pollNotifications());
  }

  /// Stop polling.
  void stopPolling() {
    _isPollingActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollNotifications() async {
    if (_disposed) return;
    // In a real implementation, call GET /api/users/{userId}/notifications
    // and emit any unread notifications. This is a stub that can be wired up
    // to the API client by the consuming widget.
    // The actual polling logic will depend on user authentication state.
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopPolling();
    _notificationController.close();
  }
}

/// A lightweight in-app notification model for fallback polling.
class InAppNotification {
  const InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.deeplink,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String? deeplink;
  final DateTime createdAt;
}
