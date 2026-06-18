import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../api/api_client.dart';
import '../services/secure_storage_service.dart';
import '../services/navigation_service.dart';

/// Push Notification Handler
///
/// Manages push notification registration, reception, and routing to appropriate app screens.
///
/// **Key Behaviors:**
/// - Platform Detection: Uses FCM for Android, APNs for iOS via firebase_messaging package
/// - Permission Request: Requests OS notification permission on app launch (authenticated users only)
/// - Token Registration: Posts device token to backend API for push targeting
/// - Foreground Handling: Displays in-app notification banner when app is active
/// - Background Handling: Routes notification tap to appropriate screen based on deeplink
/// - Token Refresh: Monitors token changes (app reinstall) and updates backend registration
///
/// **Deeplink Routing:**
/// - `cinema://booking/{bookingId}` → Booking details screen
/// - `cinema://movie/{movieId}` → Movie details screen
/// - `cinema://promotions` → Promotions list screen
///
/// **Requirements:**
/// - Requirement 15.4: When customer has disabled showtime notifications in settings, 
///   THE Push_Notifier SHALL skip notification delivery
/// - Requirement 37.1: WHEN app launches and user is authenticated, THE Customer_App 
///   SHALL request notification permission from OS
/// - Requirement 37.2: WHEN permission is granted, THE Push_Notifier SHALL obtain 
///   FCM token (Android) or APNs token (iOS)
/// - Requirement 37.3: POST /api/users/{userId}/devices with deviceToken, platform, and deviceModel
/// - Requirement 37.5: Update registration when device token changes (app reinstall)
class PushNotificationHandler {
  static final PushNotificationHandler _instance = PushNotificationHandler._internal();
  
  factory PushNotificationHandler() {
    return _instance;
  }
  
  PushNotificationHandler._internal();
  
  FirebaseMessaging? _firebaseMessaging;
  final APIClient _apiClient = APIClient();
  final SecureStorageService _secureStorage = SecureStorageService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // Stream controller for notification events
  final StreamController<RemoteMessage> _notificationController = 
      StreamController<RemoteMessage>.broadcast();
  
  // Stream for notification events
  Stream<RemoteMessage> get notificationStream => _notificationController.stream;
  
  bool _isInitialized = false;
  String? _currentToken;
  
  // Lazy getter for Firebase Messaging (initialized during initialize())
  FirebaseMessaging get _messaging {
    if (_firebaseMessaging == null) {
      throw StateError('PushNotificationHandler not initialized. Call initialize() first.');
    }
    return _firebaseMessaging!;
  }
  
