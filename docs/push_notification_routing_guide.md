# Push Notification Routing Guide

## Overview

This document describes the push notification handling and routing implementation for task 19.4 of the Cinema Booking API Integration spec.

## Architecture

### Components

1. **PushNotificationHandler** (`lib/services/push_notification_handler.dart`)
   - Manages Firebase Messaging setup
   - Listens for foreground, background, and terminated state notifications
   - Routes notifications to appropriate screens based on deeplink or notification type

2. **NavigationService** (`lib/services/navigation_service.dart`)
   - Provides global navigation without BuildContext
   - Exposes methods for navigating to specific screens (booking details, movie details, promotions)
   - Uses GlobalKey<NavigatorState> for accessing navigator from anywhere

3. **NotificationBanner** (`lib/widgets/notification_banner.dart`)
   - Displays in-app notification banners when app is in foreground
   - Shows notification title and body with tap-to-view functionality
   - Uses SnackBar for temporary, non-intrusive display

## Notification States

### Foreground (App Active)

When a notification is received while the app is in the foreground:

1. `FirebaseMessaging.onMessage` listener fires
2. Notification is emitted through `PushNotificationHandler.notificationStream`
3. App (`app.dart`) listens to the stream and shows an in-app banner
4. User can tap the banner to navigate to the destination screen

**Implementation:**
```dart
// In app.dart
_pushNotificationHandler.notificationStream.listen((message) {
  NotificationBanner.show(
    context: context,
    message: message,
    onTap: () => _pushNotificationHandler.handleNotificationTap(message),
  );
});
```

### Background (App Suspended)

When a notification is received and tapped while the app is in the background:

1. OS displays the notification
2. User taps the notification
3. App resumes
4. `FirebaseMessaging.onMessageOpenedApp` listener fires
5. `handleNotificationTap` is called with the message
6. Navigation occurs based on deeplink or type

**Implementation:**
```dart
// In PushNotificationHandler.initialize()
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  handleNotificationTap(message);
});
```

### Terminated (App Closed)

When a notification is received and tapped while the app was terminated:

1. OS displays the notification
2. User taps the notification
3. App launches
4. During initialization, `getInitialMessage()` is called
5. If a message exists, `handleNotificationTap` is called
6. Navigation occurs after app is fully initialized

**Implementation:**
```dart
// In PushNotificationHandler.initialize()
FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
  if (message != null) {
    handleNotificationTap(message);
  }
});
```

## Deeplink Format

### Supported Deeplink Patterns

#### Booking Details
```
cinema://booking/{bookingId}
```
Example: `cinema://booking/abc123`

Routes to: Booking confirmation screen showing ticket QR code and details

#### Movie Details
```
cinema://movie/{movieId}
```
Example: `cinema://movie/movie789`

Routes to: Movie details loader screen (fetches movie from API, then shows details)

#### Promotions
```
cinema://promotions
```

Routes to: Promotions dialog/screen showing current offers

### Deeplink Parsing

Deeplinks use the URI scheme format where:
- **Scheme**: `cinema`
- **Host**: Route type (booking, movie, promotions)
- **Path**: Resource ID (if applicable)

**Example:**
```dart
final uri = Uri.parse('cinema://booking/abc123');
// uri.scheme = 'cinema'
// uri.host = 'booking'
// uri.pathSegments[0] = 'abc123'
```

## Notification Types

### Type-Based Routing (Fallback)

When a deeplink is not present, the notification type field is used for routing:

| Type | Routes To | Required Data |
|------|-----------|---------------|
| `showtime_reminder` | Booking details | `bookingId` |
| `booking_confirmation` | Booking details | `bookingId` |
| `booking_cancellation` | Booking details | `bookingId` |
| `promotion` | Movie details or promotions | `movieId` (optional) |
| `new_movie` | Movie details or movie list | `movieId` (optional) |

**Example Notification Payloads:**

```json
// Showtime reminder
{
  "notification": {
    "title": "Showtime Reminder",
    "body": "Your movie starts in 2 hours"
  },
  "data": {
    "type": "showtime_reminder",
    "bookingId": "booking123",
    "deeplink": "cinema://booking/booking123"
  }
}

// Promotional notification
{
  "notification": {
    "title": "New Movie Alert!",
    "body": "Check out the latest blockbuster"
  },
  "data": {
    "type": "promotion",
    "movieId": "movie456",
    "deeplink": "cinema://movie/movie456"
  }
}
```

