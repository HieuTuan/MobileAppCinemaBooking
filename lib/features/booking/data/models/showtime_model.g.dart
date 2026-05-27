// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'showtime_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShowtimeModel _$ShowtimeModelFromJson(Map<String, dynamic> json) =>
    ShowtimeModel(
      id: json['id'] as String,
      movieId: json['movie_id'] as String,
      cinemaName: json['cinema_name'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      format: json['format'] as String,
      price: (json['price'] as num).toInt(),
    );

Map<String, dynamic> _$ShowtimeModelToJson(ShowtimeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'movie_id': instance.movieId,
      'cinema_name': instance.cinemaName,
      'start_time': instance.startTime.toIso8601String(),
      'format': instance.format,
      'price': instance.price,
    };
