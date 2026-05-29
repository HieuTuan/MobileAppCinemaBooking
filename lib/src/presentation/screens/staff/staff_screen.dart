part of '../../../app.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({
    super.key,
    required this.user,
    required this.bookings,
    required this.onVerify,
    required this.onLogout,
  });

  final DemoUser user;
  final List<Booking> bookings;
  final ValueChanged<String> onVerify;
  final VoidCallback onLogout;

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  String _query = '';

  Booking? get _match {
    if (_query.trim().isEmpty) return null;
    final needle = _query.toLowerCase().trim();
    return widget.bookings.where((booking) {
      return booking.id.toLowerCase().contains(needle) ||
          booking.customerName.toLowerCase().contains(needle);
    }).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;
    return Scaffold(
      appBar: _CineAppBar(
        title: 'Cua soat ve thong minh',
        user: widget.user,
        onLogout: widget.onLogout,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.qr_code_scanner),
              labelText: 'Ma ve, QR hoac ten khach',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          if (match != null)
            _VerifyCard(
              booking: match,
              onVerify: () => widget.onVerify(match.id),
            ),
          if (_query.isNotEmpty && match == null)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Khong tim thay ve phu hop.',
                style: TextStyle(color: Color(0xFFF87171)),
              ),
            ),
          const SizedBox(height: 24),
          const _SectionTitle(icon: Icons.history, title: 'Ve dat gan day'),
          const SizedBox(height: 12),
          ...widget.bookings.map((booking) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BookingTile(
                booking: booking,
                onTap: () => setState(() => _query = booking.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}
