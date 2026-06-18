import 'package:cine_book/services/push_notification_handler.dart';
import 'package:cine_book/services/router.dart';
import 'package:cine_book/src/core/app_theme.dart';
import 'package:cine_book/src/state/cinema_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CineBookingApp extends StatefulWidget {
  const CineBookingApp({super.key});

  @override
  State<CineBookingApp> createState() => _CineBookingAppState();
}

class _CineBookingAppState extends State<CineBookingApp> {
  late final CinemaStore store;
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    store = CinemaStore();
    router = createRouter(store);

    PushNotificationHandler.initialize(
      onNotificationTap: (route) {
        _handleNotificationTap(route);
      },
    );
  }

  void _handleNotificationTap(NotificationRoute route) {
    switch (route.path) {
      case '/':
        router.go('/');
      case '/booking/':
        final bookingId = route.queryParams['bookingId'];
        if (bookingId != null) {
          router.go('/booking/$bookingId');
        }
      case '/movie/':
        final movieId = route.queryParams['movieId'];
        if (movieId != null) {
          router.go('/movie/$movieId');
        }
      case '/promotion/':
        router.go('/');
    }
  }

  @override
  void dispose() {
    store.dispose();
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
        );
      },
    );
  }
}
