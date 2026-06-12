import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

/// Review model representing a customer's movie review.
/// 
/// **Requirements Coverage:**
/// - Requirement 3.1: Movie reviews with verification status
/// - Requirement 3.7: Complete review data including user info, rating, and verification
/// 
/// Usage:
/// ```dart
/// // From JSON
/// final review = Review.fromJson(jsonMap);
/// 
/// // Access review data
/// print('${review.userName}: ${review.rating}/5');
/// if (review.isVerified) {
///   print('Verified viewer');
/// }
/// ```
@JsonSerializable()
class Review {
  /// Unique review identifier
  final String id;
  
  /// ID of the user who wrote the review
  final String userId;
  
  /// Name of the user who wrote the review
  final String userName;
  
  /// ID of the movie being reviewed
  final String movieId;
  
  /// Rating from 1 to 5 stars
  final int rating;
  
  /// Review comment text
  final String comment;
  
  /// Whether the review is verified (user has watched the movie)
  final bool isVerified;
  
  /// Timestamp when the review was created
  final DateTime createdAt;
  
  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.movieId,
    required this.rating,
    required this.comment,
    required this.isVerified,
    required this.createdAt,
  });
  
  /// Creates an instance from JSON map
  factory Review.fromJson(Map<String, dynamic> json) =>
      _$ReviewFromJson(json);
  
  /// Converts instance to JSON map
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
  
  /// Checks if rating is positive (4 or 5 stars)
  bool get isPositive => rating >= 4;
  
  /// Checks if rating is negative (1 or 2 stars)
  bool get isNegative => rating <= 2;
  
  /// Checks if rating is neutral (3 stars)
  bool get isNeutral => rating == 3;
  
  /// Returns star emoji representation (e.g., "⭐⭐⭐⭐⭐")
  String get starEmojis => '⭐' * rating;
  
  /// Returns formatted date (e.g., "Dec 25, 2023")
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = months[createdAt.month - 1];
    final day = createdAt.day;
    final year = createdAt.year;
    
    return '$month $day, $year';
  }
  
  /// Returns relative time (e.g., "2 days ago", "1 week ago")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Returns truncated comment (max length with ellipsis)
  String truncatedComment(int maxLength) {
    if (comment.length <= maxLength) return comment;
    return '${comment.substring(0, maxLength)}...';
  }
}
