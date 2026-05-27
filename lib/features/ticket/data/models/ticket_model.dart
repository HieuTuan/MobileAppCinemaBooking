import 'package:json_annotation/json_annotation.dart';

part 'ticket_model.g.dart';

@JsonSerializable()
class TicketModel {
  final String id;
  @JsonKey(name: 'movie_title')
  final String movieTitle;
  @JsonKey(name: 'poster_url')
  final String posterUrl;
  @JsonKey(name: 'cinema_name')
  final String cinemaName;
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  final List<String> seats;
  @JsonKey(name: 'booking_code')
  final String bookingCode;
  final int totalAmount;
  final String status; // UPCOMING, USED, CANCELLED

  TicketModel({
    required this.id,
    required this.movieTitle,
    required this.posterUrl,
    required this.cinemaName,
    required this.startTime,
    required this.seats,
    required this.bookingCode,
    required this.totalAmount,
    required this.status,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) => _$TicketModelFromJson(json);
  Map<String, dynamic> toJson() => _$TicketModelToJson(this);
}
