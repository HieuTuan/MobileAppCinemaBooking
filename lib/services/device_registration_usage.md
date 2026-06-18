# Device Registration Usage Guide

This guide demonstrates how to use the device registration functionality implemented in task 19.3.

## Overview

The device registration feature allows the app to:
1. Register device tokens with the backend for push notifications
2. Detect and handle token changes (e.g., after app reinstall)
3. Automatically re-register devices when tokens refresh

## Components

### 1. APIClient - `registerDevice()` method

```dart
// Register device with backend
await apiClient.registerDevice(
  userId: 'user-123',
  deviceToken: 'fcm-token-abc123...',
  platform: 'android', // or 'ios'
  deviceModel: 'Samsung Galaxy S21',
);
```

### 2. SecureStorageService - Device token storage

```dart
// Store device token locally
await secureStorage.saveDeviceToken(token);

// Check if token has changed
final hasChanged = await secureStorage.hasDeviceTokenChanged(newToken);

// Get stored token
final storedToken = await secureStorage.getDeviceToken();
```

### 3. PushNotificationHandler - Registration integration

```dart
// Register device after obtaining token and user is authenticated
final success = await pushHandler.registerDevice(userId);

// Or provide token explicitly
final success = await pushHandler.registerDevice(
  userId, 
  deviceToken: myToken,
);
```

## Complete Integration Example

Here's a complete example showing how to integrate device registration into your app:

```dart
import 'package:cine_book/services/push_notification_handler.dart';
import 'package:cine_book/services/auth_service.dart';

class AppInitializer {
  final PushNotificationHandler _pushHandler = PushNotificationHandler();
  final AuthService _authService = AuthService();
  
  Future<void> initializePushNotifications() async {
    // Step 1: Initialize push notification handler
    await _pushHandler.initialize();
    
    // Step 2: Listen to authentication state changes
    _authService.authStateStream.listen((authState) async {
      if (authState == AuthState.authenticated) {
        await _setupPushNotifications();
      }
    });
  }
  
  Future<void> _setupPushNotifications() async {
    final user = _authService.currentUser;
    if (user == null) return;
    
    // Step 3: Request notification permission
    final status = await _pushHandler.requestPermission();
    
    if (status == AuthorizationStatus.authorized) {
      // Step 4: Register device with backend
      final success = await _pushHandler.registerDevice(user.id);
      
      if (success) {
        print('✅ Device registered for push notifications');
      } else {
        print('⚠️ Device registration failed, but app continues');
      }
    } else {
      print('ℹ️ Notification permission not granted');
    }
  }
}
```

## Token Refresh Handling

Token refresh is automatically handled by the `PushNotificationHandler`. When Firebase detects a token change (e.g., after app reinstall), it will:

1. Update the stored token in secure storage
2. Log the token change for debugging
3. The app should call `registerDevice()` again to update the backend

### Example: Re-register on token refresh

```dart
class AppLifecycleManager {
  final PushNotificationHandler _pushHandler = PushNotificationHandler();
  final AuthService _authService = AuthService();
  
  void setupTokenRefreshListener() {
    // Listen to Firebase token refresh events
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = _authService.currentUser;
      if (user != null) {
        // Re-register with new token
        await _pushHandler.registerDevice(user.id, deviceToken: newToken);
        print('✅ Device re-registered with new token');
      }
    });
  }
}
```

## Error Handling

The device registration is designed to fail gracefully:

```dart
try {
  final success = await pushHandler.registerDevice(userId);
  
  if (!success) {
    // Registration failed, but app continues normally
    // User just won't receive push notifications
    print('⚠️ Push notifications unavailable');
  }
} catch (e) {
  // Network or API errors are caught internally
  // No need to handle exceptions here
  print('Device registration error: $e');
}
```

## Backend API Endpoint

The device registration calls this backend endpoint:

```
POST /api/users/{userId}/devices
Content-Type: application/json
Authorization: Bearer <jwt-token>

{
  "deviceToken": "fcm-token-or-apns-token",
  "platform": "android", // or "ios"
  "deviceModel": "Samsung Galaxy S21" // optional
}
```

## Requirements Coverage

✅ **Requirement 37.3**: POST /api/users/{userId}/devices with deviceToken, platform, and deviceModel
✅ **Requirement 37.5**: Update registration when device token changes (app reinstall)

## Platform-Specific Notes

### Android
- Platform value: `"android"`
- Uses FCM (Firebase Cloud Messaging) tokens
- Device model format: `"Manufacturer Model"` (e.g., `"Samsung Galaxy S21"`)

### iOS
- Platform value: `"ios"`
- Uses APNs tokens via Firebase Messaging
- Device model format: Machine identifier (e.g., `"iPhone14,2"`)

## Testing

To test device registration:

1. **Manual Testing**:
   - Run the app and sign in
   - Grant notification permission
   - Check logs for "Device registration successful"
   - Verify backend receives the device registration

2. **Token Refresh Testing**:
   - Reinstall the app
   - Sign in again
   - Verify new token is registered with backend

3. **Error Testing**:
   - Test with no network connection
   - Test with invalid user ID
   - Verify app continues to work despite registration failure
