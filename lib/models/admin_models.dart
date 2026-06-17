/// Admin dashboard models — plain Dart, no code generation.
///
/// Requirements: 24.1, 24.2, 24.3, 24.4, 25.1, 25.2, 25.3, 25.4, 25.5

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
