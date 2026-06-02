import '../models/app_models.dart';

String bookingStatusLabel(BookingStatus status) {
  return switch (status) {
    BookingStatus.active => 'Sắp chiếu',
    BookingStatus.used => 'Đã xem',
    BookingStatus.cancelled => 'Đã hủy',
    BookingStatus.refunded => 'Đã hoàn tiền',
  };
}

String paymentStatusLabel(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.processing => 'Đang xử lý',
    PaymentStatus.success => 'Thành công',
    PaymentStatus.failed => 'Thất bại',
    PaymentStatus.refunded => 'Đã hoàn tiền',
  };
}

String roomStatusLabel(RoomStatus status) {
  return switch (status) {
    RoomStatus.ready => 'Sẵn sàng',
    RoomStatus.maintenance => 'Bảo trì',
  };
}

String seatTypeLabel(SeatType type) {
  return switch (type) {
    SeatType.standard => 'Ghế thường',
    SeatType.vip => 'Ghế VIP',
    SeatType.couple => 'Ghế đôi',
  };
}

String roleLabel(UserRole role) {
  return switch (role) {
    UserRole.customer => 'Khách hàng',
    UserRole.staff => 'Nhân viên',
    UserRole.admin => 'Quản trị viên',
  };
}
