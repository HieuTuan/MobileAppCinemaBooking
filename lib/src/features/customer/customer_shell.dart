import 'package:flutter/material.dart';

import '../../shared/widgets/luxury_scaffold.dart';
import '../../state/cinema_store.dart';
import 'movie_list_screen.dart';
import 'profile_screen.dart';
import 'api_tickets_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key, required this.store});

  final CinemaStore store;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      MovieListScreen(store: widget.store),
      ApiTicketsScreen(store: widget.store),
      ProfileScreen(store: widget.store),
    ];
    return LuxuryScaffold(
      title: ['CineLuxe', 'Vé của tôi', 'Hồ sơ'][_index],
      actions: [
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: widget.store.logout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_filter_outlined),
            selectedIcon: Icon(Icons.movie_filter_rounded),
            label: 'Phim',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number_rounded),
            label: 'Vé',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ],
      ),
      child: IndexedStack(index: _index, children: screens),
    );
  }
}
