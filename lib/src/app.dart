import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/app_theme.dart';
import 'models/app_models.dart';
import 'state/cinema_store.dart';
import '../services/analytics_service.dart';
import '../services/locale_service.dart';
import '../services/navigation_service.dart';
import '../services/push_notification_handler.dart';
import '../services/router.dart';
import '../widgets/notification_banner.dart';
import 'shared/widgets/analytics_consent_banner.dart';

class CineBookingApp extends StatefulWidget {
  const CineBookingApp({super.key});

  @override
  State<CineBookingApp> createState() => _CineBookingAppState();
}

class _CineBookingAppState extends State<CineBookingApp> {
  late final CinemaStore store;
  late final GoRouter router;
  late final PushNotificationHandler _pushNotificationHandler;

  @override
  void initState() {
    super.initState();
    store = CinemaStore();
    router = createRouter(store);

    // Listen to locale changes so the widget tree rebuilds.
    LocaleService.instance.addListener(_onLocaleChanged);

    _pushNotificationHandler = PushNotificationHandler();
    _initializePushNotifications();

    // Show GDPR consent banner on first launch (Req 41.7, 45.8)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = NavigationService.context;
      if (ctx != null && ctx.mounted) {
        AnalyticsConsentBanner.showIfNeeded(ctx);
      }
    });
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  /// Handles navigation when the user taps a push notification.
  void _handleNotificationTap(NotificationRoute route) {
    switch (route.path) {
      case '/':
        router.go('/');
      case '/booking/':
        final bookingId = route.queryParams['bookingId'];
        if (bookingId != null) router.go('/booking/$bookingId');
      case '/movie/':
        final movieId = route.queryParams['movieId'];
        if (movieId != null) router.go('/movie/$movieId');
      case '/promotion/':
        router.go('/');
    }
  }

  Future<void> _initializePushNotifications() async {
    try {
      await _pushNotificationHandler.initialize();
      _pushNotificationHandler.notificationStream.listen((message) {
        debugPrint('App: Foreground notification received');
        final context = NavigationService.context;
        if (context == null) return;
        NotificationBanner.show(
          context: context,
          message: message,
          onTap: () => _pushNotificationHandler.handleNotificationTap(message),
        );
      });
      debugPrint('App: Push notification handler initialized');
    } catch (e) {
      debugPrint('App: Failed to initialize push notifications: $e');
    }
  }

  @override
  void dispose() {
    LocaleService.instance.removeListener(_onLocaleChanged);
    store.dispose();
    _pushNotificationHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'CineLuxe Booking',
          theme: buildAppTheme(),
          routerConfig: router,
          // ── Localization ─────────────────────────────────────
          locale: LocaleService.instance.locale,
          supportedLocales: LocaleService.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}