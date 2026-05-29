part of '../../../app.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.movie,
    required this.customerName,
    required this.onBook,
  });

  final Movie movie;
  final String customerName;
  final ValueChanged<Booking> onBook;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  Showtime _showtime = _showtimes.first;
  final Set<String> _selectedSeats = {};
  final Set<String> _selectedFood = {};

  int get _seatTotal =>
      _selectedSeats.fold(0, (sum, seat) => sum + _seatPrice(seat));
  int get _foodTotal =>
      _selectedFood.fold(0, (sum, item) => sum + (_foodMenu[item] ?? 0));
  int get _discount =>
      widget.movie.vipGold ? ((_seatTotal + _foodTotal) * .2).round() : 0;
  int get _total => _seatTotal + _foodTotal - _discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title),
        backgroundColor: _surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _SectionTitle(
            icon: Icons.apartment_outlined,
            title: 'Chon rap va suat chieu',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _showtimes.map((showtime) {
              final selected = showtime.id == _showtime.id;
              return ChoiceChip(
                selected: selected,
                selectedColor: _gold,
                labelStyle: TextStyle(color: selected ? _obsidian : _stone),
                label: Text(
                  '${showtime.branch}\n${showtime.date} - ${showtime.time} - ${showtime.hall}',
                ),
                onSelected: (_) => setState(() => _showtime = showtime),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            icon: Icons.event_seat_outlined,
            title: 'So do ghe da thuong hang',
          ),
          const SizedBox(height: 12),
          const Center(child: _ScreenGlow()),
          const SizedBox(height: 20),
          _SeatMap(selectedSeats: _selectedSeats, onToggle: _toggleSeat),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _Legend(color: Color(0xFF3F3F46), label: 'Classic'),
              _Legend(color: _goldDeep, label: 'Prestige VIP'),
              _Legend(color: _velvet, label: 'Royal Velvet'),
              _Legend(color: _emerald, label: 'Dang chon'),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
            icon: Icons.room_service_outlined,
            title: 'Am thuc hoang gia',
          ),
          const SizedBox(height: 10),
          ..._foodMenu.entries.map((entry) {
            return CheckboxListTile(
              value: _selectedFood.contains(entry.key),
              title: Text(entry.key),
              subtitle: Text(
                _currency.format(entry.value),
                style: const TextStyle(color: _muted),
              ),
              activeColor: _gold,
              onChanged: (_) => setState(() {
                _selectedFood.contains(entry.key)
                    ? _selectedFood.remove(entry.key)
                    : _selectedFood.add(entry.key);
              }),
            );
          }),
          const SizedBox(height: 16),
          _PriceSummary(
            seatTotal: _seatTotal,
            foodTotal: _foodTotal,
            discount: _discount,
            total: _total,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _selectedSeats.isEmpty ? null : _finish,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('TIEP TUC THANH TOAN'),
          ),
        ],
      ),
    );
  }

  void _toggleSeat(String seat) {
    setState(() {
      _selectedSeats.contains(seat)
          ? _selectedSeats.remove(seat)
          : _selectedSeats.add(seat);
    });
  }

  void _finish() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentTransferScreen(
          movie: widget.movie,
          customerName: widget.customerName,
          showtime: _showtime,
          seats: _selectedSeats.toList()..sort(),
          food: _selectedFood.toList()..sort(),
          total: _total,
          onPaid: widget.onBook,
        ),
      ),
    );
  }
}
