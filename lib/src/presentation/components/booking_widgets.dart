part of '../../app.dart';

class _SeatMap extends StatelessWidget {
  const _SeatMap({required this.selectedSeats, required this.onToggle});

  final Set<String> selectedSeats;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: GridView.builder(
          itemCount: 48,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final row = String.fromCharCode(65 + index ~/ 8);
            final col = index % 8 + 1;
            final seat = '$row$col';
            final selected = selectedSeats.contains(seat);
            return Material(
              color: selected ? _emerald : _seatColor(seat),
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onToggle(seat),
                child: Center(
                  child: Text(
                    seat,
                    style: TextStyle(
                      color: selected || row.codeUnitAt(0) >= 67
                          ? Colors.white
                          : _stone,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
