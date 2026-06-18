import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences.g.dart';

/// Notification preferences model for managing user notification categories.
///
/// **Requirements Coverage:**
/// - Requirement 38.2: Preferences with categories (showtimeReminders, promotions, newMovies, bookingUpdates)
/// - Requirement 38.6: Toggle switches for each category with descriptive labels
///
/// Each boolean field represents a notification category:
/// - `showtimeReminders`: 2-hour reminder before showtime
/// - `promotions`: Marketing and promotional notifications
/// - `newMovies`: New movie release announcements
/// - `bookingUpdates`: Booking confirmations and status changes
///
/// Usage:
/// ```dart
/// // From JSON
/// final prefs = NotificationPreferences.fromJson(jsonMap);
///
/// // Update preference
/// final updated = prefs.copyWith(promotions: false);
/// ```
@JsonSerializable()
class NotificationPreferences {
  /// Enable showtime reminder notifications (2 hours before showtime)
  final bool showtimeReminders;

  /// Enable promotional and marketing notifications
  final bool promotions;

  /// Enable new movie release notifications
  final bool newMovies;

  /// Enable booking update notifications (confirmations, changes)
  final bool bookingUpdates;

  const NotificationPreferences({
    required this.showtimeReminders,
    required this.promotions,
    required this.newMovies,
    required this.bookingUpdates,
  });

  /// Creates an instance from JSON map
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  /// Converts instance to JSON map
  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);

  /// Creates a copy with optional field overrides
  NotificationPreferences copyWith({
    bool? showtimeReminders,
    bool? promotions,
    bool? newMovies,
    bool? bookingUpdates,
  }) {
    return NotificationPreferences(
      showtimeReminders: showtimeReminders ?? this.showtimeReminders,
      promotions: promotions ?? this.promotions,
      newMovies: newMovies ?? this.newMovies,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
    );
  }

  /// Default preferences (all enabled)
  static const NotificationPreferences defaults = NotificationPreferences(
    showtimeReminders: true,
    promotions: true,
    newMovies: true,
    bookingUpdates: true,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationPreferences &&
        other.showtimeReminders == showtimeReminders &&
        other.promotions == promotions &&
        other.newMovies == newMovies &&
        other.bookingUpdates == bookingUpdates;
  }

  @override
  int get hashCode {
    return showtimeReminders.hashCode ^
        promotions.hashCode ^
        newMovies.hashCode ^
        bookingUpdates.hashCode;
  }
}
