// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiSeat _$ApiSeatFromJson(Map<String, dynamic> json) => ApiSeat(
  code: json['code'] as String,
  row: json['row'] as String,
  column: (json['column'] as num).toInt(),
  type: json['type'] as String,
  status: $enumDecode(_$ApiSeatStatusEnumMap, json['status']),
);

Map<String, dynamic> _$ApiSeatToJson(ApiSeat instance) => <String, dynamic>{
  'code': instance.code,
  'row': instance.row,
  'column': instance.column,
  'type': instance.type,
  'status': _$ApiSeatStatusEnumMap[instance.status]!,
};

const _$ApiSeatStatusEnumMap = {
  ApiSeatStatus.available: 'available',
  ApiSeatStatus.held: 'held',
  ApiSeatStatus.booked: 'booked',
  ApiSeatStatus.selected: 'selected',
};

SeatMap _$SeatMapFromJson(Map<String, dynamic> json) => SeatMap(
  showtimeId: json['showtimeId'] as String,
  seats: (json['seats'] as List<dynamic>)
      .map((e) => ApiSeat.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SeatMapToJson(SeatMap instance) => <String, dynamic>{
  'showtimeId': instance.showtimeId,
  'seats': instance.seats.map((e) => e.toJson()).toList(),
};

HoldResponse _$HoldResponseFromJson(Map<String, dynamic> json) => HoldResponse(
  holdId: json['holdId'] as String,
  showtimeId: json['showtimeId'] as String,
  seatCodes: (json['seatCodes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  expiresAt: DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$HoldResponseToJson(HoldResponse instance) =>
    <String, dynamic>{
      'holdId': instance.holdId,
      'showtimeId': instance.showtimeId,
      'seatCodes': instance.seatCodes,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

FoodCombo _$FoodComboFromJson(Map<String, dynamic> json) => FoodCombo(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toInt(),
  quantity: (json['quantity'] as num?)?.toInt() ?? 0,
  imageUrl: json['imageUrl'] as String? ?? '',
);

Map<String, dynamic> _$FoodComboToJson(FoodCombo instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'quantity': instance.quantity,
  'imageUrl': instance.imageUrl,
};

ComboSelection _$ComboSelectionFromJson(Map<String, dynamic> json) =>
    ComboSelection(
      comboId: json['comboId'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$ComboSelectionToJson(ComboSelection instance) =>
    <String, dynamic>{
      'comboId': instance.comboId,
      'quantity': instance.quantity,
    };

CreateBookingRequest _$CreateBookingRequestFromJson(
  Map<String, dynamic> json,
) => CreateBookingRequest(
  holdId: json['holdId'] as String,
  combos: (json['combos'] as List<dynamic>)
      .map((e) => ComboSelection.fromJson(e as Map<String, dynamic>))
      .toList(),
  userId: json['userId'] as String?,
  movieAgeRating: json['movieAgeRating'] as String?,
);

Map<String, dynamic> _$CreateBookingRequestToJson(
  CreateBookingRequest instance,
) => <String, dynamic>{
  'holdId': instance.holdId,
  'combos': instance.combos.map((e) => e.toJson()).toList(),
  'userId': ?instance.userId,
  'movieAgeRating': ?instance.movieAgeRating,
};

BookingResponse _$BookingResponseFromJson(Map<String, dynamic> json) =>
    BookingResponse(
      bookingId: json['bookingId'] as String,
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      totalAmount: (json['totalAmount'] as num).toInt(),
      paymentUrl: json['paymentUrl'] as String,
      paymentExpiresAt: DateTime.parse(json['paymentExpiresAt'] as String),
    );

Map<String, dynamic> _$BookingResponseToJson(BookingResponse instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'status': instance.status,
      'paymentStatus': instance.paymentStatus,
      'totalAmount': instance.totalAmount,
      'paymentUrl': instance.paymentUrl,
      'paymentExpiresAt': instance.paymentExpiresAt.toIso8601String(),
    };

BookingDetails _$BookingDetailsFromJson(Map<String, dynamic> json) =>
    BookingDetails(
      bookingId: json['bookingId'] as String,
      userId: json['userId'] as String,
      showtimeId: json['showtimeId'] as String,
      movieTitle: json['movieTitle'] as String,
      roomName: json['roomName'] as String,
      cinemaName: json['cinemaName'] as String,
      showtimeDateTime: DateTime.parse(json['showtimeDateTime'] as String),
      seatCodes: (json['seatCodes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      combos: (json['combos'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      totalAmount: (json['totalAmount'] as num).toInt(),
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      qrCode: json['qrCode'] as String?,
      posterUrl: json['posterUrl'] as String?,
    );

Map<String, dynamic> _$BookingDetailsToJson(BookingDetails instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'userId': instance.userId,
      'showtimeId': instance.showtimeId,
      'movieTitle': instance.movieTitle,
      'roomName': instance.roomName,
      'cinemaName': instance.cinemaName,
      'showtimeDateTime': instance.showtimeDateTime.toIso8601String(),
      'seatCodes': instance.seatCodes,
      'combos': instance.combos,
      'totalAmount': instance.totalAmount,
      'status': instance.status,
      'paymentStatus': instance.paymentStatus,
      'createdAt': instance.createdAt.toIso8601String(),
      'qrCode': instance.qrCode,
      'posterUrl': instance.posterUrl,
    };

BookingQr _$BookingQrFromJson(Map<String, dynamic> json) => BookingQr(
  bookingId: json['bookingId'] as String,
  qrCode: json['qrCode'] as String,
  movieTitle: json['movieTitle'] as String,
  showtimeDateTime: DateTime.parse(json['showtimeDateTime'] as String),
  roomName: json['roomName'] as String,
  cinemaName: json['cinemaName'] as String,
  seatCodes: (json['seatCodes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  qrCodeUrl: json['qrCodeUrl'] as String?,
);

Map<String, dynamic> _$BookingQrToJson(BookingQr instance) => <String, dynamic>{
  'bookingId': instance.bookingId,
  'qrCode': instance.qrCode,
  'movieTitle': instance.movieTitle,
  'showtimeDateTime': instance.showtimeDateTime.toIso8601String(),
  'roomName': instance.roomName,
  'cinemaName': instance.cinemaName,
  'seatCodes': instance.seatCodes,
  'qrCodeUrl': instance.qrCodeUrl,
};

PaymentStatusResult _$PaymentStatusResultFromJson(Map<String, dynamic> json) =>
    PaymentStatusResult(
      bookingId: json['bookingId'] as String,
      status: json['status'] as String,
      paymentStatus: $enumDecode(
        _$ApiPaymentStatusEnumMap,
        json['paymentStatus'],
      ),
      transactionId: json['transactionId'] as String?,
      responseCode: json['responseCode'] as String?,
    );

Map<String, dynamic> _$PaymentStatusResultToJson(
  PaymentStatusResult instance,
) => <String, dynamic>{
  'bookingId': instance.bookingId,
  'status': instance.status,
  'paymentStatus': _$ApiPaymentStatusEnumMap[instance.paymentStatus]!,
  'transactionId': instance.transactionId,
  'responseCode': instance.responseCode,
};

const _$ApiPaymentStatusEnumMap = {
  ApiPaymentStatus.pending: 'pending',
  ApiPaymentStatus.processing: 'processing',
  ApiPaymentStatus.success: 'success',
  ApiPaymentStatus.failed: 'failed',
  ApiPaymentStatus.timeout: 'timeout',
  ApiPaymentStatus.cancelled: 'cancelled',
  ApiPaymentStatus.refunded: 'refunded',
};

CancelBookingResponse _$CancelBookingResponseFromJson(
  Map<String, dynamic> json,
) => CancelBookingResponse(
  bookingId: json['bookingId'] as String,
  status: json['status'] as String,
  refundAmount: (json['refundAmount'] as num).toInt(),
  refundStatus: json['refundStatus'] as String,
);

Map<String, dynamic> _$CancelBookingResponseToJson(
  CancelBookingResponse instance,
) => <String, dynamic>{
  'bookingId': instance.bookingId,
  'status': instance.status,
  'refundAmount': instance.refundAmount,
  'refundStatus': instance.refundStatus,
};

ValidationResult _$ValidationResultFromJson(Map<String, dynamic> json) =>
    ValidationResult(
      success: json['success'] as bool,
      status: json['status'] as String,
      message: json['message'] as String,
      bookingId: json['bookingId'] as String,
      customerName: json['customerName'] as String,
      movieTitle: json['movieTitle'] as String,
      showtimeId: json['showtimeId'] as String,
      showtimeDateTime: DateTime.parse(json['showtimeDateTime'] as String),
      seatCodes: (json['seatCodes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      validatedAt: DateTime.parse(json['validatedAt'] as String),
    );

Map<String, dynamic> _$ValidationResultToJson(ValidationResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'status': instance.status,
      'message': instance.message,
      'bookingId': instance.bookingId,
      'customerName': instance.customerName,
      'movieTitle': instance.movieTitle,
      'showtimeId': instance.showtimeId,
      'showtimeDateTime': instance.showtimeDateTime.toIso8601String(),
      'seatCodes': instance.seatCodes,
      'validatedAt': instance.validatedAt.toIso8601String(),
    };
