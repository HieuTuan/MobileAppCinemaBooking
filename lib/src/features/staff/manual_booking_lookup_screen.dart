import 'package:flutter/material.dart';
import '../../../models/booking_models.dart';
import '../../../services/staff_booking_service.dart';

/// Screen for staff to manually search and validate bookings.
///
/// **Requirements Coverage:**
/// - Requirement 12.1: Search bookings by booking ID
/// - Requirement 12.2: Search bookings by customer name
/// - Requirement 12.3: Display search results with booking details
/// - Requirement 12.6: Manual validation button for selected booking
/// - Requirement 12.7: Call validation endpoint with staffId
/// - Requirement 12.8: Apply same validation rules as QR code validation
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => ManualBookingLookupScreen(
///       staffId: 'STAFF001',
///       expectedShowtimeId: 'SH789',
///     ),
///   ),
/// );
/// ```
class ManualBookingLookupScreen extends StatefulWidget {
  final String staffId;
  final String expectedShowtimeId;

  const ManualBookingLookupScreen({
    super.key,
    required this.staffId,
    required this.expectedShowtimeId,
  });

  @override
  State<ManualBookingLookupScreen> createState() =>
      _ManualBookingLookupScreenState();
}

class _ManualBookingLookupScreenState
    extends State<ManualBookingLookupScreen> {
  final _bookingIdController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _service = StaffBookingService();

  List<BookingDetails>? _searchResults;
  bool _isSearching = false;
  String? _errorMessage;
  bool _isValidating = false;

  @override
  void dispose() {
    _bookingIdController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _searchBookings() async {
    final bookingId = _bookingIdController.text.trim();
    final customerName = _customerNameController.text.trim();

    if (bookingId.isEmpty && customerName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter booking ID or customer name';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults = null;
    });

    try {
      final results = await _service.searchBookings(
        bookingId: bookingId.isNotEmpty ? bookingId : null,
        customerName: customerName.isNotEmpty ? customerName : null,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
        if (results.isEmpty) {
          _errorMessage = 'No bookings found';
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Search failed: ${e.toString()}';
      });
    }
  }

  Future<void> _validateBooking(BookingDetails booking) async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.manuallyValidateBooking(
        bookingId: booking.bookingId,
        expectedShowtimeId: widget.expectedShowtimeId,
        staffId: widget.staffId,
      );

      if (result.success) {
        if (!mounted) return;
        setState(() {
          if (_searchResults != null) {
            final index = _searchResults!.indexWhere((b) => b.bookingId == booking.bookingId);
            if (index != -1) {
              final b = _searchResults![index];
              _searchResults![index] = BookingDetails(
                bookingId: b.bookingId,
                userId: b.userId,
                showtimeId: b.showtimeId,
                movieTitle: b.movieTitle,
                roomName: b.roomName,
                cinemaName: b.cinemaName,
                showtimeDateTime: b.showtimeDateTime,
                seatCodes: b.seatCodes,
                combos: b.combos,
                totalAmount: b.totalAmount,
                status: 'used',
                paymentStatus: b.paymentStatus,
                createdAt: b.createdAt,
                qrCode: b.qrCode,
              );
            }
          }
          _isValidating = false;
        });
        _showValidationSuccessDialog(result);
      } else {
        setState(() {
          _errorMessage = result.message;
          _isValidating = false;
        });
      }
    } catch (e) {
      setState(() {
        _isValidating = false;
        _errorMessage = 'Validation failed: ${e.toString()}';
      });
    }
  }

  void _showValidationSuccessDialog(ValidationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Validation Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${result.customerName}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Movie: ${result.movieTitle}'),
            Text('Seats: ${result.seatCodes.join(', ')}'),
            Text('Showtime: ${_formatDateTime(result.showtimeDateTime)}'),
            const SizedBox(height: 8),
            Text(
              'Validated at: ${_formatDateTime(result.validatedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Booking Lookup'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search Booking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bookingIdController,
                      decoration: const InputDecoration(
                        labelText: 'Booking ID',
                        hintText: 'Enter booking ID (e.g., BK123456)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.confirmation_number),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'OR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        hintText: 'Enter customer full name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSearching ? null : _searchBookings,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                            _isSearching ? 'Searching...' : 'Search Booking'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Search Results
            if (_searchResults != null && _searchResults!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(_searchResults!.map((booking) => _buildBookingCard(booking))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingDetails booking) {
    final isValidationDisabled = _isValidating || booking.status != 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.movieTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
            const Divider(height: 20),
            _buildInfoRow(Icons.confirmation_number, 'Booking ID',
                booking.bookingId),
            _buildInfoRow(Icons.event, 'Showtime',
                _formatDateTime(booking.showtimeDateTime)),
            _buildInfoRow(
                Icons.location_on, 'Cinema', '${booking.cinemaName} - ${booking.roomName}'),
            _buildInfoRow(
                Icons.event_seat, 'Seats', booking.seatCodes.join(', ')),
            _buildInfoRow(Icons.payments, 'Total',
                '${booking.totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} VND'),
            _buildInfoRow(Icons.payment, 'Payment', booking.paymentStatus),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isValidationDisabled
                    ? null
                    : () => _validateBooking(booking),
                icon: _isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isValidating
                    ? 'Validating...'
                    : 'Validate Ticket'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: isValidationDisabled
                      ? Colors.grey
                      : Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (booking.status != 'active') ...[
              const SizedBox(height: 8),
              Text(
                'Cannot validate: Booking status is "${booking.status}"',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String displayText;

    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        displayText = 'Active';
        break;
      case 'used':
        color = Colors.blue;
        displayText = 'Used';
        break;
      case 'cancelled':
        color = Colors.red;
        displayText = 'Cancelled';
        break;
      case 'refunded':
        color = Colors.orange;
        displayText = 'Refunded';
        break;
      default:
        color = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
