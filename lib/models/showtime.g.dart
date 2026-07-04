// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'showtime.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Showtime _$ShowtimeFromJson(Map<String, dynamic> json) => Showtime(
  id: json['id'] as String,
  movieId: json['movieId'] as String,
  roomId: json['roomId'] as String,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  basePrice: (json['basePrice'] as num).toInt(),
  vipSeatPrice: (json['vipSeatPrice'] as num?)?.toInt(),
  coupleSeatPrice: (json['coupleSeatPrice'] as num?)?.toInt(),
  status: json['status'] as String,
  roomName: json['roomName'] as String,
  cinemaName: json['cinemaName'] as String,
  cinemaAddress: json['cinemaAddress'] as String,
);

Map<String, dynamic> _$ShowtimeToJson(Showtime instance) => <String, dynamic>{
  'id': instance.id,
  'movieId': instance.movieId,
  'roomId': instance.roomId,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime.toIso8601String(),
  'basePrice': instance.basePrice,
  'vipSeatPrice': instance.vipSeatPrice,
  'coupleSeatPrice': instance.coupleSeatPrice,
  'status': instance.status,
  'roomName': instance.roomName,
  'cinemaName': instance.cinemaName,
  'cinemaAddress': instance.cinemaAddress,
};
