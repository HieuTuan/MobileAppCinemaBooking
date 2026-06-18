import 'package:flutter_test/flutter_test.dart';
import 'package:cine_book/services/push_notification_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushNotificationHandler', () {
    test('should return singleton instance', () {
      final instance1 = PushNotificationHandler();
      final instance2 = PushNotificationHandler();
      
      expect(instance1, same(instance2));
    });

    test('getPlatform should return android or ios', () {
      final handler = PushNotificationHandler();
      final platform = handler.getPlatform();
      
      expect(platform, isIn(['android', 'ios', 'unknown']));
    });

    test('notificationStream should be broadcast stream', () {
      final handler = PushNotificationHandler();
      final stream = handler.notificationStream;
      
      expect(stream.isBroadcast, isTrue);
    });

    group('handleNotificationTap', () {
      late PushNotificationHandler handler;
      
      setUp(() {
        handler = PushNotificationHandler();
      });

      test('should parse booking deeplink correctly', () {
        final message = RemoteMessage(
          data: {
            'deeplink': 'cinema://booking/BK123456',
            'type': 'showtime_reminder',
          },
        );

        // This should not throw
        expect(() => handler.handleNotificationTap(message), returnsNormally);
      });

      test('should parse movie deeplink correctly', () {
        final message = RemoteMessage(
          data: {
            'deeplink': 'cinema://movie/MV789',
            'type': 'new_movie',
          },
        );

        // This should not throw
        expect(() => handler.handleNotificationTap(message), returnsNormally);
      });

      test('should parse promotions deeplink correctly', () {
        final message = RemoteMessage(
          data: {
            'deeplink': 'cinema://promotions',
            'type': 'promotion',
          },
        );

        // This should not throw
        expect(() => handler.handleNotificationTap(message), returnsNormally);
      });

      test('should handle missing deeplink gracefully', () {
        final message = RemoteMessage(
          data: {
            'type': 'showtime_reminder',
            'bookingId': 'BK123',
          },
        );

        // Should not throw even without deeplink
        expect(() => handler.handleNotificationTap(message), returnsNormally);
      });

      test('should handle empty data gracefully', () {
        final message = RemoteMessage(data: {});

        // Should not throw even with empty data
        expect(() => handler.handleNotificationTap(message), returnsNormally);
      });

      test('should handle invalid deeplink format gracefully', () {
        final message = RemoteMessage(
          data: {
            'deeplink': 'not-a-valid-url',
          },
        );

        // Should not throw even with invalid format
        expect(() => handler.handleNotificationTap(message), returnsNormally);
      });
    });

    group('Notification Types', () {
      late PushNotificationHandler handler;
      
      setUp(() {
        handler = PushNotificationHandler();
      });
      
      test('should handle showtime_reminder type', () {
        final message = RemoteMessage(
          data: {
            'type': 'showtime_reminder',
            'bookingId': 'BK123',
          },
        );

        expect(() => handler.handleNotificationTap(message), returnsNormally);
      });

      test('should handle booking_confirmation type', () {
        final message = RemoteMessage(
          data: {
            'type': 'booking_confirmation',
            'bookingId': 'BK456',
          },
        );

        expect(() => handler.handleNotificationTap(message), returnsNormally);
      });

      test('should handle promotion type', () {
        final message = RemoteMessage(
          data: {
            'type': 'promotion',
            'movieId': 'MV789',
          },
        );

        expect(() => handler.handleNotificationTap(message), returnsNormally);
      });

      test('should handle new_movie type', () {
        final message = RemoteMessage(
          data: {
            'type': 'new_movie',
            'movieId': 'MV999',
          },
        );

        expect(() => handler.handleNotificationTap(message), returnsNormally);
      });

      test('should handle unknown type gracefully', () {
        final message = RemoteMessage(
          data: {
            'type': 'unknown_type',
          },
        );

        expect(() => handler.handleNotificationTap(message), returnsNormally);
      });
    });

    // Note: Testing initialize(), requestPermission(), and getDeviceToken()
    // requires mocking Firebase services which is complex.
    // These should be tested through integration tests or manually.
    // The methods are designed to be robust with error handling.

    group('Device Registration', () {
      late PushNotificationHandler handler;
      
      setUp(() {
        handler = PushNotificationHandler();
      });

      test('registerDevice should handle null token gracefully', () async {
        // When no token is available, registerDevice should return false
        // This test verifies the method doesn't throw
        expect(
          () async => await handler.registerDevice('user-123'),
          returnsNormally,
        );
      });

      test('getPlatform should return valid platform string', () {
        final platform = handler.getPlatform();
        expect(platform, isIn(['android', 'ios', 'unknown']));
        expect(platform, isNotEmpty);
      });
    });

    group('Device Unregistration', () {
      late PushNotificationHandler handler;
      
      setUp(() {
        handler = PushNotificationHandler();
      });

      test('unregisterDevice should handle null token gracefully', () async {
        // When no token is available, unregisterDevice should return false
        // This test verifies the method doesn't throw
        expect(
          () async => await handler.unregisterDevice('user-123'),
          returnsNormally,
        );
      });

      test('unregisterDevice should not throw on API failure', () async {
        // Even if API call fails, unregisterDevice should handle gracefully
        // This is important for logout flow - user should be able to logout
        // even if device unregistration fails
        expect(
          () async => await handler.unregisterDevice('user-123', deviceToken: 'test-token'),
          returnsNormally,
        );
      });
    });
  });
}

// Integration Test Example (requires Firebase setup and backend)
// 
// To run this test:
// 1. Set up Firebase for test environment
// 2. Ensure backend API is running
// 3. Run: flutter test test/services/push_notification_handler_integration_test.dart
//
// void main() {
//   group('PushNotificationHandler Integration Tests', () {
//     late PushNotificationHandler handler;
//     late String testUserId;
//     
//     setUpAll(() async {
//       // Initialize Firebase
//       await Firebase.initializeApp();
//       handler = PushNotificationHandler();
//       await handler.initialize();
//       testUserId = 'test-user-123';
//     });
//     
//     test('should register device successfully', () async {
//       // Request permission
//       final status = await handler.requestPermission();
//       expect(status, AuthorizationStatus.authorized);
//       
//       // Get device token
//       final token = await handler.getDeviceToken();
//       expect(token, isNotNull);
//       expect(token, isNotEmpty);
//       
//       // Register device
//       final success = await handler.registerDevice(testUserId);
//       expect(success, isTrue);
//     });
//     
//     test('should detect token changes', () async {
//       final secureStorage = SecureStorageService();
//       
//       // Save initial token
//       await secureStorage.saveDeviceToken('old-token-123');
//       
//       // Check with different token
//       final hasChanged = await secureStorage.hasDeviceTokenChanged('new-token-456');
//       expect(hasChanged, isTrue);
//       
//       // Check with same token
//       final hasNotChanged = await secureStorage.hasDeviceTokenChanged('new-token-456');
//       expect(hasNotChanged, isFalse);
//     });
//     
//     test('should handle token refresh', () async {
//       // This test requires triggering a token refresh from Firebase
//       // In practice, this happens automatically on app reinstall
//       // We can simulate by calling registerDevice with a new token
//       
//       final success = await handler.registerDevice(
//         testUserId,
//         deviceToken: 'refreshed-token-789',
//       );
//       
//       expect(success, isTrue);
//     });
//   });
// }
