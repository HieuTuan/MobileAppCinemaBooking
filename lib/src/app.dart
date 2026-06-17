import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/auth/auth_screen.dart';
import 'features/customer/customer_shell.dart';
import 'features/staff/staff_dashboard.dart';
import 'models/app_models.dart';
import 'state/cinema_store.dart';
import '../services/push_notification_handler.dart';
import '../services/navigation_service.dart';
import '../widgets/notification_banner.dart';

class CineBookingApp extends StatefulWidget {
  const CineBookingApp({super.key});

  @override
  State<CineBookingApp> createState() => _CineBookingAppState();
}

class _CineBookingAppState extends State<CineBookingApp> {
  late final CinemaStore store;
  late final PushNotificationHandler _pushNotificationHandler;

  @override
  void initState() {
    super.initState();
    store = CinemaStore();
    _pushNotificationHandler = PushNotificationHandler();
    _initializePushNotifications();
  }

  /// Initialize push notifications and set up foreground handlers
  ///
  /// This method:
  /// 1. Initializes Firebase messaging
  /// 2. Sets up foreground notification listener
  /// 3. Displays in-app banners for foreground notifications
  ///
  /// **Requirements:**
  /// - Requirement 15.6: Handle foreground notifications with in-app banner
  /// - Requirement 16.6: Route notifications to appropriate screens
  Future<void> _initializePushNotifications() async {
    try {
      // Initialize push notification handler
      await _pushNotificationHandler.initialize();
      
      // Listen to foreground notifications
      _pushNotificationHandler.notificationStream.listen((message) {
        debugPrint('App: Foreground notification received');
        
        // Get current context
        final context = NavigationService.context;
        if (context == null) {
          debugPrint('App: No context available for showing banner');
          return;
        }
        
        // Show in-app notification banner
        NotificationBanner.show(
          context: context,
          message: message,
          onTap: () {
            debugPrint('App: Notification banner tapped');
            _pushNotificationHandler.handleNotificationTap(message);
          },
        );
      });
      
      debugPrint('App: Push notification handler initialized');
    } catch (e) {
      debugPrint('App: Failed to initialize push notifications: $e');
      // Continue app startup even if push notifications fail
      // User can still use the app without notifications
    }
  }

  @override
  void dispose() {
    store.dispose();
    _pushNotificationHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          // Register global navigator key for deep linking and push notifications
          navigatorKey: NavigationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'CineLuxe Booking',
          theme: buildAppTheme(),
          home: _homeForRole(),
        );
      },
    );
  }

  Widget _homeForRole() {
    final user = store.currentUser;
    if (user == null) return AuthScreen(store: store);
    return switch (user.role) {
      UserRole.customer => CustomerShell(store: store),
      UserRole.staff => StaffDashboard(store: store),
      UserRole.admin => AdminDashboard(store: store),
    };
  }
}
