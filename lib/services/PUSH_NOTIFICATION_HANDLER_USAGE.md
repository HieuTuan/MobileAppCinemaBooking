# PushNotificationHandler Usage Guide

## Overview

The `PushNotificationHandler` manages push notification registration, reception, and routing for the Cinema Booking application. It provides a unified interface for handling Firebase Cloud Messaging (FCM) on Android and Apple Push Notification Service (APNs) on iOS.

## Features

- **Platform Detection**: Automatically uses FCM for Android and APNs for iOS via firebase_messaging
- **Permission Management**: Requests OS notification permissions with proper platform handling
- **Token Management**: Obtains and monitors device tokens for push targeting
- **Foreground Notifications**: Streams notifications for in-app banner display when app is active
- **Background Handling**: Routes notification taps to appropriate screens via deeplinks
- **Token Refresh**: Automatically detects and reports token changes

## Requirements Fulfilled

- **Requirement 15.4**: Push notification delivery respects user preferences
- **Requirement 37.1**: Request notification permission on app launch for authenticated users
- **Requirement 37.2**: Obtain FCM token (Android) or APNs token (iOS)

## Basic Usage

### 1. Initialize the Handler

Call `initialize()` once during app startup, ideally in your `main.dart`:

```dart
import 'package:cine_book/services/push_notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize push notifications
  final pushHandler = PushNotificationHandler();
  await pushHandler.initialize();
  
  runApp(MyApp());
}
```

### 2. Request Permission

Request notification permission after user authentication:

```dart
final pushHandler = PushNotificationHandler();

// Request permission
final status = await pushHandler.requestPermission();

if (status == AuthorizationStatus.authorized) {
  print('Notification permission granted');
  
  // Get device token for backend registration
  final token = await pushHandler.getDeviceToken();
  if (token != null) {
    // TODO: Send token to backend API
    // await apiClient.registerDevice(token, pushHandler.getPlatform());
  }
} else {
  print('Notification permission denied: $status');
}
```

### 3. Listen to Foreground Notifications

Subscribe to notification stream to display in-app banners:

```dart
final pushHandler = PushNotificationHandler();

pushHandler.notificationStream.listen((RemoteMessage message) {
  // Display in-app notification banner
  showNotificationBanner(
    title: message.notification?.title ?? 'Notification',
    body: message.notification?.body ?? '',
    onTap: () => pushHandler.handleNotificationTap(message),
  );
});
```

### 4. Handle Background Notification Taps

Background notification taps are handled automatically. The handler parses deeplinks and routes accordingly:

```dart
// This is handled internally by the PushNotificationHandler
// No additional code needed - just ensure initialize() was called
```

## Deeplink Format

The handler supports the following deeplink formats:

### Booking Details
```
cinema://booking/{bookingId}
```
Example: `cinema://booking/BK123456`

### Movie Details
```
cinema://movie/{movieId}
```
Example: `cinema://movie/MV789`

### Promotions
```
cinema://promotions
```

## Notification Payload Structure

### Expected Data Format

```json
{
  "notification": {
    "title": "Showtime Reminder",
    "body": "Your movie 'Avengers' starts in 2 hours"
  },
  "data": {
    "deeplink": "cinema://booking/BK123456",
    "type": "showtime_reminder",
    "bookingId": "BK123456"
  }
}
```

### Notification Types

- `showtime_reminder`: 2-hour reminder before showtime
- `booking_confirmation`: Payment successful
- `booking_cancellation`: Booking cancelled or refunded
- `promotion`: Special offers and promotions
- `new_movie`: New movie announcements

## Platform-Specific Behavior

### Android
- Uses Firebase Cloud Messaging (FCM)
- Permission automatically granted for Android <13
- Shows system permission dialog for Android 13+
- Supports notification channels for categorization

### iOS
- Uses Apple Push Notification Service (APNs) via FCM
- Requires user permission via system dialog
- Supports provisional authorization
- Configures badge, sound, and alert options

## Backend Integration

### Register Device

After obtaining the device token, register it with the backend:

