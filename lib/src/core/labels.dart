import '../models/app_models.dart';

String bookingStatusLabel(
  BookingStatus status, {
  AppLanguage language = AppLanguage.vi,
}) {
  final vi = switch (status) {
    BookingStatus.active => 'Sắp chiếu',
    BookingStatus.used => 'Đã xem',
    BookingStatus.cancelled => 'Đã hủy',
    BookingStatus.refunded => 'Đã hoàn tiền',
  };
  final en = switch (status) {
    BookingStatus.active => 'Active',
    BookingStatus.used => 'Used',
    BookingStatus.cancelled => 'Cancelled',
    BookingStatus.refunded => 'Refunded',
  };
  return language == AppLanguage.vi ? vi : en;
}

String paymentStatusLabel(
  PaymentStatus status, {
  AppLanguage language = AppLanguage.vi,
}) {
  final vi = switch (status) {
    PaymentStatus.processing => 'Đang xử lý',
    PaymentStatus.success => 'Thành công',
    PaymentStatus.failed => 'Thất bại',
    PaymentStatus.refunded => 'Đã hoàn tiền',
  };
  final en = switch (status) {
    PaymentStatus.processing => 'Processing',
    PaymentStatus.success => 'Success',
    PaymentStatus.failed => 'Failed',
    PaymentStatus.refunded => 'Refunded',
  };
  return language == AppLanguage.vi ? vi : en;
}

String roomStatusLabel(
  RoomStatus status, {
  AppLanguage language = AppLanguage.vi,
}) {
  final vi = switch (status) {
    RoomStatus.ready => 'Sẵn sàng',
    RoomStatus.maintenance => 'Bảo trì',
  };
  final en = switch (status) {
    RoomStatus.ready => 'Ready',
    RoomStatus.maintenance => 'Maintenance',
  };
  return language == AppLanguage.vi ? vi : en;
}

String seatTypeLabel(SeatType type, {AppLanguage language = AppLanguage.vi}) {
  final vi = switch (type) {
    SeatType.standard => 'Ghế thường',
    SeatType.vip => 'Ghế VIP',
    SeatType.couple => 'Ghế đôi',
  };
  final en = switch (type) {
    SeatType.standard => 'Standard',
    SeatType.vip => 'VIP',
    SeatType.couple => 'Couple',
  };
  return language == AppLanguage.vi ? vi : en;
}

String roleLabel(UserRole role, {AppLanguage language = AppLanguage.vi}) {
  final vi = switch (role) {
    UserRole.customer => 'Khách hàng',
    UserRole.staff => 'Nhân viên',
    UserRole.admin => 'Quản trị viên',
  };
  final en = switch (role) {
    UserRole.customer => 'Customer',
    UserRole.staff => 'Staff',
    UserRole.admin => 'Admin',
  };
  return language == AppLanguage.vi ? vi : en;
}
