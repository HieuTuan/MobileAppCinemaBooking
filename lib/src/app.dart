import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/auth/auth_screen.dart';
import 'features/customer/customer_shell.dart';
import 'features/staff/staff_dashboard.dart';
import 'models/app_models.dart';
import 'state/cinema_store.dart';

class CineBookingApp extends StatefulWidget {
  const CineBookingApp({super.key});

  @override
  State<CineBookingApp> createState() => _CineBookingAppState();
}

class _CineBookingAppState extends State<CineBookingApp> {
  late final CinemaStore store;

  @override
  void initState() {
    super.initState();
    store = CinemaStore();
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
        return MaterialApp(
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
