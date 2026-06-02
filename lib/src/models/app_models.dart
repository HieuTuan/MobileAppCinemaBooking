enum UserRole { customer, staff, admin }

enum MovieStatus { nowShowing, comingSoon }

enum SeatType { standard, vip, couple }

enum SeatStatus { available, held, booked, selected }

enum BookingStatus { active, used, cancelled, refunded }

enum PaymentStatus { processing, success, failed, refunded }

enum RoomStatus { ready, maintenance }

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.role,
    this.avatar = '',
    this.memberRank = 'Bạc',
    this.points = 0,
    this.isActive = true,
    this.permissions = const [],
  });

  final String id;
  final String fullName;
  final String email;
  final String password;
  final String phone;
  final UserRole role;
  final String avatar;
  final String memberRank;
  final int points;
  final bool isActive;
  final List<String> permissions;

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? memberRank,
    int? points,
    bool? isActive,
    List<String>? permissions,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password,
      phone: phone ?? this.phone,
      role: role,
      avatar: avatar,
      memberRank: memberRank ?? this.memberRank,
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
    );
  }
}

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.genres,
    required this.durationMinutes,
    required this.director,
    required this.cast,
    required this.posterUrl,
    required this.trailerUrl,
    required this.rating,
    required this.ageRating,
    required this.releaseDate,
    required this.status,
    required this.heroColor,
  });

  final String id;
  final String title;
  final String description;
  final List<String> genres;
  final int durationMinutes;
  final String director;
  final List<String> cast;
  final String posterUrl;
  final String trailerUrl;
  final double rating;
  final String ageRating;
  final DateTime releaseDate;
  final MovieStatus status;
  final int heroColor;

  Movie copyWith({
    String? title,
    String? description,
    List<String>? genres,
    int? durationMinutes,
    String? director,
    List<String>? cast,
    String? posterUrl,
    String? trailerUrl,
    double? rating,
    String? ageRating,
    DateTime? releaseDate,
    MovieStatus? status,
  }) {
    return Movie(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      director: director ?? this.director,
      cast: cast ?? this.cast,
      posterUrl: posterUrl ?? this.posterUrl,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      rating: rating ?? this.rating,
      ageRating: ageRating ?? this.ageRating,
      releaseDate: releaseDate ?? this.releaseDate,
      status: status ?? this.status,
      heroColor: heroColor,
    );
  }
}

class Cinema {
  const Cinema({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.phone,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String phone;
}

class Room {
  const Room({
    required this.id,
    required this.cinemaId,
    required this.name,
    required this.capacity,
    required this.screenType,
    required this.status,
  });

  final String id;
  final String cinemaId;
  final String name;
  final int capacity;
  final String screenType;
  final RoomStatus status;

  Room copyWith({RoomStatus? status}) {
    return Room(
      id: id,
      cinemaId: cinemaId,
      name: name,
      capacity: capacity,
      screenType: screenType,
      status: status ?? this.status,
    );
  }
}

class Showtime {
  const Showtime({
    required this.id,
    required this.movieId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.basePrice,
    required this.status,
  });

  final String id;
  final String movieId;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;
  final int basePrice;
  final String status;
}

class SeatSpot {
  const SeatSpot({
    required this.code,
    required this.row,
    required this.column,
    required this.type,
  });

  final String code;
  final String row;
  final int column;
  final SeatType type;
}

class FoodCombo {
  const FoodCombo({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  final String id;
  final String name;
  final String description;
  final int price;
}

class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.showtimeId,
    required this.movieTitle,
    required this.seats,
    required this.comboIds,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.qrCode,
  });

  final String id;
  final String userId;
  final String customerName;
  final String showtimeId;
  final String movieTitle;
  final List<String> seats;
  final List<String> comboIds;
  final int totalAmount;
  final BookingStatus status;
  final DateTime createdAt;
  final String qrCode;

  Booking copyWith({BookingStatus? status}) {
    return Booking(
      id: id,
      userId: userId,
      customerName: customerName,
      showtimeId: showtimeId,
      movieTitle: movieTitle,
      seats: seats,
      comboIds: comboIds,
      totalAmount: totalAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      qrCode: qrCode,
    );
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.method,
    required this.amount,
    required this.status,
    required this.vnpayTransactionId,
    required this.vnpayResponseCode,
    required this.paidAt,
  });

  final String id;
  final String bookingId;
  final String method;
  final int amount;
  final PaymentStatus status;
  final String vnpayTransactionId;
  final String vnpayResponseCode;
  final DateTime paidAt;

  Payment copyWith({PaymentStatus? status, String? responseCode}) {
    return Payment(
      id: id,
      bookingId: bookingId,
      method: method,
      amount: amount,
      status: status ?? this.status,
      vnpayTransactionId: vnpayTransactionId,
      vnpayResponseCode: responseCode ?? vnpayResponseCode,
      paidAt: paidAt,
    );
  }
}

class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String movieId;
  final int rating;
  final String comment;
  final DateTime createdAt;
}

class AppBanner {
  const AppBanner({
    required this.id,
    required this.title,
    required this.message,
    required this.active,
  });

  final String id;
  final String title;
  final String message;
  final bool active;
}

class TechnicalIssue {
  const TechnicalIssue({
    required this.id,
    required this.roomId,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String roomId;
  final String description;
  final DateTime createdAt;
  final String status;
}

class VnpayConfig {
  const VnpayConfig({
    required this.terminalId,
    required this.secretKey,
    required this.environment,
  });

  final String terminalId;
  final String secretKey;
  final String environment;
}
