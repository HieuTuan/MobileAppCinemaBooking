import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/app.dart';

/// Main entry point for the CineLuxe Booking app
///
/// Initializes Firebase before running the app to ensure
/// push notifications and other Firebase services work correctly.
///
/// **Requirements:**
/// - Requirement 15.3: Set up Firebase messaging integration
/// - Requirement 37.1: Initialize Firebase core before app starts
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    debugPrint('Main: Firebase initialized successfully');
  } catch (e) {
    debugPrint('Main: Firebase initialization failed: $e');
    // Continue app startup even if Firebase fails
    // Push notifications won't work, but core features will
  }
  
  runApp(const CineBookingApp());
}
