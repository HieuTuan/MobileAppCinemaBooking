import 'package:json_annotation/json_annotation.dart';

// This file is auto-generated. Run 'flutter pub run build_runner build' to regenerate.
part 'example_model.g.dart';

/// Example model demonstrating JSON serialization configuration.
/// 
/// This serves as a reference for implementing other API models with json_serializable.
/// 
/// Usage:
/// ```dart
/// // From JSON
/// final model = ExampleModel.fromJson(jsonMap);
/// 
/// // To JSON
/// final jsonMap = model.toJson();
/// ```
@JsonSerializable()
class ExampleModel {
  final String id;
  final String name;
  final int? optionalValue;
  
  ExampleModel({
    required this.id,
    required this.name,
    this.optionalValue,
  });
  
  /// Creates an instance from JSON map
  factory ExampleModel.fromJson(Map<String, dynamic> json) =>
      _$ExampleModelFromJson(json);
  
  /// Converts instance to JSON map
  Map<String, dynamic> toJson() => _$ExampleModelToJson(this);
}
