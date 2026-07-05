class QrCodeFormatException implements FormatException {
  const QrCodeFormatException(this.message);

  @override
  final String message;

  @override
  int? get offset => null;

  @override
  dynamic get source => null;

  @override
  String toString() => 'QrCodeFormatException: $message';
}

class QrTicketData {
  const QrTicketData({
    required this.bookingId,
    required this.userId,
    required this.showtimeId,
    required this.seats,
  });

  final String bookingId;
  final String userId;
  final String showtimeId;
  final List<String> seats;
}

final RegExp _bookingIdPattern = RegExp(
  r'BK-[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);

QrTicketData parseQrTicket(String value) {
  final parts = value.trim().split('|');
  if (parts.length != 5 || parts.first != 'CINELUXE') {
    throw const QrCodeFormatException('Invalid CineLuxe QR format');
  }
  if (parts.skip(1).any((part) => part.trim().isEmpty)) {
    throw const QrCodeFormatException('QR fields cannot be empty');
  }
  final seats = parts[4].split('-');
  if (seats.any((seat) => !RegExp(r'^[A-Z]+\d+$').hasMatch(seat))) {
    throw const QrCodeFormatException('Invalid seat code');
  }
  return QrTicketData(
    bookingId: parts[1],
    userId: parts[2],
    showtimeId: parts[3],
    seats: seats,
  );
}

String? tryExtractBookingId(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('CINELUXE|')) {
    return parseQrTicket(trimmed).bookingId;
  }

  final match = _bookingIdPattern.firstMatch(trimmed);
  if (match != null) {
    return match.group(0);
  }

  return null;
}

String parseTicketBookingId(String value) {
  final bookingId = tryExtractBookingId(value);
  if (bookingId == null) {
    throw const QrCodeFormatException('Không tìm thấy mã booking hợp lệ');
  }
  return bookingId;
}