```dart
final pushHandler = PushNotificationHandler();

// Get token
final token = await pushHandler.getDeviceToken();
final platform = pushHandler.getPlatform(); // 'android' or 'ios'

if (token != null) {
  // Call backend API
  await apiClient.registerDevice(token, platform);
}
```

Expected API endpoint: `POST /api/users/{userId}/devices`

Request body:
```json
{
  "deviceToken": "fcm_token_here",
  "platform": "android",
  "deviceModel": "Pixel 6"
}
```

### Unregister Device

When user logs out:

```dart
final token = await pushHandler.getDeviceToken();

if (token != null) {
  // Call backend API to remove device
  await apiClient.unregisterDevice(token);
}
```

Expected API endpoint: `DELETE /api/users/{userId}/devices/{deviceToken}`

## Advanced Usage

### Complete Integration Example

```dart
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cine_book/services/push_notification_handler.dart';
import 'package:cine_book/api/api_client.dart';

class NotificationManager {
  final PushNotificationHandler _pushHandler = PushNotificationHandler();
  final APIClient _apiClient = APIClient();
  
  Future<void> setup() async {
    // 1. Initialize
    await _pushHandler.initialize();
    
    // 2. Request permission
    final status = await _pushHandler.requestPermission();
    
    if (status == AuthorizationStatus.authorized) {
      // 3. Get token and register
      final token = await _pushHandler.getDeviceToken();
      if (token != null) {
        await _apiClient.registerDevice(
          token, 
          _pushHandler.getPlatform()
        );
      }
      
      // 4. Listen to foreground notifications
      _pushHandler.notificationStream.listen(_handleForegroundNotification);
    }
  }
  
  void _handleForegroundNotification(RemoteMessage message) {
    // Display in-app banner or dialog
    print('Foreground notification: ${message.notification?.title}');
    
    // Optionally show UI
    // showDialog or showSnackBar
  }
  
  Future<void> cleanup() async {
    final token = await _pushHandler.getDeviceToken();
    if (token != null) {
      await _apiClient.unregisterDevice(token);
    }
    _pushHandler.dispose();
  }
}
```

### Handling Token Refresh

Monitor token changes (e.g., after app reinstall):

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) async {
  print('Token refreshed: $newToken');
  
  // Update backend with new token
  await apiClient.registerDevice(
    newToken,
    pushHandler.getPlatform()
  );
});
```

## Troubleshooting

### No Token Received

1. Check Firebase configuration files are present:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

2. Verify Firebase project has FCM enabled

3. Check network connectivity

### Permission Denied

- User explicitly denied permission in system settings
- App must guide user to system settings to enable
- Cannot programmatically enable after denial

### Notifications Not Received

1. Verify device token is registered with backend
2. Check notification preferences in app settings
3. Ensure device is connected to internet
4. Verify Firebase project configuration

### iOS Specific Issues

1. Ensure APNs certificate is configured in Firebase Console
2. Check that push notifications capability is enabled in Xcode
3. Verify provisioning profile includes push notifications

## Testing

### Test Notification from Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Enter your device FCM token
4. Send notification and verify receipt

### Test Deeplink Navigation

Send a test notification with deeplink data:

```json
{
  "notification": {
    "title": "Test",
    "body": "Test notification"
  },
  "data": {
    "deeplink": "cinema://booking/TEST123"
  }
}
```

Tap the notification and verify navigation occurs.

## Next Steps

After implementing `PushNotificationHandler`, you'll need to:

1. **Task 19.3**: Implement device registration endpoint in backend
2. **Task 19.4**: Implement notification handling UI (in-app banners)
3. **Task 19.5**: Implement device unregistration on logout
4. **Integrate with AuthService**: Call permission request after login
5. **Implement Navigation**: Connect deeplink routing to actual screen navigation

## References

- [Firebase Messaging Documentation](https://firebase.flutter.dev/docs/messaging/overview/)
- [FCM Best Practices](https://firebase.google.com/docs/cloud-messaging/concept-options)
- Design Document: Section 5 (Push Notification Handler)
- Requirements: Requirement 15 (Push Notifications for Showtime Reminders)
- Requirements: Requirement 37 (Push Notification Device Registration)
