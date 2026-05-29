part of '../app.dart';

class CineverseApp extends StatefulWidget {
  const CineverseApp({super.key});

  @override
  State<CineverseApp> createState() => _CineverseAppState();
}

class _CineverseAppState extends State<CineverseApp> {
  final List<DemoUser> _users = [
    const DemoUser(
      name: 'Khach VIP',
      email: 'demo@cineverse.vnd',
      password: 'demo1234',
      role: UserRole.customer,
      phone: '0909 888 777',
      memberTier: 'VIP Gold',
      favoriteBranch: 'Royal Suite Tay Ho',
    ),
    const DemoUser(
      name: 'Quan tri rap',
      email: 'admin@cineverse.vnd',
      password: 'admin1234',
      role: UserRole.admin,
    ),
    const DemoUser(
      name: 'Nhan vien sanh',
      email: 'staff@cineverse.vnd',
      password: 'staff1234',
      role: UserRole.staff,
    ),
  ];

  late List<Movie> _movies;
  late List<Booking> _bookings;
  DemoUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _movies = _seedMovies();
    _bookings = [
      Booking(
        id: 'CVS-ELITE1',
        customerName: 'Minh Anh',
        movieTitle: 'Dune: Part Two',
        showtime: _showtimes.first,
        seats: const ['C4', 'C5'],
        food: const ['Gourmet Gold Popcorn'],
        total: 720000,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Booking(
        id: 'CVS-USED01',
        customerName: 'Bao Nguyen',
        movieTitle: 'Inside Out 2',
        showtime: _showtimes[2],
        seats: const ['A6', 'A7', 'A8'],
        food: const ['Family Royal Combo'],
        total: 630000,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: BookingStatus.used,
      ),
    ];
  }

  void _login(DemoUser user) {
    setState(() => _currentUser = user);
  }

  void _register(DemoUser user) {
    setState(() {
      _users.add(user);
      _currentUser = user;
    });
  }

  void _logout() {
    setState(() => _currentUser = null);
  }

  void _addBooking(Booking booking) {
    setState(() => _bookings.insert(0, booking));
  }

  void _saveMovie(Movie movie) {
    setState(() {
      final index = _movies.indexWhere((item) => item.id == movie.id);
      if (index == -1) {
        _movies.insert(0, movie);
      } else {
        _movies[index] = movie;
      }
    });
  }

  void _deleteMovie(String id) {
    setState(() => _movies.removeWhere((movie) => movie.id == id));
  }

  void _markBookingUsed(String id) {
    setState(() {
      final booking = _bookings.where((item) => item.id == id).firstOrNull;
      if (booking != null && booking.status == BookingStatus.active) {
        booking.status = BookingStatus.used;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cineverse Club',
      theme: _cineverseTheme(),
      home: _currentUser == null
          ? LoginScreen(users: _users, onLogin: _login, onRegister: _register)
          : switch (_currentUser!.role) {
              UserRole.customer => CustomerShell(
                user: _currentUser!,
                movies: _movies,
                bookings: _bookings,
                onBook: _addBooking,
                onLogout: _logout,
              ),
              UserRole.admin => AdminScreen(
                user: _currentUser!,
                movies: _movies,
                onSave: _saveMovie,
                onDelete: _deleteMovie,
                onLogout: _logout,
              ),
              UserRole.staff => StaffScreen(
                user: _currentUser!,
                bookings: _bookings,
                onVerify: _markBookingUsed,
                onLogout: _logout,
              ),
            },
    );
  }
}
