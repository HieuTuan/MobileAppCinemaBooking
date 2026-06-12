/// Data model for real-time seat status updates received via WebSocket
class SeatUpdate {
  final String seatCode;
  final SeatStatus status;
  final String? userId;
  final DateTime? expiresAt;

  const SeatUpdate({
    required this.seatCode,
    required this.status,
    this.userId,
    this.expiresAt,
  });

  factory SeatUpdate.fromJson(Map<String, dynamic> json) {
    return SeatUpdate(
      seatCode: json['seatCode'] as String,
      status: _parseSeatStatus(json['status'] as String),
      userId: json['userId'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seatCode': seatCode,
      'status': status.name,
      if (userId != null) 'userId': userId,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    };
  }

  static SeatStatus _parseSeatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return SeatStatus.available;
      case 'held':
        return SeatStatus.held;
      case 'booked':
        return SeatStatus.booked;
      case 'selected':
        return SeatStatus.selected;
      default:
        return SeatStatus.available;
    }
  }

  @override
  String toString() {
    return 'SeatUpdate(seatCode: $seatCode, status: $status, userId: $userId, expiresAt: $expiresAt)';
  }
}

/// Seat status enumeration matching backend states
enum SeatStatus {
  available,  // Seat can be selected
  held,       // Temporarily reserved (10-minute hold)
  booked,     // Confirmed booking
  selected,   // Current user's selection (local state only)
}
