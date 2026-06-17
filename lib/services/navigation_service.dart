import 'package:flutter/material.dart';
import '../src/features/customer/booking_confirmation_screen.dart';

/// Navigation Service for global navigation without BuildContext
///
/// This service allows navigation from anywhere in the app, including
/// push notification handlers that don't have access to BuildContext.
///
/// Usage:
/// ```dart
/// // Register navigator key in MaterialApp
/// MaterialApp(
///   navigatorKey: NavigationService.navigatorKey,
///   ...
/// )
///
/// // Navigate from anywhere
/// NavigationService.navigateToBookingDetails('booking123');
/// ```
///
/// **Requirements:**
/// - 15.6: Handle notification tap by navigating to booking details screen
/// - 16.6: Navigate to movie details or promotions based on deeplink
class NavigationService {
  /// Global navigator key for accessing navigator without context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get the current BuildContext from the navigator
  static BuildContext? get context => navigatorKey.currentContext;

  /// Navigate to booking details screen
  ///
  /// **Requirement 15.6**: Handle notification tap by navigating to booking details
  static Future<void> navigateToBookingDetails(String bookingId) async {
    final ctx = context;
    if (ctx == null) {
      debugPrint('NavigationService: No context available for navigation');
      return;
    }

    debugPrint('NavigationService: Navigating to booking details: $bookingId');

    try {
      final route = MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(bookingId: bookingId),
      );

      await navigatorKey.currentState?.push(route);
    } catch (e) {
      debugPrint('NavigationService: Failed to navigate to booking: $e');
    }
  }

  /// Navigate to movie details screen
  ///
  /// **Requirement 16.6**: Navigate to movie details based on deeplink
  ///
  /// Note: Movie details screen requires Movie object, not just movieId.
  /// For push notifications, we'll need to fetch the movie from API first
  /// or show a loading screen that fetches the movie.
  static Future<void> navigateToMovieDetails(String movieId) async {
    final ctx = context;
    if (ctx == null) {
      debugPrint('NavigationService: No context available for navigation');
      return;
    }

    debugPrint('NavigationService: Navigating to movie details: $movieId');

    try {
      // Show a loading screen that fetches the movie
      final route = MaterialPageRoute(
        builder: (_) => _MovieDetailsLoader(movieId: movieId),
      );

      await navigatorKey.currentState?.push(route);
    } catch (e) {
      debugPrint('NavigationService: Failed to navigate to movie: $e');
    }
  }

  /// Navigate to promotions screen
  ///
  /// **Requirement 16.6**: Navigate to promotions screen based on deeplink
  static Future<void> navigateToPromotions() async {
    final ctx = context;
    if (ctx == null) {
      debugPrint('NavigationService: No context available for navigation');
      return;
    }

    debugPrint('NavigationService: Navigating to promotions screen');

    try {
      // For now, show a dialog indicating promotions
      // In a full implementation, this would navigate to a promotions screen
      _showPromotionsDialog(ctx);
    } catch (e) {
      debugPrint('NavigationService: Failed to navigate to promotions: $e');
    }
  }

  /// Navigate to movie list screen (for promotional notifications)
  static Future<void> navigateToMovieList() async {
    final ctx = context;
    if (ctx == null) {
      debugPrint('NavigationService: No context available for navigation');
      return;
    }

    debugPrint('NavigationService: Navigating to movie list');

    try {
      // Pop to root (movie list is typically the home screen)
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('NavigationService: Failed to navigate to movie list: $e');
    }
  }

  /// Show promotions dialog (temporary implementation)
  static void _showPromotionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khuyến mãi'),
        content: const Text(
          'Xem các chương trình khuyến mãi và ưu đãi đặc biệt trong phần khuyến mãi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Movie details loader screen
///
/// Loads movie details from API before showing the actual movie details screen
class _MovieDetailsLoader extends StatefulWidget {
  const _MovieDetailsLoader({required this.movieId});

  final String movieId;

  @override
  State<_MovieDetailsLoader> createState() => _MovieDetailsLoaderState();
}

class _MovieDetailsLoaderState extends State<_MovieDetailsLoader> {
  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    try {
      // For now, show a simple message
      // In a full implementation, this would:
      // 1. Fetch movie from API using widget.movieId
      // 2. Pop this screen
      // 3. Navigate to actual MovieDetailScreen with the movie object
      debugPrint(
        'NavigationService: Would load movie ${widget.movieId} and navigate',
      );

      // Wait a bit to show loading state
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Show a message that movie loading would happen here
      // In production, this would fetch the movie and navigate
      _showMovieMessage();
    } catch (e) {
      debugPrint('NavigationService: Failed to load movie: $e');
      if (mounted) {
        _showError(e.toString());
      }
    }
  }

  void _showMovieMessage() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phim'),
        content: Text(
          'Đang tải thông tin phim ID: ${widget.movieId}\n\n'
          'Trong ứng dụng hoàn chỉnh, màn hình này sẽ tải thông tin phim từ API và điều hướng đến trang chi tiết phim.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text('Không thể tải thông tin phim: $error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đang tải...')),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
