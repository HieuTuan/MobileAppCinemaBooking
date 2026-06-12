import 'package:json_annotation/json_annotation.dart';

part 'showtime.g.dart';

/// Showtime model representing a specific screening of a movie.
/// 
/// **Requirements Coverage:**
/// - Requirement 3.1: Showtime data for movie screenings
/// - Requirement 3.7: Complete showtime information including movie, room, timing, and pricing
/// 
/// Usage:
/// ```dart
/// // From JSON
/// final showtime = Showtime.fromJson(jsonMap);
/// 
/// // Access showtime data
/// print('${showtime.movieId} at ${showtime.startTime}');
/// print('Location: ${showtime.cinemaName} - ${showtime.roomName}');
/// ```
@JsonSerializable()
class Showtime {
  /// Unique showtime identifier
  final String id;
  
  /// ID of the movie being shown
  final String movieId;
  
  /// ID of the screening room
  final String roomId;
  
  /// Start time of the screening
  final DateTime startTime;
  
  /// End time of the screening (includes cleanup buffer)
  final DateTime endTime;
  
  /// Base ticket price in VND
  final int basePrice;
  
  /// Showtime status (scheduled, cancelled)
  final String status;
  
  /// Name of the screening room
  final String roomName;
  
  /// Name of the cinema/theater
  final String cinemaName;
  
  /// Full address of the cinema
  final String cinemaAddress;
  
  Showtime({
    required this.id,
    required this.movieId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.basePrice,
    required this.status,
    required this.roomName,
    required this.cinemaName,
    required this.cinemaAddress,
  });
  
  /// Creates an instance from JSON map
  factory Showtime.fromJson(Map<String, dynamic> json) =>
      _$ShowtimeFromJson(json);
  
  /// Converts instance to JSON map
  Map<String, dynamic> toJson() => _$ShowtimeToJson(this);
  
  /// Checks if showtime is scheduled
  bool get isScheduled => status == 'scheduled';
  
  /// Checks if showtime is cancelled
  bool get isCancelled => status == 'cancelled';
  
  /// Checks if showtime has already started
  bool get hasStarted => DateTime.now().isAfter(startTime);
  
  /// Checks if showtime has ended
  bool get hasEnded => DateTime.now().isAfter(endTime);
  
  /// Checks if showtime is currently playing
  bool get isPlaying {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
  
  /// Returns duration of the screening in minutes (including cleanup)
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }
  
  /// Returns time until showtime starts (null if already started)
  Duration? get timeUntilStart {
    if (hasStarted) return null;
    return startTime.difference(DateTime.now());
  }
  
  /// Returns formatted start time (e.g., "14:30")
  String get formattedStartTime {
    return '${startTime.hour.toString().padLeft(2, '0')}:'
        '${startTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// Returns formatted date (e.g., "Mon, Dec 25")
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final dayName = days[startTime.weekday - 1];
    final month = months[startTime.month - 1];
    final day = startTime.day;
    
    return '$dayName, $month $day';
  }
  
  /// Returns formatted price in VND (e.g., "150,000 VND")
  String get formattedPrice {
    return '${basePrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} VND';
  }
  
  /// Returns full location string
  String get fullLocation => '$cinemaName - $roomName';
}
