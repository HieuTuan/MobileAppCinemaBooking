import '../api/api_client.dart';
import '../models/booking_models.dart';

/// Service for staff booking search and manual validation operations.
///
/// **Requirements Coverage:**
/// - Requirement 12.1: Search bookings by booking ID
/// - Requirement 12.2: Search bookings by customer name
/// - Requirement 12.6: Manual validation from search results
/// - Requirement 12.7: Call validation endpoint with staffId
/// - Requirement 12.8: Apply same validation rules as QR code validation
///
/// Usage:
/// ```dart
/// final service = StaffBookingService();
///
/// // Search by booking ID
/// final results = await service.searchBookings(bookingId: 'BK123456');
///
/// // Search by customer name
/// final results = await service.searchBookings(customerName: 'John Doe');
///
/// // Manually validate a booking
/// final result = await service.manuallyValidateBooking(
///   bookingId: 'BK123456',
///   expectedShowtimeId: 'SH789',
///   staffId: 'STAFF001',
/// );
/// ```
class StaffBookingService {
  final APIClient _apiClient;

  StaffBookingService({APIClient? apiClient}) 
      : _apiClient = apiClient ?? APIClient();

  /// Search for bookings by booking ID or customer name.
  ///
  /// **Requirements:**
  /// - 12.1: Search by booking ID
  /// - 12.2: Search by customer name
  /// - 12.3: Return booking details with all relevant information
  /// - 12.4: Limit to showtimes within 24 hours
  ///
  /// At least one parameter must be provided.
  ///
  /// Returns list of matching bookings, or empty list if no matches found.
  Future<List<BookingDetails>> searchBookings({
    String? bookingId,
    String? customerName,
  }) async {
    if ((bookingId == null || bookingId.isEmpty) &&
        (customerName == null || customerName.isEmpty)) {
      throw ArgumentError(
        'At least one search parameter (bookingId or customerName) must be provided',
      );
    }

    return await _apiClient.searchBookings(
      bookingId: bookingId,
      customerName: customerName,
    );
  }

  /// Manually validate a booking from search results.
  ///
  /// **Requirements:**
  /// - 12.6: Display manual validation button for selected booking
  /// - 12.7: Call validation endpoint with staffId
  /// - 12.8: Apply same validation rules as QR code validation
  ///
  /// This applies the same validation rules as QR code scanning:
  /// - Verify booking exists and status is active
  /// - Check booking status (reject if already used, cancelled, or refunded)
  /// - Verify showtime matches expected showtime
  /// - Enforce validation time window (2 hours before to 30 minutes after showtime)
  /// - Update booking status to 'used' on success
  /// - Record validation timestamp and staffId
  ///
  /// Parameters:
  /// - [bookingId]: The booking ID to validate
  /// - [expectedShowtimeId]: The showtime ID that should match the booking
  /// - [staffId]: The staff member performing the validation
  ///
  /// Returns ValidationResult with success status and booking details.
  ///
  /// Throws exceptions for validation errors (handled by error interceptor).
  Future<ValidationResult> manuallyValidateBooking({
    required String bookingId,
    required String expectedShowtimeId,
    required String staffId,
  }) async {
    return await _apiClient.validateTicket(
      bookingId,
      expectedShowtimeId,
      staffId: staffId,
    );
  }

  /// Get full booking details for display before validation.
  ///
  /// Helper method to fetch complete booking information
  /// before staff performs manual validation.
  Future<BookingDetails> getBookingDetails(String bookingId) async {
    return await _apiClient.getBookingDetails(bookingId);
  }
}
