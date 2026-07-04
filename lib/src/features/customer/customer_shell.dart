import 'package:cine_book/services/logout_service.dart';
import 'package:cine_book/src/core/app_theme.dart';
import 'package:cine_book/src/shared/widgets/luxury_scaffold.dart';
import 'package:cine_book/src/state/cinema_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  int _ticketsRefreshToken = 0;

  Future<void> _handleLogout() async {
    await LogoutService.signOut(context: context, store: widget.store);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.store.isLoggedIn;
    final screens = [
      MovieListScreen(store: widget.store),
      isLoggedIn
          ? ApiTicketsScreen(
              store: widget.store,
              refreshToken: _ticketsRefreshToken,
            )
          : _GuestAuthPanel(
              icon: Icons.confirmation_number_outlined,
              title: 'Vé của tôi',
              subtitle:
                  'Đăng nhập để xem vé đã đặt, mã QR và lịch sử giao dịch.',
              onLogin: () => context.go('/auth'),
              onRegister: () => context.go('/auth?mode=register'),
            ),
      isLoggedIn
          ? ProfileScreen(store: widget.store)
          : _GuestAuthPanel(
              icon: Icons.person_outline_rounded,
              title: 'Hồ sơ thành viên',
              subtitle:
                  'Tạo tài khoản để tích điểm, lưu thông tin đặt vé và nhận ưu đãi.',
              onLogin: () => context.go('/auth'),
              onRegister: () => context.go('/auth?mode=register'),
            ),
    ];
    return LuxuryScaffold(
      title: ['CineLuxe', 'Vé của tôi', 'Hồ sơ'][_index],
      actions: isLoggedIn ? _loggedInActions() : _guestActions(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
            if (value == 1 && isLoggedIn) {
              _ticketsRefreshToken++;
            }
          });
        },
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

  List<Widget> _loggedInActions() {
    return [
      IconButton(
        tooltip: 'Đăng xuất',
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout_rounded),
      ),
    ];
  }

  List<Widget> _guestActions(BuildContext context) {
    return [
      TextButton.icon(
        onPressed: () => context.go('/auth'),
        icon: const Icon(Icons.login_rounded, size: 18),
        label: const Text('Đăng nhập'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilledButton.icon(
          onPressed: () => context.go('/auth?mode=register'),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('Đăng ký'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
            minimumSize: const Size(40, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    ];
  }
}

class _GuestAuthPanel extends StatelessWidget {
  const _GuestAuthPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onLogin,
    required this.onRegister,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.gold, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onLogin,
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Đăng nhập'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRegister,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Đăng ký'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
