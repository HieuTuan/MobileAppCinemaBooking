import 'package:cine_book/services/logout_service.dart';
import 'package:cine_book/src/shared/widgets/luxury_scaffold.dart';
import 'package:cine_book/src/state/cinema_store.dart';
import 'package:flutter/material.dart';

import 'admin_account_section.dart';
import 'admin_content_section.dart';
import 'admin_finance_section.dart';
import 'admin_system_section.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.store});

  final CinemaStore store;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;

  Future<void> _handleLogout() async {
    await LogoutService.signOut(context: context, store: widget.store);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminContentSection(store: widget.store),
      AdminAccountSection(store: widget.store),
      AdminFinanceSection(store: widget.store),
      AdminSystemSection(store: widget.store),
    ];
    return LuxuryScaffold(
      title: 'Bảng quản trị',
      actions: [
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_creation_outlined),
            selectedIcon: Icon(Icons.movie_creation_rounded),
            label: 'Nội dung',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Tài khoản',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Tài chính',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Cấu hình',
          ),
        ],
      ),
      child: IndexedStack(index: _tab, children: pages),
    );
  }
}
