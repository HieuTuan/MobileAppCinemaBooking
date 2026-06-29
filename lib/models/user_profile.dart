import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

/// User profile model containing account information and membership details.
/// 
/// **Requirements Coverage:**
/// - Requirement 1.3: User profile data (id, email, fullName, avatar, memberRank, points)
/// - Requirement 2.3: Traditional authentication user data
/// 
/// Usage:
/// ```dart
/// // From JSON
/// final profile = UserProfile.fromJson(jsonMap);
/// 
/// // Access user data
/// print('User: ${profile.fullName}, Rank: ${profile.memberRank}');
/// ```
@JsonSerializable()
class UserProfile {
  /// Unique user identifier
  @JsonKey(name: 'userId')
  final String id;
  
  /// User email address
  final String email;
  
  /// User's full name
  final String fullName;
  
  /// Phone number (optional)
  final String? phone;
  
  /// Date of birth (optional, required for T18 movie bookings)
  final DateTime? birthdate;
  
  /// URL to user's avatar image (optional)
  final String? avatarUrl;
  
  /// Membership rank based on points (silver, gold, platinum)
  final String memberRank;
  
  /// Loyalty points earned from bookings (1 point per 10,000 VND)
  final int points;
  
  /// User role in the system (customer, staff, admin)
  final String role;
  
  /// Staff permissions (optional, only for staff/admin users)
  final List<String>? permissions;
  
  /// Account active status
  @JsonKey(name: 'active')
  final bool isActive;
  
  /// Account creation timestamp
  final DateTime createdAt;
  
  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.birthdate,
    this.avatarUrl,
    required this.memberRank,
    required this.points,
    required this.role,
    this.permissions,
    required this.isActive,
    required this.createdAt,
  });
  
  /// Creates an instance from JSON map
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  
  /// Converts instance to JSON map
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
  
  /// Checks if user is a customer
  bool get isCustomer => role == 'customer';
  
  /// Checks if user is staff
  bool get isStaff => role == 'staff';
  
  /// Checks if user is admin
  bool get isAdmin => role == 'admin';
  
  /// Checks if user is at least 18 years old (for T18 movie bookings)
  bool get isAdult {
    if (birthdate == null) return false;
    final age = DateTime.now().difference(birthdate!).inDays ~/ 365;
    return age >= 18;
  }
  
  /// Returns user's age, or null if birthdate is not set
  int? get age {
    if (birthdate == null) return null;
    return DateTime.now().difference(birthdate!).inDays ~/ 365;
  }
}
