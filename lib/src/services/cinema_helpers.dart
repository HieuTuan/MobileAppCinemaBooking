part of '../app.dart';

IconData _roleIcon(UserRole role) {
  return switch (role) {
    UserRole.customer => Icons.workspace_premium_outlined,
    UserRole.admin => Icons.admin_panel_settings_outlined,
    UserRole.staff => Icons.badge_outlined,
  };
}

String _roleLabel(UserRole role) {
  return switch (role) {
    UserRole.customer => 'Khach VIP',
    UserRole.admin => 'Admin',
    UserRole.staff => 'Staff',
  };
}

Color _seatColor(String seat) {
  final row = seat.codeUnitAt(0);
  if (row >= 69) return _velvet;
  if (row >= 67) return _goldDeep;
  return const Color(0xFF3F3F46);
}

int _seatPrice(String seat) {
  final row = seat.codeUnitAt(0);
  if (row >= 69) return 260000;
  if (row >= 67) return 190000;
  return 120000;
}

Color _statusColor(BookingStatus status) {
  return switch (status) {
    BookingStatus.active => _emeraldDeep,
    BookingStatus.used => const Color(0xFF71717A),
    BookingStatus.cancelled => const Color(0xFFDC2626),
  };
}
