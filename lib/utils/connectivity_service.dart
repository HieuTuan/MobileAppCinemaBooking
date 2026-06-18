import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Singleton wrapper around `connectivity_plus` that exposes a simple
/// online/offline boolean stream.
///
/// Defaults to **online** until the first connectivity event is received,
/// matching the optimistic assumption used by the rest of the app.
class ConnectivityService {
  ConnectivityService._() {
    _bootstrap();
  }

  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Current connectivity state. `true` = online.
  bool get isOnline => _isOnline;

  /// Broadcasts `true` (online) or `false` (offline) on every transition.
  Stream<bool> get connectivityStream => _controller.stream;

  Future<void> _bootstrap() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      _emit(_toBool(initial));
    } catch (_) {
      // Keep optimistic default on failure.
    }
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _emit(_toBool(results));
    });
  }

  void _emit(bool online) {
    if (online == _isOnline) return;
    _isOnline = online;
    if (!_controller.isClosed) {
      _controller.add(online);
    }
  }

  bool _toBool(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Releases the internal subscription and closes the broadcast stream.
  /// Called on app shutdown by the owner of the singleton.
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
