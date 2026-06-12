// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExampleModel _$ExampleModelFromJson(Map<String, dynamic> json) => ExampleModel(
  id: json['id'] as String,
  name: json['name'] as String,
  optionalValue: (json['optionalValue'] as num?)?.toInt(),
);

Map<String, dynamic> _$ExampleModelToJson(ExampleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'optionalValue': instance.optionalValue,
    };
