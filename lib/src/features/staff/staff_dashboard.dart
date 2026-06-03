import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/luxury_scaffold.dart';
import '../../state/cinema_store.dart';
import 'staff_customer_support_section.dart';
import 'staff_room_management_section.dart';
import 'staff_showtime_bookings_section.dart';
import 'staff_ticket_verification_section.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key, required this.store});

  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    final staff = store.currentUser;
    return LuxuryScaffold(
      title: 'Bảng nhân viên',
      actions: [
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: store.logout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _StaffHeader(user: staff),
          const SizedBox(height: 12),
          _StaffMetrics(store: store),
          StaffTicketVerificationSection(store: store),
          StaffCustomerSupportSection(store: store),
          StaffRoomManagementSection(store: store),
          StaffShowtimeBookingsSection(store: store),
        ],
      ),
    );
  }
}

class _StaffHeader extends StatelessWidget {
  const _StaffHeader({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.badge_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Nhân viên',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (user?.permissions.isEmpty ?? true)
                      ? 'Tài khoản nội bộ Staff'
                      : user!.permissions.join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffMetrics extends StatelessWidget {
  const _StaffMetrics({required this.store});

  final CinemaStore store;

  @override
  Widget build(BuildContext context) {
    final activeTickets = store.bookings
        .where((item) => item.status == BookingStatus.active)
        .length;
    final readyRooms = store.rooms
        .where((room) => room.status == RoomStatus.ready)
        .length;
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            label: 'Vé chờ soát',
            value: '$activeTickets',
            icon: Icons.qr_code_scanner_rounded,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricCard(
            label: 'Phòng sẵn sàng',
            value: '$readyRooms/${store.rooms.length}',
            icon: Icons.meeting_room_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}
