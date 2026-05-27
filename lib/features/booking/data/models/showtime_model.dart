import 'package:json_annotation/json_annotation.dart';

part 'showtime_model.g.dart';

@JsonSerializable()
class ShowtimeModel {
  final String id;
  @JsonKey(name: 'movie_id')
  final String movieId;
  @JsonKey(name: 'cinema_name')
  final String cinemaName;
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  final String format; // 2D, 3D, IMAX
  final int price;

  ShowtimeModel({
    required this.id,
    required this.movieId,
    required this.cinemaName,
    required this.startTime,
    required this.format,
    required this.price,
  });

  factory ShowtimeModel.fromJson(Map<String, dynamic> json) => _$ShowtimeModelFromJson(json);
  Map<String, dynamic> toJson() => _$ShowtimeModelToJson(this);
}
