// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateReviewRequest _$CreateReviewRequestFromJson(Map<String, dynamic> json) =>
    CreateReviewRequest(
      userId: json['userId'] as String,
      movieId: json['movieId'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String,
    );

Map<String, dynamic> _$CreateReviewRequestToJson(
  CreateReviewRequest instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'movieId': instance.movieId,
  'rating': instance.rating,
  'comment': instance.comment,
};

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
  id: json['id'] as String,
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  movieId: json['movieId'] as String,
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String,
  isVerified: json['isVerified'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'userName': instance.userName,
  'movieId': instance.movieId,
  'rating': instance.rating,
  'comment': instance.comment,
  'isVerified': instance.isVerified,
  'createdAt': instance.createdAt.toIso8601String(),
};
