// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedResponse<T> _$PaginatedResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => PaginatedResponse<T>(
  data: (json['data'] as List<dynamic>).map(fromJsonT).toList(),
  page: (json['page'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
  totalItems: (json['totalItems'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
  hasNext: json['hasNext'] as bool,
  hasPrevious: json['hasPrevious'] as bool,
);

Map<String, dynamic> _$PaginatedResponseToJson<T>(
  PaginatedResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'data': instance.data.map(toJsonT).toList(),
  'page': instance.page,
  'pageSize': instance.pageSize,
  'totalItems': instance.totalItems,
  'totalPages': instance.totalPages,
  'hasNext': instance.hasNext,
  'hasPrevious': instance.hasPrevious,
};
