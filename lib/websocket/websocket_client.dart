import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/backend_config.dart';
import 'seat_update.dart';

typedef ChannelFactory = WebSocketChannel Function(Uri uri);
typedef SeatStateSync = Future<void> Function(String showtimeId);

class WebSocketClient with WidgetsBindingObserver {
  WebSocketClient({
    String? baseUrl,
    ChannelFactory? channelFactory,
    SeatStateSync? onStateSync,
    Duration pingInterval = const Duration(seconds: 30),
    Duration pongTimeout = const Duration(seconds: 5),
  }) : _baseUrl = baseUrl ?? _defaultBaseUrl,
       _channelFactory = channelFactory ?? WebSocketChannel.connect,
       // ignore: prefer_initializing_formals
       _onStateSync = onStateSync,
       // ignore: prefer_initializing_formals
       _pingInterval = pingInterval,
       // ignore: prefer_initializing_formals
       _pongTimeout = pongTimeout;

  static String get _defaultBaseUrl => BackendConfig.wsShowtimesBaseUrl;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);

  final String _baseUrl;
  final ChannelFactory _channelFactory;
  final SeatStateSync? _onStateSync;
  final Duration _pingInterval;
  final Duration _pongTimeout;

  WebSocketChannel? _channel;
  ConnectionState _currentState = ConnectionState.disconnected;
  String? _showtimeId;
  String? _jwtToken;
  int _reconnectAttempts = 0;
  bool _shouldReconnect = false;
  bool _disposed = false;
  bool _wasConnected = false;
  bool _observingLifecycle = false;
  Timer? _pingTimer;
  Timer? _pongTimer;
  Timer? _reconnectTimer;
  StreamSubscription<dynamic>? _messageSubscription;

  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  final _seatUpdateController = StreamController<SeatUpdate>.broadcast();

  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<SeatUpdate> get seatUpdateStream => _seatUpdateController.stream;
  ConnectionState get currentState => _currentState;

  Future<void> connect(String showtimeId, String jwtToken) async {
    if (_disposed) return;
    if (_showtimeId != showtimeId && _channel != null) {
      await _closeConnection();
    }
    _showtimeId = showtimeId;
    _jwtToken = jwtToken;
    _shouldReconnect = true;
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
    if (_currentState != ConnectionState.connected &&
        _currentState != ConnectionState.connecting) {
      await _establishConnection();
    }
  }

  Future<void> _establishConnection() async {
    final showtimeId = _showtimeId;
    final jwtToken = _jwtToken;
    if (_disposed ||
        !_shouldReconnect ||
        showtimeId == null ||
        jwtToken == null) {
      return;
    }

    _reconnectTimer?.cancel();
    _updateConnectionState(ConnectionState.connecting);
    try {
      final url =
          '$_baseUrl/${Uri.encodeComponent(showtimeId)}/seats'
          '?token=${Uri.encodeQueryComponent(jwtToken)}';
      final channel = _channelFactory(Uri.parse(url));
      _channel = channel;
      await channel.ready;
      if (_channel != channel || !_shouldReconnect) {
        await channel.sink.close(status.goingAway);
        return;
      }
      _messageSubscription = channel.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );
      _updateConnectionState(ConnectionState.connected);
      _reconnectAttempts = 0;
      _startPingTimer();
      if (_wasConnected && _onStateSync != null) {
        await _onStateSync(showtimeId);
      }
      _wasConnected = true;
    } catch (_) {
      _updateConnectionState(ConnectionState.error);
      await _closeConnection();
      _scheduleReconnection();
    }
  }

  void _handleMessage(dynamic message) {
    if (message is! String) return;
    try {
      final payload = jsonDecode(message) as Map<String, dynamic>;
      final type = payload['type'] as String?;
      if (type == 'pong') {
        _pongTimer?.cancel();
      } else if (type == 'seat_update') {
        final data = payload['data'] as Map<String, dynamic>;
        _seatUpdateController.add(SeatUpdate.fromJson(data));
      } else if (type == 'seat_snapshot') {
        final data = payload['data'] as List<dynamic>? ?? const [];
        for (final item in data) {
          _seatUpdateController.add(
            SeatUpdate.fromJson(item as Map<String, dynamic>),
          );
        }
      }
    } on FormatException {
      // Ignore malformed server messages and keep the connection alive.
    } on TypeError {
      // Ignore messages that do not match the documented contract.
    }
  }

  void _handleError(Object _) {
    _updateConnectionState(ConnectionState.error);
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _closeConnection();
    if (_shouldReconnect && !_disposed) {
      _updateConnectionState(ConnectionState.disconnected);
      _scheduleReconnection();
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) => _sendPing());
  }

  void _sendPing() {
    if (_channel == null || _currentState != ConnectionState.connected) return;
    _channel!.sink.add(jsonEncode({'type': 'ping'}));
    _pongTimer?.cancel();
    _pongTimer = Timer(_pongTimeout, () async {
      _updateConnectionState(ConnectionState.error);
      await _closeConnection();
      _scheduleReconnection();
    });
  }

  void _scheduleReconnection() {
    if (!_shouldReconnect || _disposed || _reconnectTimer?.isActive == true) {
      return;
    }
    final multiplier = 1 << _reconnectAttempts.clamp(0, 5);
    final milliseconds = (_initialReconnectDelay.inMilliseconds * multiplier)
        .clamp(
          _initialReconnectDelay.inMilliseconds,
          _maxReconnectDelay.inMilliseconds,
        );
    _reconnectAttempts++;
    _reconnectTimer = Timer(
      Duration(milliseconds: milliseconds),
      _establishConnection,
    );
  }

  void _updateConnectionState(ConnectionState state) {
    if (_currentState == state || _disposed) return;
    _currentState = state;
    _connectionStateController.add(state);
  }

  Future<void> _closeConnection() async {
    _pingTimer?.cancel();
    _pongTimer?.cancel();
    final subscription = _messageSubscription;
    final channel = _channel;
    _messageSubscription = null;
    _channel = null;
    await subscription?.cancel();
    try {
      await channel?.sink.close(status.goingAway);
    } catch (_) {
      // Socket may already be closed.
    }
  }

  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    await _closeConnection();
    _updateConnectionState(ConnectionState.disconnected);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _closeConnection().then((_) {
        if (_shouldReconnect && !_disposed) {
          _updateConnectionState(ConnectionState.disconnected);
        }
      });
    } else if (state == AppLifecycleState.resumed &&
        _shouldReconnect &&
        _currentState != ConnectionState.connected) {
      _establishConnection();
    }
  }

  void dispose() {
    if (_disposed) return;
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _shouldReconnect = false;
    _disposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _pongTimer?.cancel();
    _messageSubscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _connectionStateController.close();
    _seatUpdateController.close();
  }
}

enum ConnectionState { disconnected, connecting, connected, error }
