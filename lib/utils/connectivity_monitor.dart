import 'dart:io';

/// Simple connectivity monitor to detect online/offline state.
///
/// **Requirements Coverage:**
/// - Requirement 35.3: Detect network connectivity for offline mode
/// - Requirement 35.4: Display offline indicators
///
/// Usage:
/// ```dart
/// final isOnline = await ConnectivityMonitor.checkConnectivity();
/// if (!isOnline) {
///   // Show offline UI
/// }
/// ```
class ConnectivityMonitor {
  /// Check if device has internet connectivity.
  ///
  /// Performs a simple DNS lookup to verify actual internet access
  /// (not just WiFi/cellular connection).
  ///
  /// Returns true if online, false if offline.
  static Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Check connectivity with custom host.
  ///
  /// Useful for checking connectivity to specific servers.
  static Future<bool> checkConnectivityTo(String host) async {
    try {
      final result = await InternetAddress.lookup(host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
