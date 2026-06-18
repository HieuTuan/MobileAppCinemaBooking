import 'package:cine_book/models/app_models.dart';
import 'package:cine_book/src/features/admin/admin_dashboard.dart';
import 'package:cine_book/src/features/auth/auth_screen.dart';
import 'package:cine_book/src/features/customer/customer_shell.dart';
import 'package:cine_book/src/features/staff/staff_dashboard.dart';
import 'package:cine_book/src/state/cinema_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'push_notification_handler.dart';

GoRouter createRouter(CinemaStore store) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => _buildRoot(context, store),
      ),
      GoRoute(
        path: '/booking/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
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
  if (user == null) return AuthScreen(store: store);
  return switch (user.role) {
    UserRole.customer => CustomerShell(store: store),
    UserRole.staff => StaffDashboard(store: store),
    UserRole.admin => AdminDashboard(store: store),
  };
}
