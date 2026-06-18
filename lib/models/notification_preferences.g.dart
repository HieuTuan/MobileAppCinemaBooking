// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPreferences _$NotificationPreferencesFromJson(
  Map<String, dynamic> json,
) => NotificationPreferences(
  showtimeReminders: json['showtimeReminders'] as bool,
  promotions: json['promotions'] as bool,
  newMovies: json['newMovies'] as bool,
  bookingUpdates: json['bookingUpdates'] as bool,
);

Map<String, dynamic> _$NotificationPreferencesToJson(
  NotificationPreferences instance,
) => <String, dynamic>{
  'showtimeReminders': instance.showtimeReminders,
  'promotions': instance.promotions,
  'newMovies': instance.newMovies,
  'bookingUpdates': instance.bookingUpdates,
};
