import 'package:json_annotation/json_annotation.dart';

part 'booking_models.g.dart';

enum ApiSeatStatus { available, held, booked, selected }

@JsonSerializable()
class ApiSeat {
  const ApiSeat({
    required this.code,
    required this.row,
    required this.column,
    required this.type,
    required this.status,
  });

  final String code;
  final String row;
  final int column;
  final String type;
  final ApiSeatStatus status;

  factory ApiSeat.fromJson(Map<String, dynamic> json) =>
      _$ApiSeatFromJson(json);
  Map<String, dynamic> toJson() => _$ApiSeatToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SeatMap {
  const SeatMap({required this.showtimeId, required this.seats});

  final String showtimeId;
  final List<ApiSeat> seats;

  factory SeatMap.fromJson(Map<String, dynamic> json) =>
      _$SeatMapFromJson(json);
  Map<String, dynamic> toJson() => _$SeatMapToJson(this);
}

@JsonSerializable()
class HoldResponse {
  const HoldResponse({
    required this.holdId,
    required this.showtimeId,
    required this.seatCodes,
    required this.expiresAt,
  });

  final String holdId;
  final String showtimeId;
  final List<String> seatCodes;
  final DateTime expiresAt;

  factory HoldResponse.fromJson(Map<String, dynamic> json) =>
      _$HoldResponseFromJson(json);
  Map<String, dynamic> toJson() => _$HoldResponseToJson(this);
}

@JsonSerializable()
class FoodCombo {
  const FoodCombo({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.quantity = 0,
    this.imageUrl = '',
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final int quantity;
  final String imageUrl;

  factory FoodCombo.fromJson(Map<String, dynamic> json) =>
      _$FoodComboFromJson(json);
  Map<String, dynamic> toJson() => _$FoodComboToJson(this);
}

@JsonSerializable()
class ComboSelection {
  const ComboSelection({required this.comboId, required this.quantity});

  final String comboId;
  final int quantity;

  factory ComboSelection.fromJson(Map<String, dynamic> json) =>
      _$ComboSelectionFromJson(json);
  Map<String, dynamic> toJson() => _$ComboSelectionToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CreateBookingRequest {
  const CreateBookingRequest({
    required this.holdId,
    required this.combos,
    this.userId,
    this.movieAgeRating,
  });

  final String holdId;
  final List<ComboSelection> combos;
  final String? userId;

  /// Bước 4 — backend re-verify khi "T18": truyền ageRating để backend
  /// biết cần kiểm tra ngày sinh trong profile (Req R7.5, R7.6).
  final String? movieAgeRating;

  factory CreateBookingRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBookingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateBookingRequestToJson(this);
}

@JsonSerializable()
class BookingResponse {
  const BookingResponse({
    required this.bookingId,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.paymentUrl,
    required this.paymentExpiresAt,
  });

  final String bookingId;
  final String status;
  final String paymentStatus;
  final int totalAmount;
  final String paymentUrl;
  final DateTime paymentExpiresAt;

  factory BookingResponse.fromJson(Map<String, dynamic> json) =>
      _$BookingResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BookingResponseToJson(this);
}

@JsonSerializable()
class BookingDetails {
  const BookingDetails({
    required this.bookingId,
    required this.userId,
    required this.showtimeId,
    required this.movieTitle,
    required this.roomName,
    required this.cinemaName,
    required this.showtimeDateTime,
    required this.seatCodes,
    required this.combos,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    this.qrCode,
  });

  final String bookingId;
  final String userId;
  final String showtimeId;
  final String movieTitle;
  final String roomName;
  final String cinemaName;
  final DateTime showtimeDateTime;
  final List<String> seatCodes;
  final List<String> combos;
  final int totalAmount;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;
  final String? qrCode;

  factory BookingDetails.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$BookingDetailsToJson(this);
}

@JsonSerializable()
class BookingQr {
  const BookingQr({
    required this.bookingId,
    required this.qrCode,
    required this.movieTitle,
    required this.showtimeDateTime,
    required this.roomName,
    required this.cinemaName,
    required this.seatCodes,
  });

  final String bookingId;
  final String qrCode;
  final String movieTitle;
  final DateTime showtimeDateTime;
  final String roomName;
  final String cinemaName;
  final List<String> seatCodes;

  factory BookingQr.fromJson(Map<String, dynamic> json) =>
      _$BookingQrFromJson(json);
  Map<String, dynamic> toJson() => _$BookingQrToJson(this);
}

enum ApiPaymentStatus {
  pending,
  processing,
  success,
  failed,
  timeout,
  cancelled,
  refunded,
}

@JsonSerializable()
class PaymentStatusResult {
  const PaymentStatusResult({
    required this.bookingId,
    required this.status,
    required this.paymentStatus,
    this.transactionId,
    this.responseCode,
  });

  final String bookingId;
  final String status;
  final ApiPaymentStatus paymentStatus;
  final String? transactionId;
  final String? responseCode;

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) =>
      _$PaymentStatusResultFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentStatusResultToJson(this);
}

@JsonSerializable()
class CancelBookingResponse {
  const CancelBookingResponse({
    required this.bookingId,
    required this.status,
    required this.refundAmount,
    required this.refundStatus,
  });

  final String bookingId;
  final String status;
  final int refundAmount;
  final String refundStatus;

  factory CancelBookingResponse.fromJson(Map<String, dynamic> json) =>
      _$CancelBookingResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CancelBookingResponseToJson(this);
}

@JsonSerializable()
class ValidationResult {
  const ValidationResult({
    required this.success,
    required this.status,
    required this.message,
    required this.bookingId,
    required this.customerName,
    required this.movieTitle,
    required this.showtimeId,
    required this.showtimeDateTime,
    required this.seatCodes,
    required this.validatedAt,
  });

  final bool success;
  final String status;
  final String message;
  final String bookingId;
  final String customerName;
  final String movieTitle;
  final String showtimeId;
  final DateTime showtimeDateTime;
  final List<String> seatCodes;
  final DateTime validatedAt;

  factory ValidationResult.fromJson(Map<String, dynamic> json) =>
      _$ValidationResultFromJson(json);
  Map<String, dynamic> toJson() => _$ValidationResultToJson(this);
}