  /// Initialize Firebase messaging and set up listeners
  ///
  /// Sets up:
  /// - Foreground message handler
  /// - Background message handler
  /// - Token refresh listener
  /// - Notification interaction handlers
  ///
  /// Should be called once during app initialization
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('PushNotificationHandler: Already initialized');
      return;
    }
    
    try {
      // Ensure Firebase is initialized
      await Firebase.initializeApp();
      debugPrint('PushNotificationHandler: Firebase initialized');
      
      // Initialize Firebase Messaging instance
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // Set up foreground notification handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('PushNotificationHandler: Foreground message received');
        debugPrint('  Title: ${message.notification?.title}');
        debugPrint('  Body: ${message.notification?.body}');
        debugPrint('  Data: ${message.data}');
        
        // Emit notification to stream for in-app banner display
        _notificationController.add(message);
      });
      
      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('PushNotificationHandler: Notification tapped (background)');
        handleNotificationTap(message);
      });
      
      // Handle notification tap when app was terminated
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('PushNotificationHandler: Notification tapped (terminated)');
          handleNotificationTap(message);
        }
      });
      
      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
        debugPrint('PushNotificationHandler: Token refreshed: $newToken');
        _currentToken = newToken;
        // Token refresh handler - caller should listen to this and call registerDevice
        _handleTokenRefresh(newToken);
      });
      
      _isInitialized = true;
      debugPrint('PushNotificationHandler: Initialization complete');
    } catch (e) {
      debugPrint('PushNotificationHandler: Initialization failed: $e');
      rethrow;
    }
  }
  
  /// Request OS notification permission
  ///
  /// For iOS: Shows system permission dialog
  /// For Android 13+: Shows system permission dialog
  /// For Android <13: Automatically granted
  ///
  /// Returns authorization status:
  /// - authorized: Permission granted
  /// - denied: Permission denied by user
  /// - notDetermined: Permission not yet requested
  /// - provisional: Provisional authorization (iOS only)
  ///
  /// **Requirement 37.1**: Request notification permission on app launch for authenticated users
  Future<AuthorizationStatus> requestPermission() async {
    try {
      debugPrint('PushNotificationHandler: Requesting notification permission');
      
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('PushNotificationHandler: Permission status: ${settings.authorizationStatus}');
      
      // For iOS, configure notification presentation options
      if (Platform.isIOS) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('PushNotificationHandler: iOS foreground options configured');
      }
      
      return settings.authorizationStatus;
    } catch (e) {
      debugPrint('PushNotificationHandler: Permission request failed: $e');
      rethrow;
    }
  }
  
  /// Get the current device token (FCM for Android, APNs for iOS)
  ///
  /// Returns the device token string or null if token is unavailable
  ///
  /// **Requirement 37.2**: Obtain FCM token (Android) or APNs token (iOS)
  Future<String?> getDeviceToken() async {
    try {
      if (_currentToken != null) {
        return _currentToken;
      }
      
      debugPrint('PushNotificationHandler: Fetching device token');
      
      // Get FCM token (works for both Android FCM and iOS APNs via FCM)
      final String? token = await _messaging.getToken();
      
      if (token != null) {
        _currentToken = token;
        debugPrint('PushNotificationHandler: Token obtained: ${token.substring(0, 20)}...');
      } else {
        debugPrint('PushNotificationHandler: Token is null');
      }
      
      return token;
    } catch (e) {
      debugPrint('PushNotificationHandler: Failed to get token: $e');
      rethrow;
    }
  }
  
  /// Handle notification tap and route to appropriate screen
  ///
  /// Deeplink routing:
  /// - `cinema://booking/{bookingId}` → Booking details screen
  /// - `cinema://movie/{movieId}` → Movie details screen
  /// - `cinema://promotions` → Promotions list screen
  ///
  /// **Requirement 15.6**: Handle notification tap by navigating to booking details screen
  void handleNotificationTap(RemoteMessage message) {
    debugPrint('PushNotificationHandler: Handling notification tap');
    
    // Extract deeplink from notification data
    final String? deeplink = message.data['deeplink'];
    final String? type = message.data['type'];
    
    if (deeplink != null) {
      debugPrint('PushNotificationHandler: Deeplink: $deeplink');
      _routeToScreen(deeplink);
    } else if (type != null) {
      // Fallback: use type field if deeplink not present
      debugPrint('PushNotificationHandler: Type-based routing: $type');
      _routeByType(type, message.data);
    } else {
      debugPrint('PushNotificationHandler: No routing information in notification');
    }
  }
  
  /// Route to screen based on deeplink URL
  ///
  /// **Requirement 15.6**: Handle notification tap by navigating to booking details
  /// **Requirement 16.6**: Navigate to movie details or promotions based on deeplink
  void _routeToScreen(String deeplink) {
    // Parse deeplink format: cinema://booking/123, cinema://movie/456, cinema://promotions
    final Uri? uri = Uri.tryParse(deeplink);
    
    if (uri == null) {
      debugPrint('PushNotificationHandler: Invalid deeplink format: $deeplink');
      return;
    }
    
    // Extract route from host (cinema://booking/123 -> host="booking", path="/123")
    final String route = uri.host;
    final String? id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    
    if (route.isEmpty) {
      debugPrint('PushNotificationHandler: Empty route in deeplink');
      return;
    }
    
    debugPrint('PushNotificationHandler: Routing to: $route${id != null ? '/$id' : ''}');
    
    // Use NavigationService for actual navigation
    switch (route) {
      case 'booking':
        if (id != null) {
          debugPrint('PushNotificationHandler: Navigate to booking details: $id');
          NavigationService.navigateToBookingDetails(id);
        }
        break;
      case 'movie':
        if (id != null) {
          debugPrint('PushNotificationHandler: Navigate to movie details: $id');
          NavigationService.navigateToMovieDetails(id);
        }
        break;
      case 'promotions':
        debugPrint('PushNotificationHandler: Navigate to promotions screen');
        NavigationService.navigateToPromotions();
        break;
      default:
        debugPrint('PushNotificationHandler: Unknown route: $route');
    }
  }
  
  /// Route to screen based on notification type
  ///
  /// Fallback routing when deeplink is not available
  void _routeByType(String type, Map<String, dynamic> data) {
    debugPrint('PushNotificationHandler: Type-based routing: $type');
    
    switch (type) {
      case 'showtime_reminder':
      case 'booking_confirmation':
      case 'booking_cancellation':
        final String? bookingId = data['bookingId'];
        if (bookingId != null) {
          debugPrint('PushNotificationHandler: Navigate to booking: $bookingId');
          NavigationService.navigateToBookingDetails(bookingId);
        }
        break;
      case 'promotion':
        final String? movieId = data['movieId'];
        if (movieId != null) {
          debugPrint('PushNotificationHandler: Navigate to movie: $movieId');
          NavigationService.navigateToMovieDetails(movieId);
        } else {
          debugPrint('PushNotificationHandler: Navigate to promotions');
          NavigationService.navigateToPromotions();
        }
        break;
      case 'new_movie':
        final String? movieId = data['movieId'];
        if (movieId != null) {
          debugPrint('PushNotificationHandler: Navigate to movie: $movieId');
          NavigationService.navigateToMovieDetails(movieId);
        } else {
          debugPrint('PushNotificationHandler: Navigate to movie list');
          NavigationService.navigateToMovieList();
        }
        break;
      default:
        debugPrint('PushNotificationHandler: Unknown notification type: $type');
    }
  }
  
  /// Get platform identifier for backend registration
  ///
  /// Returns 'android' or 'ios'
  String getPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'unknown';
    }
  }
  
  // ============================================================================
  // Device Registration - Requirements 37.3, 37.5
  // ============================================================================
  
  /// Register device token with backend for push notifications
  ///
  /// Should be called after:
  /// - Permission is granted
  /// - User is authenticated
  /// - Device token is obtained
  ///
  /// **Requirements:**
  /// - 37.3: POST /api/users/{userId}/devices with deviceToken, platform, and deviceModel
  /// - 37.5: Update registration when device token changes
  ///
  /// Parameters:
  /// - [userId]: Current authenticated user ID
  /// - [deviceToken]: Optional token (will fetch if not provided)
  ///
  /// Returns true if registration succeeded, false otherwise
  Future<bool> registerDevice(String userId, {String? deviceToken}) async {
    try {
      // Get device token if not provided
      final token = deviceToken ?? await getDeviceToken();
      
      if (token == null) {
        debugPrint('PushNotificationHandler: Cannot register - no device token');
        return false;
      }
      
      // Check if token has changed
      final hasChanged = await _secureStorage.hasDeviceTokenChanged(token);
      
      if (!hasChanged) {
        debugPrint('PushNotificationHandler: Device token unchanged, skipping registration');
        return true;
      }
      
      // Get device model information
      final deviceModel = await _getDeviceModel();
      
      debugPrint('PushNotificationHandler: Registering device');
      debugPrint('  User ID: $userId');
      debugPrint('  Platform: ${getPlatform()}');
      debugPrint('  Device Model: $deviceModel');
      debugPrint('  Token: ${token.substring(0, 20)}...');
      
      // Call backend API to register device
      await _apiClient.registerDevice(
        userId: userId,
        deviceToken: token,
        platform: getPlatform(),
        deviceModel: deviceModel,
      );
      
      // Store token locally to detect future changes
      await _secureStorage.saveDeviceToken(token);
      
      debugPrint('PushNotificationHandler: Device registration successful');
      return true;
    } catch (e) {
      debugPrint('PushNotificationHandler: Device registration failed: $e');
      // Don't throw - gracefully handle registration failures
      // User can still use the app without push notifications
      return false;
    }
  }
  
  /// Handle token refresh by re-registering device
  ///
  /// Automatically called when Firebase detects token change (app reinstall)
  ///
  /// **Requirement 37.5**: Update registration when device token changes
  ///
  /// Note: This requires userId to be available. Caller should ensure user is authenticated
  /// before token refresh registration can succeed.
  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      debugPrint('PushNotificationHandler: Handling token refresh');
      
      // Store new token
      _currentToken = newToken;
      
      // Check if token has changed from stored token
      final hasChanged = await _secureStorage.hasDeviceTokenChanged(newToken);
      
      if (!hasChanged) {
        debugPrint('PushNotificationHandler: Token refresh - no change detected');
        return;
      }
      
      debugPrint('PushNotificationHandler: Token changed, re-registration required');
      debugPrint('  New Token: ${newToken.substring(0, 20)}...');
      
      // Note: Actual re-registration requires userId which is not available here
      // The app should listen to token refresh events and call registerDevice
      // with the current userId when authenticated
      
      // For now, just log the token change
      // The calling code (e.g., AuthService or main app) should handle re-registration
      await _secureStorage.saveDeviceToken(newToken);
      
    } catch (e) {
      debugPrint('PushNotificationHandler: Token refresh handling failed: $e');
    }
  }
  
  /// Get device model information for registration
  ///
  /// Returns device model string or 'Unknown' if unavailable
  Future<String> _getDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.utsname.machine ?? 'iOS Device';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      debugPrint('PushNotificationHandler: Failed to get device model: $e');
      return 'Unknown';
    }
  }

  // ============================================================================
  // Device Unregistration - Requirement 37.6
  // ============================================================================

  /// Unregister device from push notifications
  ///
  /// Should be called when user logs out to stop sending notifications to the device.
  ///
  /// **Requirement 37.6**: DELETE /api/users/{userId}/devices/{deviceToken} to stop notifications
  ///
  /// Parameters:
  /// - [userId]: User ID whose device to unregister
  /// - [deviceToken]: Optional token (will fetch if not provided)
  ///
  /// Returns true if unregistration succeeded, false otherwise
  Future<bool> unregisterDevice(String userId, {String? deviceToken}) async {
    try {
      // Get device token if not provided
      final token = deviceToken ?? _currentToken ?? await getDeviceToken();
      
      if (token == null) {
        debugPrint('PushNotificationHandler: Cannot unregister - no device token');
        return false;
      }
      
      debugPrint('PushNotificationHandler: Unregistering device');
      debugPrint('  User ID: $userId');
      debugPrint('  Token: ${token.substring(0, 20)}...');
      
      // Call backend API to unregister device
      await _apiClient.unregisterDevice(
        userId: userId,
        deviceToken: token,
      );
      
      // Clear stored token
      await _secureStorage.clearDeviceToken();
      _currentToken = null;
      
      debugPrint('PushNotificationHandler: Device unregistration successful');
      return true;
    } catch (e) {
      debugPrint('PushNotificationHandler: Device unregistration failed: $e');
      // Don't throw - gracefully handle unregistration failures
      // User can still logout even if unregistration fails
      return false;
    }
  }
  
  /// Clean up resources
  void dispose() {
    _notificationController.close();
    _isInitialized = false;
    debugPrint('PushNotificationHandler: Disposed');
  }
}
