part of '../../../app.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({
    super.key,
    required this.user,
    required this.movies,
    required this.bookings,
    required this.onBook,
    required this.onLogout,
  });

  final DemoUser user;
  final List<Movie> movies;
  final List<Booking> bookings;
  final ValueChanged<Booking> onBook;
  final VoidCallback onLogout;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      MovieLounge(
        movies: widget.movies,
        customerName: widget.user.name,
        onBook: widget.onBook,
      ),
      TicketWallet(bookings: widget.bookings),
      AiConcierge(movies: widget.movies),
      ProfileScreen(user: widget.user, bookings: widget.bookings),
    ];

    return Scaffold(
      appBar: _CineAppBar(
        title: 'Cineverse Club',
        user: widget.user,
        onLogout: widget.onLogout,
      ),
      body: Stack(children: [const _CinematicBackdrop(), pages[_tab]]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: _surface,
        indicatorColor: _gold.withValues(alpha: .22),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_filter_outlined),
            selectedIcon: Icon(Icons.movie_filter),
            label: 'Phim',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Ve',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Ho so',
          ),
        ],
        onDestinationSelected: (index) => setState(() => _tab = index),
      ),
    );
  }
}
