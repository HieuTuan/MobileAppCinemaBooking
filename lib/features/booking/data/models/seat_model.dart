enum SeatType { regular, vip, sweetbox, taken }

class SeatModel {
  final String id;
  final String label; // e.g., A1
  final SeatType type;
  bool isSelected;

  SeatModel({
    required this.id,
    required this.label,
    required this.type,
    this.isSelected = false,
  });
}
