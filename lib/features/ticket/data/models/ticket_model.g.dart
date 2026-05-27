// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketModel _$TicketModelFromJson(Map<String, dynamic> json) => TicketModel(
  id: json['id'] as String,
  movieTitle: json['movie_title'] as String,
  posterUrl: json['poster_url'] as String,
  cinemaName: json['cinema_name'] as String,
  startTime: DateTime.parse(json['start_time'] as String),
  seats: (json['seats'] as List<dynamic>).map((e) => e as String).toList(),
  bookingCode: json['booking_code'] as String,
  totalAmount: (json['totalAmount'] as num).toInt(),
  status: json['status'] as String,
);

Map<String, dynamic> _$TicketModelToJson(TicketModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'movie_title': instance.movieTitle,
      'poster_url': instance.posterUrl,
      'cinema_name': instance.cinemaName,
      'start_time': instance.startTime.toIso8601String(),
      'seats': instance.seats,
      'booking_code': instance.bookingCode,
      'totalAmount': instance.totalAmount,
      'status': instance.status,
    };
