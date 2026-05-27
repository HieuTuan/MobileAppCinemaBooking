import 'package:json_annotation/json_annotation.dart';

part 'movie_model.g.dart';

@JsonSerializable()
class MovieModel {
  final String id;
  final String title;
  @JsonKey(name: 'original_title')
  final String? originalTitle;
  final String description;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  final List<String> genre;
  @JsonKey(name: 'age_rating')
  final String ageRating;
  @JsonKey(name: 'poster_url')
  final String posterUrl;
  @JsonKey(name: 'trailer_youtube_id')
  final String? trailerYoutubeId;
  @JsonKey(name: 'imdb_rating')
  final double? imdbRating;
  final String status;
  @JsonKey(name: 'release_date')
  final String releaseDate;

  MovieModel({
    required this.id,
    required this.title,
    this.originalTitle,
    required this.description,
    required this.durationMinutes,
    required this.genre,
    required this.ageRating,
    required this.posterUrl,
    this.trailerYoutubeId,
    this.imdbRating,
    required this.status,
    required this.releaseDate,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) => _$MovieModelFromJson(json);
  Map<String, dynamic> toJson() => _$MovieModelToJson(this);
}
