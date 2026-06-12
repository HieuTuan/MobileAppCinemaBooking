import 'package:json_annotation/json_annotation.dart';

part 'paginated_response.g.dart';

/// Generic paginated response wrapper for list endpoints.
/// 
/// **Requirements Coverage:**
/// - Requirement 3.8: Pagination support for movie and review endpoints
/// 
/// Usage:
/// ```dart
/// // From JSON
/// final response = PaginatedResponse<Movie>.fromJson(
///   jsonMap,
///   (json) => Movie.fromJson(json as Map<String, dynamic>),
/// );
/// 
/// // Access paginated data
/// print('Page ${response.page} of ${response.totalPages}');
/// for (var movie in response.data) {
///   print(movie.title);
/// }
/// ```
@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponse<T> {
  /// List of items for current page
  final List<T> data;
  
  /// Current page number (1-indexed)
  final int page;
  
  /// Number of items per page
  final int pageSize;
  
  /// Total number of items across all pages
  final int totalItems;
  
  /// Total number of pages
  final int totalPages;
  
  /// Whether there is a next page
  final bool hasNext;
  
  /// Whether there is a previous page
  final bool hasPrevious;
  
  PaginatedResponse({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });
  
  /// Creates an instance from JSON map with custom deserializer for items
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);
  
  /// Converts instance to JSON map with custom serializer for items
  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$PaginatedResponseToJson(this, toJsonT);
  
  /// Returns true if this is the first page
  bool get isFirstPage => page == 1;
  
  /// Returns true if this is the last page
  bool get isLastPage => page == totalPages;
  
  /// Returns the starting item number for this page (1-indexed)
  int get startItem => (page - 1) * pageSize + 1;
  
  /// Returns the ending item number for this page (1-indexed)
  int get endItem => startItem + data.length - 1;
  
  /// Returns a display string like "Showing 1-20 of 100"
  String get displayRange => 'Showing $startItem-$endItem of $totalItems';
}
