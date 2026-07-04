import 'package:flutter/foundation.dart';

class BackendConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _wsBaseUrl = String.fromEnvironment('WS_BASE_URL');
  static const String _devServerHost = String.fromEnvironment(
    'DEV_SERVER_HOST',
  );
  static const String _devServerPort = String.fromEnvironment(
    'DEV_SERVER_PORT',
    defaultValue: '8080',
  );

  static String get restBaseUrl {
    // 1️⃣ Production / Staging: set via --dart-define=API_BASE_URL=https://...
    if (_apiBaseUrl.trim().isNotEmpty) {
      return _stripTrailingSlash(_apiBaseUrl);
    }

    // 2️⃣ Physical device: set via --dart-define=DEV_SERVER_HOST=<PC_LAN_IP>
    //    e.g.  flutter run --dart-define=DEV_SERVER_HOST=10.11.64.190
    //    Or use the "📱 Physical Device" VS Code launch config.
    if (_devServerHost.trim().isNotEmpty) {
      return _httpUrlForHost(_devServerHost);
    }

    // 3️⃣ Web dev server
    if (kIsWeb) return 'http://localhost:8080';

    // 4️⃣ Android Emulator & Physical Devices / iOS Simulator & Physical Devices
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://192.168.1.18:8080';
    }

    // 5️⃣ Web / desktop localhost
    return 'http://localhost:8080';
  }

  static String get wsShowtimesBaseUrl {
    if (_wsBaseUrl.trim().isNotEmpty) {
      return _stripTrailingSlash(_wsBaseUrl);
    }
    return _webSocketUrlFromRest(restBaseUrl);
  }

  static String _httpUrlForHost(String host) {
    final normalizedHost = _stripTrailingSlash(host.trim());
    if (normalizedHost.startsWith('http://') ||
        normalizedHost.startsWith('https://')) {
      return normalizedHost;
    }
    if (normalizedHost.contains(':')) {
      return 'http://$normalizedHost';
    }
    return 'http://$normalizedHost:$_devServerPort';
  }

  static String _webSocketUrlFromRest(String restUrl) {
    final uri = Uri.parse(restUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri
        .replace(
          scheme: scheme,
          path: '${_stripTrailingSlash(uri.path)}/ws/showtimes',
          query: null,
          fragment: null,
        )
        .toString();
  }

  static String _stripTrailingSlash(String value) {
    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}
