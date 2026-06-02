import '../models/app_models.dart';

class SeedData {
  static DateTime get _today => DateTime.now();

  static List<AppUser> users() {
    return const [
      AppUser(
        id: 'U001',
        fullName: 'Nguyễn Minh Anh',
        email: 'user@cineluxe.vn',
        password: '123456',
        phone: '0909000111',
        role: UserRole.customer,
        memberRank: 'Vàng',
        points: 1280,
      ),
      AppUser(
        id: 'S001',
        fullName: 'Trần Hoàng Staff',
        email: 'staff@cineluxe.vn',
        password: '123456',
        phone: '0909000222',
        role: UserRole.staff,
        permissions: ['Soát vé', 'Hỗ trợ quầy', 'Trạng thái phòng'],
      ),
      AppUser(
        id: 'A001',
        fullName: 'Lê Quỳnh Admin',
        email: 'admin@cineluxe.vn',
        password: '123456',
        phone: '0909000333',
        role: UserRole.admin,
        permissions: ['Nội dung', 'Tài khoản', 'Tài chính', 'Hệ thống'],
      ),
    ];
  }

  static List<Movie> movies() {
    final now = _today;
    return [
      Movie(
        id: 'M001',
        title: 'Dune: Part Two',
        description:
            'Paul Atreides liên minh cùng Chani và người Fremen để bảo vệ Arrakis trong một chuyến hành trình lớn, đầy cát, âm mưu và định mệnh.',
        genres: const ['Khoa học viễn tưởng', 'Phiêu lưu', 'IMAX'],
        durationMinutes: 166,
        director: 'Denis Villeneuve',
        cast: const ['Timothee Chalamet', 'Zendaya', 'Rebecca Ferguson'],
        posterUrl:
            'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
        trailerUrl: 'https://youtu.be/Way9Dexny3w',
        rating: 9.1,
        ageRating: 'T16',
        releaseDate: now.subtract(const Duration(days: 60)),
        status: MovieStatus.nowShowing,
        heroColor: 0xFFC9A44C,
      ),
      Movie(
        id: 'M002',
        title: 'Inside Out 2',
        description:
            'Riley bước vào tuổi teen và trung tâm cảm xúc đón nhận những vị khách mới: Lo Âu, Ghen Tị, Xấu Hổ và Nhút Nhát.',
        genres: const ['Hoạt hình', 'Gia đình', 'Hài'],
        durationMinutes: 96,
        director: 'Kelsey Mann',
        cast: const ['Amy Poehler', 'Maya Hawke', 'Kensington Tallman'],
        posterUrl:
            'https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLvDESb2QY.jpg',
        trailerUrl: 'https://youtu.be/LEjhY15eCx0',
        rating: 8.6,
        ageRating: 'P',
        releaseDate: now.subtract(const Duration(days: 18)),
        status: MovieStatus.nowShowing,
        heroColor: 0xFF89A7FF,
      ),
      Movie(
        id: 'M003',
        title: 'A Quiet Place: Day One',
        description:
            'New York chìm vào im lặng bất thường khi những sinh vật săn mồi bằng âm thanh bắt đầu cuộc tấn công đầu tiên.',
        genres: const ['Kinh dị', 'Hồi hộp'],
        durationMinutes: 99,
        director: 'Michael Sarnoski',
        cast: const ['Lupita Nyongo', 'Joseph Quinn', 'Alex Wolff'],
        posterUrl:
            'https://image.tmdb.org/t/p/w500/yrpPYKijwdMHyTGIOd1iK1h0Xno.jpg',
        trailerUrl: 'https://youtu.be/YPY7J-flzE8',
        rating: 8.0,
        ageRating: 'T18',
        releaseDate: now.add(const Duration(days: 10)),
        status: MovieStatus.comingSoon,
        heroColor: 0xFF8C98A8,
      ),
      Movie(
        id: 'M004',
        title: 'Furiosa',
        description:
            'Nguồn gốc chiến binh Furiosa được kể lại bằng tốc độ cao, những trận chiến trên sa mạc và tham vọng sinh tồn.',
        genres: const ['Hành động', 'Phiêu lưu'],
        durationMinutes: 148,
        director: 'George Miller',
        cast: const ['Anya Taylor-Joy', 'Chris Hemsworth'],
        posterUrl:
            'https://image.tmdb.org/t/p/w500/iADOJ8Zymht2JPMoy3R7xceZprc.jpg',
        trailerUrl: 'https://youtu.be/FVswuip0-co',
        rating: 8.4,
        ageRating: 'T16',
        releaseDate: now.subtract(const Duration(days: 26)),
        status: MovieStatus.nowShowing,
        heroColor: 0xFFE5BC78,
      ),
    ];
  }

