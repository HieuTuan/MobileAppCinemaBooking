import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/app.dart';
import 'services/analytics_service.dart';
import 'services/locale_service.dart';

/// Main entry point for the CineLuxe Booking app.
///
/// Initialises Firebase, locale preference, and analytics before
/// running the app.
///
/// **Requirements:**
/// - 15.3 / 37.1: Firebase messaging
/// - 39.1, 39.2: Language detection and persistence
/// - 41.1, 41.2: Firebase Analytics setup
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Core + Analytics + Messaging)
  try {
    await Firebase.initializeApp();
    debugPrint('Main: Firebase initialized successfully');
  } catch (e) {
    debugPrint('Main: Firebase initialization failed: $e');
  }

  // Initialize analytics (non-blocking)
  try {
    await AnalyticsService.instance.initialize();
    debugPrint('Main: Analytics initialized');
  } catch (e) {
    debugPrint('Main: Analytics init failed: $e');
  }

  // Initialize locale preference
  await LocaleService.instance.init();

  // Track app_open event
  AnalyticsService.instance.trackAppOpen();

  runApp(const CineBookingApp());
}
