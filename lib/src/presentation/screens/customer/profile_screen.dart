part of '../../../app.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user, required this.bookings});

  final DemoUser user;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final userBookings = bookings
        .where((booking) => booking.customerName == user.name)
        .toList();
    final spent = userBookings.fold<int>(
      0,
      (sum, booking) => sum + booking.total,
    );

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _gold.withValues(alpha: .24)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: _gold,
                foregroundColor: _obsidian,
                child: Text(
                  user.name.trim().isEmpty ? 'CV' : user.name.trim()[0],
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              _StatusPill(
                color: user.role == UserRole.customer ? _gold : _emeraldDeep,
                textColor: user.role == UserRole.customer ? _obsidian : _stone,
                label: user.memberTier,
              ),
              const Divider(height: 34),
              _InfoLine(label: 'Email', value: user.email),
              _InfoLine(label: 'So dien thoai', value: user.phone),
              _InfoLine(
                label: 'Chi nhanh yeu thich',
                value: user.favoriteBranch,
              ),
              _InfoLine(label: 'Ngay tham gia', value: user.joinedDate),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ProfileMetric(
                icon: Icons.confirmation_number_outlined,
                label: 'Ve da dat',
                value: '${userBookings.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileMetric(
                icon: Icons.payments_outlined,
                label: 'Chi tieu',
                value: _currency.format(spent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle(
          icon: Icons.history_outlined,
          title: 'Hoat dong gan day',
        ),
        const SizedBox(height: 12),
        if (userBookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Tai khoan chua co ve nao. Hay chon mot suat chieu VIP dau tien.',
              style: TextStyle(color: _muted),
            ),
          )
        else
          ...userBookings
              .take(5)
              .map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BookingTile(
                    booking: booking,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TicketDetailScreen(booking: booking),
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _gold),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
