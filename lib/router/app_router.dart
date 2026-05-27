import 'package:cine_book/features/auth/presentation/screens/login_screen.dart';
import 'package:cine_book/features/auth/presentation/screens/otp_screen.dart';
import 'package:cine_book/features/auth/presentation/screens/splash_screen.dart';
import 'package:cine_book/features/booking/presentation/screens/order_summary_screen.dart';
import 'package:cine_book/features/booking/presentation/screens/seat_picker_screen.dart';
import 'package:cine_book/features/booking/presentation/screens/showtime_screen.dart';
import 'package:cine_book/features/movie/presentation/screens/home_screen.dart';
import 'package:cine_book/features/movie/presentation/screens/movie_detail_screen.dart';
import 'package:cine_book/features/ticket/presentation/screens/ticket_detail_screen.dart';
import 'package:cine_book/features/ticket/presentation/screens/ticket_list_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String movieDetail = '/movie-detail';
  static const String showtime = '/showtime';
  static const String seatPicker = '/seat-picker';
  static const String orderSummary = '/order-summary';
  static const String ticketList = '/tickets';
  static const String ticketDetail = '/ticket-detail';
  static const String otp = '/otp';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: movieDetail,
        builder: (context, state) {
          final movieId = state.uri.queryParameters['id'] ?? '';
          return MovieDetailScreen(movieId: movieId);
        },
      ),
      GoRoute(
        path: showtime,
        builder: (context, state) {
          final movieId = state.uri.queryParameters['movieId'] ?? '';
          return ShowtimeScreen(movieId: movieId);
        },
      ),
      GoRoute(
        path: seatPicker,
        builder: (context, state) {
          final showtimeId = state.uri.queryParameters['showtimeId'] ?? '';
          return SeatPickerScreen(showtimeId: showtimeId);
        },
      ),
      GoRoute(
        path: orderSummary,
        builder: (context, state) {
          final showtimeId = state.uri.queryParameters['showtimeId'] ?? '';
          final seatIds = state.uri.queryParameters['seatIds']?.split(',') ?? [];
          return OrderSummaryScreen(showtimeId: showtimeId, seatIds: seatIds);
        },
      ),
      GoRoute(
        path: ticketList,
        builder: (context, state) => const TicketListScreen(),
      ),
      GoRoute(
        path: ticketDetail,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? '';
          return TicketDetailScreen(ticketId: id);
        },
      ),
      GoRoute(
        path: otp,
        builder: (context, state) {
          final verificationId = state.uri.queryParameters['verificationId'] ?? '';
          final phoneNumber = state.uri.queryParameters['phoneNumber'] ?? '';
          return OtpScreen(verificationId: verificationId, phoneNumber: phoneNumber);
        },
      ),
    ],
  );
}