  static List<Cinema> cinemas() {
    return const [
      Cinema(
        id: 'C001',
        name: 'CineLuxe Tràng Tiền',
        address: '24 Hai Bà Trưng, Hoàn Kiếm',
        city: 'Hà Nội',
        latitude: 21.0245,
        longitude: 105.852,
        phone: '024 7777 8888',
      ),
    ];
  }

  static List<Room> rooms() {
    return const [
      Room(
        id: 'R001',
        cinemaId: 'C001',
        name: 'Crystal IMAX',
        capacity: 72,
        screenType: 'IMAX',
        status: RoomStatus.ready,
      ),
      Room(
        id: 'R002',
        cinemaId: 'C001',
        name: 'Pearl 3D',
        capacity: 60,
        screenType: '3D',
        status: RoomStatus.ready,
      ),
      Room(
        id: 'R003',
        cinemaId: 'C001',
        name: 'Velvet 2D',
        capacity: 48,
        screenType: '2D',
        status: RoomStatus.maintenance,
      ),
    ];
  }

  static List<Showtime> showtimes() {
    final base = DateTime(_today.year, _today.month, _today.day);
    return [
      Showtime(
        id: 'ST001',
        movieId: 'M001',
        roomId: 'R001',
        startTime: base.add(const Duration(hours: 10, minutes: 30)),
        endTime: base.add(const Duration(hours: 13, minutes: 16)),
        basePrice: 145000,
        status: 'Đang mở',
      ),
      Showtime(
        id: 'ST002',
        movieId: 'M001',
        roomId: 'R002',
        startTime: base.add(const Duration(hours: 19)),
        endTime: base.add(const Duration(hours: 21, minutes: 46)),
        basePrice: 165000,
        status: 'Đang mở',
      ),
      Showtime(
        id: 'ST003',
        movieId: 'M002',
        roomId: 'R002',
        startTime: base.add(const Duration(days: 1, hours: 14)),
        endTime: base.add(const Duration(days: 1, hours: 15, minutes: 36)),
        basePrice: 120000,
        status: 'Đang mở',
      ),
      Showtime(
        id: 'ST004',
        movieId: 'M004',
        roomId: 'R001',
        startTime: base.add(const Duration(days: 1, hours: 21)),
        endTime: base.add(const Duration(days: 1, hours: 23, minutes: 28)),
        basePrice: 155000,
        status: 'Đang mở',
      ),
      Showtime(
        id: 'ST005',
        movieId: 'M003',
        roomId: 'R003',
        startTime: base.add(const Duration(days: 10, hours: 20)),
        endTime: base.add(const Duration(days: 10, hours: 21, minutes: 39)),
        basePrice: 135000,
        status: 'Sắp mở',
      ),
    ];
  }

  static List<SeatSpot> seats() {
    final seats = <SeatSpot>[];
    for (final row in ['A', 'B', 'C', 'D', 'E', 'F']) {
      for (var col = 1; col <= 10; col++) {
        final type = row == 'E' || row == 'F'
            ? SeatType.couple
            : row == 'C' || row == 'D'
            ? SeatType.vip
            : SeatType.standard;
        seats.add(
          SeatSpot(code: '$row$col', row: row, column: col, type: type),
        );
      }
    }
    return seats;
  }

  static List<FoodCombo> combos() {
    return const [
      FoodCombo(
        id: 'CB01',
        name: 'Royal Popcorn',
        description: 'Bắp caramel lớn + 2 nước ngọt',
        price: 89000,
      ),
      FoodCombo(
        id: 'CB02',
        name: 'Couple Sparkle',
        description: 'Bắp phô mai + nachos + 2 trà đào',
        price: 149000,
      ),
      FoodCombo(
        id: 'CB03',
        name: 'Family Luxe',
        description: '2 bắp lớn + 4 nước + snack trẻ em',
        price: 239000,
      ),
    ];
  }

  static List<AppBanner> banners() {
    return const [
      AppBanner(
        id: 'BN01',
        title: 'Ưu đãi VNPay',
        message: 'Giảm 20% tối đa 50.000 VND khi thanh toán qua VNPay sandbox.',
        active: true,
      ),
      AppBanner(
        id: 'BN02',
        title: 'IMAX White Night',
        message: 'Suất 21:00 có quà tặng poster premium cho thành viên Gold.',
        active: true,
      ),
    ];
  }

  static VnpayConfig vnpayConfig() {
    return const VnpayConfig(
      terminalId: 'CINELUXE01',
      secretKey: 'sandbox-hmac-sha512-secret',
      environment: 'Sandbox',
    );
  }
}
