import 'package:flutter/foundation.dart';

import '../core/formatters.dart';
import '../models/app_models.dart';
import '../../models/movie.dart' as api_movie;
import '../../models/showtime.dart' as api_showtime;
import '../../models/user_profile.dart' as api_user;
import '../../models/booking_models.dart' as api_models;
import '../../websocket/seat_update.dart' as ws_models;

class CinemaStore extends ChangeNotifier {
  CinemaStore();

  List<AppUser> users = [];
  List<Movie> movies = [];
  List<Cinema> cinemas = [];
  List<Room> rooms = [];
  List<Showtime> showtimes = [];
  List<SeatSpot> seats = [];
  List<FoodCombo> combos = [];
  List<AppBanner> banners = [];
  VnpayConfig vnpayConfig = const VnpayConfig(
    terminalId: '',
    secretKey: '',
    environment: 'API',
  );
  final List<String> customGenres = [];
  AppLanguage language = AppLanguage.vi;

  final List<Booking> bookings = [];
  final List<Payment> payments = [];
  final List<Review> reviews = [];
  final List<TechnicalIssue> issues = [];
  final Map<String, bool> notificationSettings = {
    'Nháº¯c giá» chiáº¿u': true,
    'Khuyáº¿n mÃ£i': true,
    'Phim má»›i': true,
  };

  AppUser? currentUser;
  DateTime? holdStartedAt;
  final Map<String, Map<String, SeatStatus>> _remoteSeatStatuses = {};

  int standardSeatSurcharge = 0;
  int vipSeatSurcharge = 45000;
  int coupleSeatSurcharge = 70000;

  bool get isLoggedIn => currentUser != null;

  void setCurrentUserFromProfile(api_user.UserProfile profile) {
    final user = AppUser(
      id: profile.id,
      fullName: profile.fullName,
      email: profile.email,
      password: '',
      phone: profile.phone ?? '',
      role: _roleFromApi(profile.role),
      avatar: profile.avatarUrl ?? '',
      memberRank: profile.memberRank,
      points: profile.points,
      isActive: profile.isActive,
      permissions: profile.permissions ?? const [],
    );
    currentUser = user;
    users = [user, ...users.where((item) => item.id != user.id)];
    notifyListeners();
  }

  UserRole _roleFromApi(String role) {
    return switch (role.toLowerCase()) {
      'admin' => UserRole.admin,
      'staff' => UserRole.staff,
      _ => UserRole.customer,
    };
  }

  void replaceMoviesFromApi(List<api_movie.Movie> apiMovies) {
    movies = apiMovies.map(_movieFromApi).toList();
    notifyListeners();
  }

