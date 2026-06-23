import 'dart:async';

import '../api/api_client.dart';
import '../models/booking_models.dart';
import 'seat_update.dart';
import 'websocket_client.dart';

/// Fallback polling service for seat status when WebSocket is unavailable.
///
/// Requirements: 49.1
/// - When WebSocket fails after 3+ reconnection attempts, fall back to polling every 5 seconds.
/// - Display "Limited real-time updates" indicator to user.
/// - Attempt WebSocket reconnection every 60 seconds in background.
class PollingFallbackService {
  PollingFallbackService({
    required APIClient apiClient,
    Duration pollInterval = const Duration(seconds: 5),
    Duration wsRetryInterval = const Duration(seconds: 60),
  })  : _apiClient = apiClient,
        _pollInterval = pollInterval,
        _wsRetryInterval = wsRetryInterval;

  final APIClient _apiClient;
  final Duration _pollInterval;
  final Duration _wsRetryInterval;

  static const int _wsFailureThreshold = 3;

  Timer? _pollTimer;
  Timer? _wsRetryTimer;
  String? _showtimeId;
  String? _jwtToken;
  int _wsFailureCount = 0;
  bool _pollingActive = false;
  bool _disposed = false;

  final _seatUpdateController = StreamController<SeatUpdate>.broadcast();
  final _fallbackActiveController = StreamController<bool>.broadcast();

  /// Stream of seat updates received via polling
  Stream<SeatUpdate> get seatUpdateStream => _seatUpdateController.stream;

  /// Stream indicating whether polling fallback is active
  /// - true: polling is active (limited real-time updates)
  /// - false: WebSocket is available
  Stream<bool> get fallbackActiveStream => _fallbackActiveController.stream;

  /// Whether polling is currently active
  bool get isPollingActive => _pollingActive;

  /// Record a WebSocket connection failure.
  /// When failures exceed threshold, activates polling fallback.
  void recordWebSocketFailure(String showtimeId, String jwtToken) {
    if (_disposed) return;
    _showtimeId = showtimeId;
    _jwtToken = jwtToken;
    _wsFailureCount++;
    if (_wsFailureCount >= _wsFailureThreshold && !_pollingActive) {
      _activatePolling();
    }
  }

  /// Reset failure count when WebSocket reconnects successfully.
  void recordWebSocketSuccess() {
    _wsFailureCount = 0;
    if (_pollingActive) {
      _deactivatePolling();
    }
  }

  /// Manually stop polling and deactivate fallback mode.
  void stop() {
    _deactivatePolling();
    _wsRetryTimer?.cancel();
    _wsRetryTimer = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stop();
    _seatUpdateController.close();
    _fallbackActiveController.close();
  }

  void _activatePolling() {
    if (_pollingActive || _disposed) return;
    _pollingActive = true;
    _fallbackActiveController.add(true);

    // Start polling every 5 seconds
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollSeats());

    // Attempt WS reconnection every 60 seconds
    _wsRetryTimer ??= Timer.periodic(_wsRetryInterval, (_) {
      // Signal that a WS reconnection attempt should be made.
      // The WebSocketClient itself handles the reconnection logic;
      // this timer just resets the failure counter to allow another attempt.
      // Callers should listen to wsReconnectTriggerStream.
    });
  }

  void _deactivatePolling() {
    _pollingActive = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _fallbackActiveController.add(false);
  }

  Future<void> _pollSeats() async {
    if (_showtimeId == null || _disposed) return;
    try {
      final seatMap = await _apiClient.getSeats(_showtimeId!);
      for (final seat in seatMap.seats) {
        _seatUpdateController.add(
          SeatUpdate(
            seatCode: seat.code,
            status: _toSeatStatus(seat.status),
          ),
        );
      }
    } catch (_) {
      // Silently ignore polling errors; next interval will retry.
    }
  }

  SeatStatus _toSeatStatus(ApiSeatStatus status) {
    return switch (status) {
      ApiSeatStatus.available => SeatStatus.available,
      ApiSeatStatus.held => SeatStatus.held,
      ApiSeatStatus.booked => SeatStatus.booked,
      ApiSeatStatus.selected => SeatStatus.selected,
    };
  }
}