## Integration Guide

### 1. Register Navigator Key

In `MaterialApp`, register the `NavigationService.navigatorKey`:

```dart
MaterialApp(
  navigatorKey: NavigationService.navigatorKey,
  ...
)
```

### 2. Initialize Push Notifications

In your app's `initState`:

```dart
final _pushNotificationHandler = PushNotificationHandler();

await _pushNotificationHandler.initialize();
```

### 3. Listen to Foreground Notifications

Set up a listener for foreground notifications:

```dart
_pushNotificationHandler.notificationStream.listen((message) {
  final context = NavigationService.context;
  if (context != null) {
    NotificationBanner.show(
      context: context,
      message: message,
      onTap: () => _pushNotificationHandler.handleNotificationTap(message),
    );
  }
});
```

### 4. Initialize Firebase

In `main.dart`, initialize Firebase before running the app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CineBookingApp());
}
```

## Testing

### Unit Tests

Run the notification routing tests:

```bash
flutter test test/services/notification_routing_test.dart
```

**Test Coverage:**
- Deeplink parsing for all supported formats
- Type-based routing fallback
- Priority of deeplink over type
- Handling of malformed/missing data
- Requirements validation (15.6, 16.6, 15.7)

### Manual Testing

#### Test Foreground Notifications

1. Run the app on a device/emulator
2. Keep the app in foreground
3. Send a test notification from Firebase Console or backend
4. Verify in-app banner appears
5. Tap the banner and verify navigation

#### Test Background Notifications

1. Run the app and put it in background (home button)
2. Send a test notification
3. Tap the notification from the notification tray
4. App should open and navigate to the correct screen

#### Test Terminated State Notifications

1. Completely close the app (swipe away from recent apps)
2. Send a test notification
3. Tap the notification from the notification tray
4. App should launch and navigate to the correct screen after initialization

## Requirements Satisfied

### Requirement 15.6
**THE Customer_App SHALL handle notification tap by navigating to booking details screen with bookingId**

✅ Implemented via deeplink `cinema://booking/{bookingId}` and type-based routing for showtime reminders and booking confirmations.

### Requirement 15.7
**THE Backend_API SHALL log all notification delivery attempts with status, timestamp, and deviceId**

✅ Backend requirement - client implementation supports receiving and routing notifications correctly.

### Requirement 16.6
**WHEN customer taps promotional notification, THE Customer_App SHALL navigate to promotions or movie list screen based on deeplink**

✅ Implemented via deeplinks `cinema://movie/{movieId}` and `cinema://promotions`, with fallback to type-based routing.

## Troubleshooting

### Notifications Not Appearing

**Issue:** Notifications don't show up when app is in foreground

**Solution:** Check that the notification stream listener is set up correctly in `app.dart` and that `NotificationBanner.show()` is being called.

### Navigation Not Working

**Issue:** Tapping notification doesn't navigate to the screen

**Solution:** 
1. Verify `NavigationService.navigatorKey` is registered in MaterialApp
2. Check that Firebase is initialized before app runs
3. Ensure notification data contains valid deeplink or type field

### Firebase Initialization Errors

**Issue:** Firebase fails to initialize

**Solution:**
1. Verify `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are present
2. Check that `firebase_core` is properly configured in `pubspec.yaml`
3. Ensure `WidgetsFlutterBinding.ensureInitialized()` is called before `Firebase.initializeApp()`

### Deeplink Parsing Errors

**Issue:** Deeplinks not routing correctly

**Solution:**
1. Verify deeplink format matches `cinema://route/id` pattern
2. Check URI parsing logic uses `uri.host` for route and `uri.pathSegments[0]` for ID
3. Test with the unit tests to validate parsing logic

## Future Enhancements

1. **Rich Notifications**: Add images, action buttons, and custom sounds
2. **Notification Preferences**: Honor user's notification settings from API
3. **Analytics**: Track notification open rates and user engagement
4. **Deep State Restoration**: Preserve navigation stack when opening from notification
5. **Notification History**: Local storage of received notifications for later viewing
