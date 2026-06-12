// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String,
  phone: json['phone'] as String?,
  birthdate: json['birthdate'] == null
      ? null
      : DateTime.parse(json['birthdate'] as String),
  avatarUrl: json['avatarUrl'] as String?,
  memberRank: json['memberRank'] as String,
  points: (json['points'] as num).toInt(),
  role: json['role'] as String,
  permissions: (json['permissions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'fullName': instance.fullName,
      'phone': instance.phone,
      'birthdate': instance.birthdate?.toIso8601String(),
      'avatarUrl': instance.avatarUrl,
      'memberRank': instance.memberRank,
      'points': instance.points,
      'role': instance.role,
      'permissions': instance.permissions,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };
