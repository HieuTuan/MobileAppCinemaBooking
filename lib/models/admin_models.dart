// Admin dashboard models — plain Dart, no code generation.
//
// Requirements: 24.1, 24.2, 24.3, 24.4, 25.1, 25.2, 25.3, 25.4, 25.5

class ShowtimeOccupancy {
  const ShowtimeOccupancy({
    required this.showtimeId,
    required this.movieTitle,
    required this.startTime,
    required this.roomName,
    required this.totalSeats,
    required this.bookedSeats,
    required this.occupancyRate,
  });

  final String showtimeId;
  final String movieTitle;
  final DateTime startTime;
  final String roomName;
  final int totalSeats;
  final int bookedSeats;
  final double occupancyRate;

  factory ShowtimeOccupancy.fromJson(Map<String, dynamic> json) {
    return ShowtimeOccupancy(
      showtimeId: json['showtimeId'] as String,
      movieTitle: json['movieTitle'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      roomName: json['roomName'] as String,
      totalSeats: (json['totalSeats'] as num).toInt(),
      bookedSeats: (json['bookedSeats'] as num).toInt(),
      occupancyRate: (json['occupancyRate'] as num).toDouble(),
    );
  }
}

class MovieSales {
  const MovieSales({
    required this.movieId,
    required this.title,
    required this.ticketsSold,
    required this.revenue,
  });

  final String movieId;
  final String title;
  final int ticketsSold;
  final int revenue;

