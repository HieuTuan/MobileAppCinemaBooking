// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MovieModel _$MovieModelFromJson(Map<String, dynamic> json) => MovieModel(
  id: json['id'] as String,
  title: json['title'] as String,
  originalTitle: json['original_title'] as String?,
  description: json['description'] as String,
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  genre: (json['genre'] as List<dynamic>).map((e) => e as String).toList(),
  ageRating: json['age_rating'] as String,
  posterUrl: json['poster_url'] as String,
  trailerYoutubeId: json['trailer_youtube_id'] as String?,
  imdbRating: (json['imdb_rating'] as num?)?.toDouble(),
  status: json['status'] as String,
  releaseDate: json['release_date'] as String,
);

Map<String, dynamic> _$MovieModelToJson(MovieModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'original_title': instance.originalTitle,
      'description': instance.description,
      'duration_minutes': instance.durationMinutes,
      'genre': instance.genre,
      'age_rating': instance.ageRating,
      'poster_url': instance.posterUrl,
      'trailer_youtube_id': instance.trailerYoutubeId,
      'imdb_rating': instance.imdbRating,
      'status': instance.status,
      'release_date': instance.releaseDate,
    };
