// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) => ApiError(
  code: json['code'] as String,
  message: json['message'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  path: json['path'] as String,
  fieldErrors: json['fieldErrors'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ApiErrorToJson(ApiError instance) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'timestamp': instance.timestamp.toIso8601String(),
  'path': instance.path,
  'fieldErrors': instance.fieldErrors,
};
