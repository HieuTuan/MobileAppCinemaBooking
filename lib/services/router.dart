import 'package:cine_book/src/models/app_models.dart';
import 'package:cine_book/src/features/admin/admin_dashboard.dart';
import 'package:cine_book/src/features/auth/auth_screen.dart';
import 'package:cine_book/src/features/customer/customer_shell.dart';
import 'package:cine_book/src/features/staff/staff_dashboard.dart';
import 'package:cine_book/src/state/cinema_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'analytics_service.dart';

GoRouter createRouter(CinemaStore store) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: store,
    redirect: (context, state) {
      final loggedIn = store.currentUser != null;
      if (loggedIn && state.matchedLocation == '/auth') return '/';
      if (!loggedIn && state.matchedLocation == '/booking/:bookingId') {
        return '/auth';
      }
      return null;
    },
    // Req 41.4 — auto-track screen views via FirebaseAnalyticsObserver
    observers: [AnalyticsService.instance.observer],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return AnimatedBuilder(
            animation: store,
            builder: (context, _) => _buildRoot(context, store),
          );
        },
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) {
          return AuthScreen(
            store: store,
            startInRegister:
                state.uri.queryParameters['mode']?.toLowerCase() == 'register',
          );
        },
      ),
      GoRoute(
        path: '/booking/:bookingId',
        builder: (context, state) {
          return CustomerShell(store: store);
        },
      ),
      GoRoute(
        path: '/movie/:movieId',
        builder: (context, state) {
          return CustomerShell(store: store);
        },
      ),
      GoRoute(
        path: '/promotion/:promotionId',
        builder: (context, state) {
          return CustomerShell(store: store);
        },
      ),
    ],
  );
}

Widget _buildRoot(BuildContext context, CinemaStore store) {
  final user = store.currentUser;
  if (user == null) return CustomerShell(store: store);
  return switch (user.role) {
    UserRole.customer => CustomerShell(store: store),
    UserRole.staff => StaffDashboard(store: store),
    UserRole.admin => AdminDashboard(store: store),
  };
}