  factory MovieSales.fromJson(Map<String, dynamic> json) {
    return MovieSales(
      movieId: json['movieId'] as String,
      title: json['title'] as String,
      ticketsSold: (json['ticketsSold'] as num).toInt(),
      revenue: (json['revenue'] as num).toInt(),
    );
  }
}

class RecentBooking {
  const RecentBooking({
    required this.bookingId,
    required this.customerName,
    required this.movieTitle,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  final String bookingId;
  final String customerName;
  final String movieTitle;
  final int totalAmount;
  final String status;
  final DateTime createdAt;

  factory RecentBooking.fromJson(Map<String, dynamic> json) {
    return RecentBooking(
      bookingId: json['bookingId'] as String,
      customerName: json['customerName'] as String,
      movieTitle: json['movieTitle'] as String,
      totalAmount: (json['totalAmount'] as num).toInt(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.todayRevenue,
    required this.todayBookings,
    required this.activeUsers,
    required this.concurrentUsers,
    required this.upcomingShowtimes,
    required this.topMovies,
    required this.recentBookings,
  });

  final int todayRevenue;
  final int todayBookings;
  final int activeUsers;
  final int concurrentUsers;
  final List<ShowtimeOccupancy> upcomingShowtimes;
  final List<MovieSales> topMovies;
  final List<RecentBooking> recentBookings;

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      todayRevenue: (json['todayRevenue'] as num).toInt(),
      todayBookings: (json['todayBookings'] as num).toInt(),
      activeUsers: (json['activeUsers'] as num).toInt(),
      concurrentUsers: (json['concurrentUsers'] as num).toInt(),
      upcomingShowtimes: (json['upcomingShowtimes'] as List<dynamic>)
          .map((e) => ShowtimeOccupancy.fromJson(e as Map<String, dynamic>))
          .toList(),
      topMovies: (json['topMovies'] as List<dynamic>)
          .map((e) => MovieSales.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentBookings: (json['recentBookings'] as List<dynamic>)
          .map((e) => RecentBooking.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ============================================================================
// Revenue Report Models — Requirements 24.1, 24.2, 24.3, 24.4
// ============================================================================

class RevenueByPaymentMethod {
  const RevenueByPaymentMethod({
    required this.method,
    required this.amount,
    required this.count,
  });

  /// Payment method identifier, e.g. "vnpay", "cash", "momo"
  final String method;
  final int amount;
  final int count;

  factory RevenueByPaymentMethod.fromJson(Map<String, dynamic> json) {
    return RevenueByPaymentMethod(
      method: json['method'] as String,
      amount: (json['amount'] as num).toInt(),
      count: (json['count'] as num).toInt(),
    );
  }
}

class DailyRevenue {
  const DailyRevenue({
    required this.date,
    required this.revenue,
    required this.bookings,
  });

  final DateTime date;
  final int revenue;
  final int bookings;

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: DateTime.parse(json['date'] as String),
      revenue: (json['revenue'] as num).toInt(),
      bookings: (json['bookings'] as num).toInt(),
    );
  }
}

class RevenueReport {
  const RevenueReport({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalBookings,
    required this.averageBookingValue,
    required this.byPaymentMethod,
    required this.dailySeries,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int totalRevenue;
  final int totalBookings;

  /// totalRevenue ~/ totalBookings, or 0 if totalBookings == 0
  final int averageBookingValue;
  final List<RevenueByPaymentMethod> byPaymentMethod;
  final List<DailyRevenue> dailySeries;

  factory RevenueReport.fromJson(Map<String, dynamic> json) {
    final totalRevenue = (json['totalRevenue'] as num).toInt();
    final totalBookings = (json['totalBookings'] as num).toInt();
    return RevenueReport(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalRevenue: totalRevenue,
      totalBookings: totalBookings,
      averageBookingValue: json.containsKey('averageBookingValue')
          ? (json['averageBookingValue'] as num).toInt()
          : (totalBookings > 0 ? totalRevenue ~/ totalBookings : 0),
      byPaymentMethod: (json['byPaymentMethod'] as List<dynamic>)
          .map(
            (e) => RevenueByPaymentMethod.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      dailySeries: (json['dailySeries'] as List<dynamic>)
          .map((e) => DailyRevenue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ============================================================================
// Booking Report Models — Requirements 24.5, 24.6, 24.7, 24.8, 24.9
// ============================================================================

class BookingStats {
  const BookingStats({
    required this.total,
    required this.confirmed,
    required this.cancelled,
    required this.refunded,
  });

  final int total;

  /// Count of bookings with "active" status
  final int confirmed;
  final int cancelled;
  final int refunded;

  factory BookingStats.fromJson(Map<String, dynamic> json) {
    return BookingStats(
      total: (json['total'] as num).toInt(),
      confirmed: (json['confirmed'] as num).toInt(),
      cancelled: (json['cancelled'] as num).toInt(),
      refunded: (json['refunded'] as num).toInt(),
    );
  }
}

class MovieRanking {
  const MovieRanking({
    required this.rank,
    required this.movieId,
    required this.title,
    required this.ticketsSold,
    required this.revenue,
  });

  final int rank;
  final String movieId;
  final String title;
  final int ticketsSold;
  final int revenue;

  factory MovieRanking.fromJson(Map<String, dynamic> json) {
    return MovieRanking(
      rank: (json['rank'] as num).toInt(),
      movieId: json['movieId'] as String,
      title: json['title'] as String,
      ticketsSold: (json['ticketsSold'] as num).toInt(),
      revenue: (json['revenue'] as num).toInt(),
    );
  }
}

class TheaterOccupancy {
  const TheaterOccupancy({
    required this.theaterId,
    required this.theaterName,
    required this.totalSeats,
    required this.bookedSeats,
    required this.occupancyRate,
  });

  final String theaterId;
  final String theaterName;
  final int totalSeats;
  final int bookedSeats;

  /// Occupancy rate in range 0.0–1.0
  final double occupancyRate;

  factory TheaterOccupancy.fromJson(Map<String, dynamic> json) {
    return TheaterOccupancy(
      theaterId: json['theaterId'] as String,
      theaterName: json['theaterName'] as String,
      totalSeats: (json['totalSeats'] as num).toInt(),
      bookedSeats: (json['bookedSeats'] as num).toInt(),
      occupancyRate: (json['occupancyRate'] as num).toDouble(),
    );
  }
}

class BookingReport {
  const BookingReport({
    required this.startDate,
    required this.endDate,
    required this.stats,
    required this.movieRankings,
    required this.theaterOccupancy,
  });

  final DateTime startDate;
  final DateTime endDate;
  final BookingStats stats;
  final List<MovieRanking> movieRankings;
  final List<TheaterOccupancy> theaterOccupancy;

  factory BookingReport.fromJson(Map<String, dynamic> json) {
    return BookingReport(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      stats: BookingStats.fromJson(json['stats'] as Map<String, dynamic>),
      movieRankings: (json['movieRankings'] as List<dynamic>)
          .map((e) => MovieRanking.fromJson(e as Map<String, dynamic>))
          .toList(),
      theaterOccupancy: (json['theaterOccupancy'] as List<dynamic>)
          .map((e) => TheaterOccupancy.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ============================================================================
// Admin CRUD Models — Requirements 19.x, 20.x, 21.x, 22.x, 23.x
// ============================================================================

class MovieManagementRequest {
  const MovieManagementRequest({
    required this.title,
    required this.description,
    required this.genres,
    required this.durationMinutes,
    required this.director,
    required this.cast,
    required this.posterUrl,
    required this.trailerUrl,
    required this.ageRating,
    required this.releaseDate,
    required this.status,
    this.rating = 0.0,
  });

  final String title;
  final String description;
  final List<String> genres;
  final int durationMinutes;
  final String director;
  final List<String> cast;
  final String posterUrl;
  final String trailerUrl;
  final String ageRating;
  final DateTime releaseDate;
  final String status;
  final double rating;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'genres': genres,
    'durationMinutes': durationMinutes,
    'director': director,
    'cast': cast,
    'posterUrl': posterUrl,
    'trailerUrl': trailerUrl,
    'ageRating': ageRating,
    'releaseDate': releaseDate.toIso8601String().split('T').first,
    'status': status,
    'rating': rating,
  };
}

class FoodComboManagementRequest {
  const FoodComboManagementRequest({
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    this.imageUrl = '',
    this.isActive = true,
  });

  final String name;
  final String description;
  final int price;
  final int quantity;
  final String imageUrl;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
    'quantity': quantity,
    'imageUrl': imageUrl,
    'isActive': isActive,
  };
}

/// Admin food combo model – includes isActive (not present in public FoodCombo)
class ActorManagementRequest {
  const ActorManagementRequest({
    required this.name,
    this.avatarUrl = '',
    this.description = '',
  });

  final String name;
  final String avatarUrl;
  final String description;

  Map<String, dynamic> toJson() => {
    'name': name,
    'avatarUrl': avatarUrl,
    'description': description,
  };
}

class AdminActor {
  const AdminActor({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.description,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String description;

  factory AdminActor.fromJson(Map<String, dynamic> json) {
    return AdminActor(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class AdminFoodCombo {
  const AdminFoodCombo({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final int quantity;
  final String imageUrl;
  final bool isActive;

  factory AdminFoodCombo.fromJson(Map<String, dynamic> json) {
    return AdminFoodCombo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class Theater {
  const Theater({
    required this.id,
    required this.name,
    required this.address,
    this.city = '',
    this.active = true,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final bool active;

  factory Theater.fromJson(Map<String, dynamic> json) {
    return Theater(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }
}

class TheaterRequest {
  const TheaterRequest({
    required this.name,
    required this.address,
    this.city = '',
  });

  final String name;
  final String address;
  final String city;

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    if (city.isNotEmpty) 'city': city,
  };
}

class Room {
  const Room({
    required this.id,
    required this.theaterId,
    required this.name,
    required this.status,
    required this.totalSeats,
    this.screenType = '',
  });

  final String id;
  final String theaterId;
  final String name;
  final String status;
  final int totalSeats;
  final String screenType;

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      theaterId: json['theaterId'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      totalSeats: (json['totalSeats'] as num).toInt(),
      screenType: json['screenType'] as String? ?? '',
    );
  }
}

class RoomSeatLayout {
  const RoomSeatLayout({
    required this.seatCode,
    required this.row,
    required this.column,
    required this.seatType,
  });

  final String seatCode;
  final String row;
  final int column;
  final String seatType;

  Map<String, dynamic> toJson() => {
    'seatCode': seatCode,
    'row': row,
    'column': column,
    'seatType': seatType,
  };
}

class RoomRequest {
  const RoomRequest({
    required this.theaterId,
    required this.name,
    required this.capacity,
    required this.screenType,
    required this.seatLayout,
  });

  final String theaterId;
  final String name;
  final int capacity;
  final String screenType;
  final List<RoomSeatLayout> seatLayout;

  Map<String, dynamic> toJson() => {
    'theaterId': theaterId,
    'name': name,
    'capacity': capacity,
    'screenType': screenType,
    'seatLayout': seatLayout.map((seat) => seat.toJson()).toList(),
  };
}

class ShowtimeScheduleRequest {
  const ShowtimeScheduleRequest({
    required this.movieId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.basePrice,
    this.status = 'scheduled',
  });

  final String movieId;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;
  final int basePrice;
  final String status;

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'roomId': roomId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'basePrice': basePrice,
    'status': status,
  };
}

class AdminUser {
  const AdminUser({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.active,
    this.permissions = const <String>[],
  });

  final String userId;
  final String fullName;
  final String email;
  final String role;
  final bool active;
  final List<String> permissions;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      active: json['active'] as bool? ?? true,
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
    );
  }
}

class CreateStaffUserRequest {
  const CreateStaffUserRequest({
    required this.fullName,
    required this.email,
    required this.role,
    required this.permissions,
  });

  final String fullName;
  final String email;
  final String role;
  final List<String> permissions;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'role': role,
    'permissions': permissions,
  };
}

class StaffAccountCreationResult {
  const StaffAccountCreationResult({
    required this.user,
    required this.temporaryPassword,
    required this.welcomeEmailSent,
  });

  final AdminUser user;
  final String temporaryPassword;
  final bool welcomeEmailSent;

  factory StaffAccountCreationResult.fromJson(Map<String, dynamic> json) {
    return StaffAccountCreationResult(
      user: AdminUser.fromJson(json['user'] as Map<String, dynamic>),
      temporaryPassword: json['temporaryPassword'] as String? ?? '',
      welcomeEmailSent: json['welcomeEmailSent'] as bool? ?? false,
    );
  }
}

// ============================================================================
// Staff Operations Models — Requirements 27.x, 28.x
// ============================================================================

class RoomMaintenanceRequest {
  const RoomMaintenanceRequest({
    required this.staffId,
    required this.reason,
    required this.description,
  });

  final String staffId;
  final String reason;
  final String description;

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'reason': reason,
    'description': description,
  };
}

class RoomReadyRequest {
  const RoomReadyRequest({
    required this.staffId,
    required this.resolutionNotes,
  });

  final String staffId;
  final String resolutionNotes;

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'resolutionNotes': resolutionNotes,
  };
}

class TechnicalIssue {
  const TechnicalIssue({
    required this.id,
    required this.staffId,
    required this.roomId,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String staffId;
  final String roomId;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  factory TechnicalIssue.fromJson(Map<String, dynamic> json) {
    return TechnicalIssue(
      id: json['id'] as String,
      staffId: json['staffId'] as String,
      roomId: json['roomId'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
    );
  }
}

class ModifySeatsRequest {
  const ModifySeatsRequest({required this.staffId, required this.newSeatCodes});

  final String staffId;
  final List<String> newSeatCodes;

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'newSeatCodes': newSeatCodes,
  };
}

class ModifyCombosRequest {
  const ModifyCombosRequest({required this.staffId, required this.combos});

  final String staffId;
  final List<Map<String, dynamic>> combos;

  Map<String, dynamic> toJson() => {'staffId': staffId, 'combos': combos};
}

class BookingModificationResult {
  const BookingModificationResult({
    required this.bookingId,
    required this.status,
    required this.totalAmount,
    required this.priceDifference,
    required this.requiresAdditionalPayment,
    this.paymentUrl,
  });

  final String bookingId;
  final String status;
  final int totalAmount;
  final int priceDifference;
  final bool requiresAdditionalPayment;
  final String? paymentUrl;

  factory BookingModificationResult.fromJson(Map<String, dynamic> json) {
    return BookingModificationResult(
      bookingId: json['bookingId'] as String,
      status: json['status'] as String,
      totalAmount: (json['totalAmount'] as num).toInt(),
      priceDifference: (json['priceDifference'] as num).toInt(),
      requiresAdditionalPayment:
          json['requiresAdditionalPayment'] as bool? ?? false,
      paymentUrl: json['paymentUrl'] as String?,
    );
  }
}

// ============================================================================
// Payment Settings Models — Requirements 26.x
// ============================================================================

class PaymentSettings {
  const PaymentSettings({
    required this.terminalId,
    required this.secretKey,
    required this.environment,
    required this.returnUrl,
    required this.enabled,
  });

  final String terminalId;
  final String secretKey;
  final String environment;
  final String returnUrl;
  final bool enabled;

  factory PaymentSettings.fromJson(Map<String, dynamic> json) {
    return PaymentSettings(
      terminalId: json['terminalId'] as String,
      secretKey: json['secretKey'] as String,
      environment: json['environment'] as String,
      returnUrl: json['returnUrl'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class UpdatePaymentSettingsRequest {
  const UpdatePaymentSettingsRequest({
    required this.terminalId,
    required this.secretKey,
    required this.environment,
    required this.returnUrl,
    required this.enabled,
  });

  final String terminalId;
  final String secretKey;
  final String environment;
  final String returnUrl;
  final bool enabled;

  Map<String, dynamic> toJson() => {
    'terminalId': terminalId,
    'secretKey': secretKey,
    'environment': environment,
    'returnUrl': returnUrl,
    'enabled': enabled,
  };
}