  void replaceShowtimesFromApi(List<api_showtime.Showtime> apiShowtimes) {
    final nextCinemas = <String, Cinema>{
      for (final cinema in cinemas) cinema.id: cinema,
    };
    final nextRooms = <String, Room>{for (final room in rooms) room.id: room};

    showtimes = apiShowtimes.map((item) {
      final cinemaId = _stableCinemaId(item.cinemaName, item.cinemaAddress);
      nextCinemas[cinemaId] = Cinema(
        id: cinemaId,
        name: item.cinemaName,
        address: item.cinemaAddress,
        city: '',
        latitude: 0,
        longitude: 0,
        phone: '',
      );
      nextRooms[item.roomId] = Room(
        id: item.roomId,
        cinemaId: cinemaId,
        name: item.roomName,
        capacity: 0,
        screenType: _screenTypeFromRoomName(item.roomName),
        status: item.isCancelled ? RoomStatus.maintenance : RoomStatus.ready,
      );
      return Showtime(
        id: item.id,
        movieId: item.movieId,
        roomId: item.roomId,
        startTime: item.startTime,
        endTime: item.endTime,
        basePrice: item.basePrice,
        status: item.status,
      );
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

    cinemas = nextCinemas.values.toList();
    rooms = nextRooms.values.toList();
    notifyListeners();
  }

  void register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) {
    final user = AppUser(
      id: 'U${compactId(DateTime.now())}',
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
      role: UserRole.customer,
      memberRank: 'ThÃ nh viÃªn má»›i',
      points: 100,
    );
    users = [user, ...users];
    currentUser = user;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  void updateProfile(String name, String phone) {
    final user = currentUser;
    if (user == null) return;
    final updated = user.copyWith(fullName: name, phone: phone);
    users = users.map((item) => item.id == user.id ? updated : item).toList();
    currentUser = updated;
    notifyListeners();
  }

  Movie _movieFromApi(api_movie.Movie movie) {
    return Movie(
      id: movie.id,
      title: movie.title,
      description: movie.description,
      genres: movie.genres,
      durationMinutes: movie.durationMinutes,
      director: movie.director,
      cast: movie.cast,
      posterUrl: movie.posterUrl,
      trailerUrl: movie.trailerUrl,
      rating: movie.rating <= 5 ? movie.rating * 2 : movie.rating,
      ageRating: movie.ageRating,
      releaseDate: movie.releaseDate,
      status: movie.isComingSoon
          ? MovieStatus.comingSoon
          : MovieStatus.nowShowing,
      heroColor: 0xFFC9A44C,
    );
  }

  String _stableCinemaId(String name, String address) {
    final raw = '$name|$address'.trim().toLowerCase();
    return raw.isEmpty ? 'cinema-api' : 'cinema-${raw.hashCode.abs()}';
  }

  String _screenTypeFromRoomName(String roomName) {
    final upper = roomName.toUpperCase();
    if (upper.contains('IMAX')) return 'IMAX';
    if (upper.contains('3D')) return '3D';
    return '2D';
  }

  List<Movie> searchMovies(String query, String genre, MovieStatus? status) {
    final text = query.trim().toLowerCase();
    return movies.where((movie) {
      final matchesText =
          text.isEmpty ||
          movie.title.toLowerCase().contains(text) ||
          movie.director.toLowerCase().contains(text) ||
          movie.cast.any((actor) => actor.toLowerCase().contains(text)) ||
          movie.genres.any((item) => item.toLowerCase().contains(text));
      final matchesGenre =
          genre == 'Táº¥t cáº£' || movie.genres.contains(genre);
      final matchesStatus = status == null || movie.status == status;
      return matchesText && matchesGenre && matchesStatus;
    }).toList();
  }

  List<String> get genres {
    final values = {...customGenres, ...movies.expand((movie) => movie.genres)};
    return ['Táº¥t cáº£', ...values];
  }

  Movie movieById(String id) => movies.firstWhere((movie) => movie.id == id);

  Room roomById(String id) => rooms.firstWhere(
    (room) => room.id == id,
    orElse: () => Room(
      id: id,
      cinemaId: 'cinema-api',
      name: 'Phòng chiếu',
      capacity: 0,
      screenType: '2D',
      status: RoomStatus.ready,
    ),
  );

  Cinema cinemaForRoom(String roomId) {
    final room = roomById(roomId);
    return cinemas.firstWhere(
      (cinema) => cinema.id == room.cinemaId,
      orElse: () => const Cinema(
        id: 'cinema-api',
        name: 'CineLuxe',
        address: '',
        city: '',
        latitude: 0,
        longitude: 0,
        phone: '',
      ),
    );
  }

  List<Showtime> showtimesForMovie(String movieId) {
    return showtimes.where((item) => item.movieId == movieId).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<Booking> bookingsForUser(String userId) {
    return bookings.where((booking) => booking.userId == userId).toList();
  }

  Payment? paymentForBooking(String bookingId) {
    return payments.where((item) => item.bookingId == bookingId).firstOrNull;
  }

  int seatPrice(SeatSpot seat, Showtime showtime) {
    return switch (seat.type) {
      SeatType.standard => showtime.basePrice + standardSeatSurcharge,
      SeatType.vip => showtime.basePrice + vipSeatSurcharge,
      SeatType.couple => (showtime.basePrice * 2) + coupleSeatSurcharge,
    };
  }

  Set<String> bookedSeats(String showtimeId) {
    final local = bookings
        .where(
          (booking) =>
              booking.showtimeId == showtimeId &&
              booking.status != BookingStatus.cancelled &&
              booking.status != BookingStatus.refunded,
        )
        .expand((booking) => booking.seats)
        .toSet();
    final remote = _remoteSeatStatuses[showtimeId] ?? const {};
    local.addAll(
      remote.entries
          .where((entry) => entry.value == SeatStatus.booked)
          .map((entry) => entry.key),
    );
    return local;
  }

  Set<String> heldSeats(String showtimeId) {
    final remote = _remoteSeatStatuses[showtimeId] ?? const {};
    return remote.entries
        .where((entry) => entry.value == SeatStatus.held)
        .map((entry) => entry.key)
        .toSet()
      ..removeAll(bookedSeats(showtimeId));
  }

  void applySeatMap(api_models.SeatMap seatMap) {
    seats = seatMap.seats.map((seat) {
      return SeatSpot(
        code: seat.code,
        row: seat.row,
        column: seat.column,
        type: _seatTypeFromApi(seat.type),
      );
    }).toList();
    _remoteSeatStatuses[seatMap.showtimeId] = {
      for (final seat in seatMap.seats) seat.code: _appSeatStatus(seat.status),
    };
    notifyListeners();
  }

  SeatType _seatTypeFromApi(String type) {
    return switch (type.toLowerCase()) {
      'vip' => SeatType.vip,
      'couple' => SeatType.couple,
      _ => SeatType.standard,
    };
  }

  void applySeatUpdate(String showtimeId, ws_models.SeatUpdate update) {
    _remoteSeatStatuses.putIfAbsent(
      showtimeId,
      () => {},
    )[update.seatCode] = switch (update.status) {
      ws_models.SeatStatus.available => SeatStatus.available,
      ws_models.SeatStatus.held => SeatStatus.held,
      ws_models.SeatStatus.booked => SeatStatus.booked,
      ws_models.SeatStatus.selected => SeatStatus.selected,
    };
    notifyListeners();
  }

  SeatStatus _appSeatStatus(api_models.ApiSeatStatus status) {
    return switch (status) {
      api_models.ApiSeatStatus.available => SeatStatus.available,
      api_models.ApiSeatStatus.held => SeatStatus.held,
      api_models.ApiSeatStatus.booked => SeatStatus.booked,
      api_models.ApiSeatStatus.selected => SeatStatus.selected,
    };
  }

  int calculateTotal(
    Showtime showtime,
    List<String> selectedSeats,
    Iterable<String> selectedCombos,
  ) {
    final seatTotal = selectedSeats.fold<int>(0, (sum, code) {
      final seat = seats.firstWhere((item) => item.code == code);
      return sum + seatPrice(seat, showtime);
    });
    final comboTotal = selectedCombos.fold<int>(0, (sum, comboId) {
      final combo = combos.firstWhere((item) => item.id == comboId);
      return sum + combo.price;
    });
    return seatTotal + comboTotal;
  }

  Booking createBooking({
    required Showtime showtime,
    required List<String> selectedSeats,
    required Iterable<String> selectedCombos,
    String paymentMethod = 'vnpay',
    String? transactionId,
  }) {
    final comboList = List<String>.unmodifiable(selectedCombos);
    final user = currentUser!;
    final movie = movieById(showtime.movieId);
    final now = DateTime.now();
    final id = 'BK${compactId(now)}';
    final booking = Booking(
      id: id,
      userId: user.id,
      customerName: user.fullName,
      showtimeId: showtime.id,
      movieTitle: movie.title,
      seats: List.unmodifiable(selectedSeats),
      comboIds: comboList,
      totalAmount: calculateTotal(showtime, selectedSeats, selectedCombos),
      status: BookingStatus.active,
      createdAt: now,
      qrCode:
          'CINELUXE|$id|${user.id}|${showtime.id}|${selectedSeats.join('-')}',
    );
    final payment = Payment(
      id: 'PAY${compactId(now)}',
      bookingId: id,
      method: paymentMethod,
      amount: booking.totalAmount,
      status: PaymentStatus.success,
      vnpayTransactionId: transactionId ?? 'VNP${now.millisecondsSinceEpoch}',
      vnpayResponseCode: '00',
      paidAt: now,
    );
    bookings.insert(0, booking);
    payments.insert(0, payment);
    users = users
        .map(
          (item) => item.id == user.id
              ? item.copyWith(
                  points: item.points + booking.totalAmount ~/ 10000,
                )
              : item,
        )
        .toList();
    currentUser = users.firstWhere((item) => item.id == user.id);
    notifyListeners();
    return booking;
  }

  void cancelBooking(String bookingId) {
    bookings.replaceWhere(
      (item) => item.id == bookingId,
      (item) => item.copyWith(status: BookingStatus.refunded),
    );
    payments.replaceWhere(
      (item) => item.bookingId == bookingId,
      (item) =>
          item.copyWith(status: PaymentStatus.refunded, responseCode: 'REFUND'),
    );
    notifyListeners();
  }

  String validateTicket(String rawCode, {String? expectedShowtimeId}) {
    final text = rawCode.trim();
    final booking = bookings.where((item) {
      return item.id.toLowerCase() == text.toLowerCase() ||
          item.qrCode.toLowerCase() == text.toLowerCase();
    }).firstOrNull;
    if (booking == null) return 'Không tìm thấy vé hoặc QR không hợp lệ.';
    if (expectedShowtimeId != null &&
        booking.showtimeId != expectedShowtimeId) {
      final expected = showtimes
          .where((item) => item.id == expectedShowtimeId)
          .firstOrNull;
      final actual = showtimes
          .where((item) => item.id == booking.showtimeId)
          .firstOrNull;
      final expectedText = expected == null
          ? expectedShowtimeId
          : '${movieById(expected.movieId).title} ${shortDate(expected.startTime)} ${shortTime(expected.startTime)}';
      final actualText = actual == null
          ? booking.showtimeId
          : '${booking.movieTitle} ${shortDate(actual.startTime)} ${shortTime(actual.startTime)}';
      return 'Sai suất chiếu. Vé thuộc: $actualText. Suất đang soát: $expectedText.';
    }
    if (booking.status == BookingStatus.used) return 'Vé đã được sử dụng.';
    if (booking.status == BookingStatus.cancelled ||
        booking.status == BookingStatus.refunded) {
      return 'Vé đã hủy/hoàn tiền, không được vào rạp.';
    }
    bookings.replaceWhere(
      (item) => item.id == booking.id,
      (item) => item.copyWith(status: BookingStatus.used),
    );
    notifyListeners();
    return 'Hợp lệ: ${booking.customerName} - ${booking.movieTitle} - ghế ${booking.seats.join(', ')}.';
  }

  void saveMovie(Movie movie) {
    final exists = movies.any((item) => item.id == movie.id);
    movies = exists
        ? movies.map((item) => item.id == movie.id ? movie : item).toList()
        : [movie, ...movies];
    notifyListeners();
  }

  void deleteMovie(String movieId) {
    movies = movies.where((movie) => movie.id != movieId).toList();
    notifyListeners();
  }

  void addGenre(String genre) {
    final value = genre.trim();
    if (value.isEmpty || genres.contains(value)) return;
    customGenres.add(value);
    notifyListeners();
  }

  void updateGenre(String oldGenre, String newGenre) {
    final oldValue = oldGenre.trim();
    final newValue = newGenre.trim();
    if (oldValue.isEmpty || newValue.isEmpty || oldValue == newValue) return;
    if (genres.contains(newValue)) return;

    final index = customGenres.indexOf(oldValue);
    if (index == -1) {
      customGenres.add(newValue);
    } else {
      customGenres[index] = newValue;
    }

    movies = movies.map((movie) {
      if (!movie.genres.contains(oldValue)) return movie;
      final nextGenres = movie.genres
          .map((item) => item == oldValue ? newValue : item)
          .toSet()
          .toList();
      return movie.copyWith(genres: nextGenres);
    }).toList();
    notifyListeners();
  }

  void deleteGenre(String genre) {
    customGenres.remove(genre);
    movies = movies.map((movie) {
      if (!movie.genres.contains(genre)) return movie;
      final nextGenres = movie.genres.where((item) => item != genre).toList();
      return movie.copyWith(genres: nextGenres.isEmpty ? ['Khác'] : nextGenres);
    }).toList();
    notifyListeners();
  }

  void toggleUserStatus(String userId) {
    users = users
        .map(
          (user) => user.id == userId
              ? user.copyWith(isActive: !user.isActive)
              : user,
        )
        .toList();
    notifyListeners();
  }

  void addStaff(String name, String email) {
    users = [
      AppUser(
        id: 'S${compactId(DateTime.now())}',
        fullName: name,
        email: email,
        password: '123456',
        phone: '0909000999',
        role: UserRole.staff,
        permissions: const ['SoÃ¡t vÃ©'],
      ),
      ...users,
    ];
    notifyListeners();
  }

  void toggleRoomStatus(String roomId) {
    rooms = rooms.map((room) {
      if (room.id != roomId) return room;
      return room.copyWith(
        status: room.status == RoomStatus.ready
            ? RoomStatus.maintenance
            : RoomStatus.ready,
      );
    }).toList();
    notifyListeners();
  }

  void setRoomStatus(String roomId, RoomStatus status) {
    rooms = rooms
        .map((room) => room.id == roomId ? room.copyWith(status: status) : room)
        .toList();
    notifyListeners();
  }

  void reportIssue(String roomId, String description) {
    issues.insert(
      0,
      TechnicalIssue(
        id: 'ISS${compactId(DateTime.now())}',
        roomId: roomId,
        description: description,
        createdAt: DateTime.now(),
        status: 'ÄÃ£ gá»­i Admin',
      ),
    );
    notifyListeners();
  }

  void addReview(String movieId, int rating, String comment) {
    final user = currentUser;
    if (user == null) return;
    reviews.insert(
      0,
      Review(
        id: 'RV${compactId(DateTime.now())}',
        userId: user.id,
        movieId: movieId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void setNotification(String key, bool enabled) {
    notificationSettings[key] = enabled;
    notifyListeners();
  }

  void deleteUser(String userId) {
    users = users.where((user) => user.id != userId).toList();
    if (currentUser?.id == userId) currentUser = null;
    notifyListeners();
  }

  void updateUserPermissions(String userId, List<String> permissions) {
    users = users
        .map(
          (user) => user.id == userId
              ? user.copyWith(permissions: List.unmodifiable(permissions))
              : user,
        )
        .toList();
    if (currentUser?.id == userId) {
      currentUser = users.firstWhere((user) => user.id == userId);
    }
    notifyListeners();
  }

  void saveRoom(Room room) {
    final exists = rooms.any((item) => item.id == room.id);
    rooms = exists
        ? rooms.map((item) => item.id == room.id ? room : item).toList()
        : [room, ...rooms];
    notifyListeners();
  }

  void replaceRooms(List<Room> nextRooms) {
    rooms = List.unmodifiable(nextRooms);
    notifyListeners();
  }

  void saveShowtime(Showtime showtime) {
    final exists = showtimes.any((item) => item.id == showtime.id);
    showtimes = exists
        ? showtimes
              .map((item) => item.id == showtime.id ? showtime : item)
              .toList()
        : [showtime, ...showtimes];
    notifyListeners();
  }

  void deleteShowtime(String showtimeId) {
    showtimes = showtimes
        .where((showtime) => showtime.id != showtimeId)
        .toList();
    notifyListeners();
  }

  void saveBanner(AppBanner banner) {
    final exists = banners.any((item) => item.id == banner.id);
    banners = exists
        ? banners.map((item) => item.id == banner.id ? banner : item).toList()
        : [banner, ...banners];
    notifyListeners();
  }

  void updateVnpayConfig(VnpayConfig config) {
    vnpayConfig = config;
    notifyListeners();
  }

  void updateSeatPricing({
    required int standardSurcharge,
    required int vipSurcharge,
    required int coupleSurcharge,
  }) {
    standardSeatSurcharge = standardSurcharge;
    vipSeatSurcharge = vipSurcharge;
    coupleSeatSurcharge = coupleSurcharge;
    notifyListeners();
  }

  void setLanguage(AppLanguage nextLanguage) {
    language = nextLanguage;
    notifyListeners();
  }

  int revenueTotal() {
    return payments
        .where((payment) => payment.status == PaymentStatus.success)
        .fold(0, (sum, payment) => sum + payment.amount);
  }

  Map<String, int> soldTicketsByMovie() {
    final result = <String, int>{};
    for (final booking in bookings.where(
      (item) => item.status != BookingStatus.refunded,
    )) {
      result[booking.movieTitle] =
          (result[booking.movieTitle] ?? 0) + booking.seats.length;
    }
    return result;
  }

  // ignore: unused_element
  void _disabledBookingFixture() {
    final showtime = showtimes.first;
    final booking = Booking(
      id: '',
      userId: 'U001',
      customerName: 'Nguyá»…n Minh Anh',
      showtimeId: showtime.id,
      movieTitle: movieById(showtime.movieId).title,
      seats: const ['C4', 'C5'],
      comboIds: const ['CB01'],
      totalAmount: 469000,
      status: BookingStatus.active,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      qrCode: '',
    );
    bookings.add(booking);
    payments.add(
      Payment(
        id: 'PAY-DEMO01',
        bookingId: booking.id,
        method: 'vnpay',
        amount: booking.totalAmount,
        status: PaymentStatus.success,
        vnpayTransactionId: '',
        vnpayResponseCode: '00',
        paidAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    );
  }
}

extension ReplaceWhere<T> on List<T> {
  void replaceWhere(bool Function(T item) test, T Function(T item) replace) {
    final index = indexWhere(test);
    if (index != -1) this[index] = replace(this[index]);
  }
}
