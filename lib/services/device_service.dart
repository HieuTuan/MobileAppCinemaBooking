import 'package:cine_book/api/api_client.dart';
import 'package:cine_book/services/push_notification_handler.dart';

class DeviceService {
  final APIClient _apiClient;

  DeviceService({APIClient? apiClient}) : _apiClient = apiClient ?? APIClient();

  Future<void> registerDevice({
    required String deviceToken,
    required NotificationPlatform platform,
  }) async {
    final platformString = switch (platform) {
      NotificationPlatform.android => 'android',
      NotificationPlatform.ios => 'ios',
      NotificationPlatform.web => 'web',
    };

    await _apiClient.post<Map<String, dynamic>>(
      '/api/devices/register',
      data: {
        'deviceToken': deviceToken,
        'platform': platformString,
      },
    );
  }

  Future<void> unregisterDevice() async {
    await _apiClient.post<void>(
      '/api/devices/unregister',
    );
  }

  Future<void> refreshToken({
    required String newDeviceToken,
    required NotificationPlatform platform,
  }) async {
    final platformString = switch (platform) {
      NotificationPlatform.android => 'android',
      NotificationPlatform.ios => 'ios',
      NotificationPlatform.web => 'web',
    };

    await _apiClient.post<Map<String, dynamic>>(
      '/api/devices/refresh',
      data: {
        'deviceToken': newDeviceToken,
        'platform': platformString,
      },
    );
  }
}
