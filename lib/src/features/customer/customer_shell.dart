import 'package:cine_book/services/device_service.dart';
import 'package:cine_book/services/push_notification_handler.dart';
import 'package:cine_book/src/shared/widgets/luxury_scaffold.dart';
import 'package:cine_book/src/state/cinema_store.dart';
import 'package:flutter/material.dart';

import 'api_tickets_screen.dart';
import 'movie_list_screen.dart';
import 'profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key, required this.store});

  final CinemaStore store;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;
  final _deviceService = DeviceService();

  Future<void> _handleLogout() async {
    await _deviceService.unregisterDevice();
    final token = await PushNotificationHandler.instance.getToken();
    if (token != null) {
      await _deviceService.refreshToken(
        newDeviceToken: token,
        platform: PushNotificationHandler.instance.platform,
      );
    }
    if (mounted) widget.store.logout();
  }

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
          onPressed: _handleLogout,
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
