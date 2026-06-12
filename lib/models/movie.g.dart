// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Movie _$MovieFromJson(Map<String, dynamic> json) => Movie(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  genres: (json['genres'] as List<dynamic>).map((e) => e as String).toList(),
  durationMinutes: (json['durationMinutes'] as num).toInt(),
  director: json['director'] as String,
  cast: (json['cast'] as List<dynamic>).map((e) => e as String).toList(),
  posterUrl: json['posterUrl'] as String,
  trailerUrl: json['trailerUrl'] as String,
  rating: (json['rating'] as num).toDouble(),
  ageRating: json['ageRating'] as String,
  releaseDate: DateTime.parse(json['releaseDate'] as String),
  status: json['status'] as String,
);

Map<String, dynamic> _$MovieToJson(Movie instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'genres': instance.genres,
  'durationMinutes': instance.durationMinutes,
  'director': instance.director,
  'cast': instance.cast,
  'posterUrl': instance.posterUrl,
  'trailerUrl': instance.trailerUrl,
  'rating': instance.rating,
  'ageRating': instance.ageRating,
  'releaseDate': instance.releaseDate.toIso8601String(),
  'status': instance.status,
};
