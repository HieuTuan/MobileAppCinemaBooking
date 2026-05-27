import 'package:cine_book/features/booking/data/models/showtime_model.dart';

class OrderModel {
  final String id;
  final ShowtimeModel showtime;
  final List<String> seatIds;
  final int subtotal;
  final int discount;
  final int total;
  final String status; // PENDING, PAID, CANCELLED

  OrderModel({
    required this.id,
    required this.showtime,
    required this.seatIds,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.status = 'PENDING',
  });
}
