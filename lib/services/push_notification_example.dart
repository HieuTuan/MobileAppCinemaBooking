/// Example usage of PushNotificationHandler
/// 
/// This file demonstrates how to integrate the PushNotificationHandler
/// into your Flutter application.
///
/// For full documentation, see PUSH_NOTIFICATION_HANDLER_USAGE.md

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'push_notification_handler.dart';

/// Example: Initialize push notifications in main.dart
Future<void> initializePushNotifications() async {
  final pushHandler = PushNotificationHandler();
  
  try {
    // 1. Initialize Firebase messaging
    await pushHandler.initialize();
    print('✓ Push notifications initialized');
    
    // 2. Request permission
    final status = await pushHandler.requestPermission();
    print('Permission status: $status');
    
    if (status == AuthorizationStatus.authorized) {
      // 3. Get device token
      final token = await pushHandler.getDeviceToken();
      print('Device token: ${token?.substring(0, 20)}...');
      
      // 4. Register token with backend
      // await apiClient.registerDevice(token, pushHandler.getPlatform());
    }
  } catch (e) {
    print('Push notification setup failed: $e');
  }
}

/// Example: Listen to foreground notifications
void setupForegroundNotificationListener(BuildContext context) {
  final pushHandler = PushNotificationHandler();
  
  pushHandler.notificationStream.listen((RemoteMessage message) {
    // Display in-app notification banner
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.notification?.body ?? 'New notification'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            pushHandler.handleNotificationTap(message);
          },
        ),
      ),
    );
  });
}

/// Example: Test deeplink parsing
void testDeeplinkParsing() {
  final pushHandler = PushNotificationHandler();
  
  // Test booking deeplink
  final bookingMessage = RemoteMessage(
    data: {'deeplink': 'cinema://booking/BK123456'},
  );
  pushHandler.handleNotificationTap(bookingMessage);
  
  // Test movie deeplink
  final movieMessage = RemoteMessage(
    data: {'deeplink': 'cinema://movie/MV789'},
  );
  pushHandler.handleNotificationTap(movieMessage);
  
  // Test promotions deeplink
  final promoMessage = RemoteMessage(
    data: {'deeplink': 'cinema://promotions'},
  );
  pushHandler.handleNotificationTap(promoMessage);
}

/// Example notification payload structure
const exampleBookingNotification = {
  'notification': {
    'title': 'Showtime Reminder',
    'body': 'Your movie "Avengers" starts in 2 hours',
  },
  'data': {
    'deeplink': 'cinema://booking/BK123456',
    'type': 'showtime_reminder',
    'bookingId': 'BK123456',
  },
};

const examplePromotionNotification = {
  'notification': {
    'title': 'Special Offer',
    'body': '50% off all tickets this weekend!',
  },
  'data': {
    'deeplink': 'cinema://promotions',
    'type': 'promotion',
  },
};
