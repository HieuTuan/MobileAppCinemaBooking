import 'package:cine_book/services/logout_service.dart';
import 'package:cine_book/src/core/app_theme.dart';
import 'package:cine_book/src/models/app_models.dart';
import 'package:cine_book/src/shared/widgets/glass_card.dart';
import 'package:cine_book/src/shared/widgets/luxury_scaffold.dart';
import 'package:cine_book/src/state/cinema_store.dart';
import 'package:flutter/material.dart';

import 'staff_customer_support_section.dart';
import 'staff_food_combo_section.dart';
import 'staff_refund_section.dart';
import 'staff_room_management_section.dart';
import 'staff_showtime_bookings_section.dart';
import 'staff_ticket_verification_section.dart';
import 'staff_withdrawal_section.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key, required this.store});

  final CinemaStore store;

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  Future<void> _handleLogout() async {
    await LogoutService.signOut(context: context, store: widget.store);
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.store.currentUser;
    return LuxuryScaffold(
      title: 'Bảng nhân viên',
      actions: [
        InkWell(
          onTap: _handleLogout,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _StaffHeader(user: staff),
          const SizedBox(height: 12),
          _StaffMetrics(store: widget.store),
          const SizedBox(height: 12),
          CollapsibleSection(
            title: 'Xác thực vé tại cổng',
            icon: Icons.qr_code_scanner_rounded,
            child: StaffTicketVerificationSection(store: widget.store, showTitle: false),
          ),
          CollapsibleSection(
            title: 'Xử lý hoàn tiền',
            icon: Icons.currency_exchange_rounded,
            child: const StaffRefundSection(showTitle: false),
          ),
          CollapsibleSection(
            title: 'Xử lý rút tiền',
            icon: Icons.account_balance_rounded,
            child: const StaffWithdrawalSection(showTitle: false),
          ),
          CollapsibleSection(
            title: 'Trạng thái bắp nước',
            icon: Icons.fastfood_rounded,
            child: const StaffFoodComboSection(showTitle: false),
          ),
          CollapsibleSection(
            title: 'Hỗ trợ khách hàng tại quầy',
            icon: Icons.support_agent_rounded,
            child: StaffCustomerSupportSection(store: widget.store, showTitle: false),
          ),
          CollapsibleSection(
            title: 'Phòng chiếu và sự cố kỹ thuật',
            icon: Icons.meeting_room_rounded,
            child: StaffRoomManagementSection(store: widget.store, showTitle: false),
          ),
          CollapsibleSection(
            title: 'Danh sách đặt vé theo suất',
            icon: Icons.event_available_rounded,
            child: StaffShowtimeBookingsSection(store: widget.store, showTitle: false),
          ),
        ],
      ),
    );
  }
}

class CollapsibleSection extends StatelessWidget {
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: softShadow(0.05),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          leading: Icon(icon, color: const Color(0xFFF59E0B)),
          iconColor: AppColors.ink,
          collapsedIconColor: AppColors.muted,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            child,
          ],
        ),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.badge_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Nhân viên',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                if (user?.permissions.isEmpty ?? true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Tài khoản nội bộ Staff',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.muted,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final perm in user!.permissions)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withOpacity(0.25),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            perm,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                    ],
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
