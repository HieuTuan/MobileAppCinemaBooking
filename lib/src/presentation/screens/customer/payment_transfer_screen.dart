part of '../../../app.dart';

class PaymentTransferScreen extends StatelessWidget {
  const PaymentTransferScreen({
    super.key,
    required this.movie,
    required this.customerName,
    required this.showtime,
    required this.seats,
    required this.food,
    required this.total,
    required this.onPaid,
  });

  final Movie movie;
  final String customerName;
  final Showtime showtime;
  final List<String> seats;
  final List<String> food;
  final int total;
  final ValueChanged<Booking> onPaid;

  @override
  Widget build(BuildContext context) {
    final transferCode = 'CVS-${movie.id}-${seats.join('')}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toan chuyen khoan'),
        backgroundColor: _surface,
      ),
      body: Stack(
        children: [
          const _CinematicBackdrop(),
          ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _PremiumBankCard(
                movie: movie,
                amount: total,
                transferCode: transferCode,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _surface.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _gold.withValues(alpha: .22)),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data:
                          'BANK:CINEVERSE CLUB|ACC:1900200629|AMOUNT:$total|MSG:$transferCode',
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle(
                      icon: Icons.account_balance_outlined,
                      title: 'Thong tin chuyen khoan',
                    ),
                    const SizedBox(height: 12),
                    const _InfoLine(
                      label: 'Ngan hang',
                      value: 'Cineverse Bank',
                    ),
                    const _InfoLine(
                      label: 'So tai khoan',
                      value: '1900 2006 29',
                    ),
                    const _InfoLine(
                      label: 'Chu tai khoan',
                      value: 'CINEVERSE CLUB JSC',
                    ),
                    _InfoLine(label: 'Noi dung', value: transferCode),
                    _InfoLine(label: 'So tien', value: _currency.format(total)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _TransferOrderSummary(
                movie: movie,
                showtime: showtime,
                seats: seats,
                food: food,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _confirm(context),
                icon: const Icon(Icons.verified_outlined),
                label: const Text('TOI DA CHUYEN KHOAN - TAO VE QR'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext context) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final random = Random().nextInt(899999) + 100000;
    final booking = Booking(
      id: 'CVS-$random',
      customerName: customerName,
      movieTitle: movie.title,
      showtime: showtime,
      seats: seats,
      food: food,
      total: total,
      createdAt: DateTime.now(),
    );
    onPaid(booking);
    navigator.pop();
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Thanh toan thanh cong. Da tao ve ${booking.id}.'),
      ),
    );
  }
}

class _PremiumBankCard extends StatelessWidget {
  const _PremiumBankCard({
    required this.movie,
    required this.amount,
    required this.transferCode,
  });

  final Movie movie;
  final int amount;
  final String transferCode;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0012)
            ..rotateX((1 - value) * .22)
            ..rotateY((1 - value) * -.16),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        height: 210,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2114), _surface, Color(0xFF091F19)],
          ),
          border: Border.all(color: _gold.withValues(alpha: .42)),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: .18),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.local_movies_outlined, color: _gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cineverse Transfer Pass',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(Icons.contactless_outlined, color: _muted),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  transferCode,
                  style: const TextStyle(
                    color: _muted,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
            Text(
              _currency.format(amount),
              style: const TextStyle(
                color: _emerald,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferOrderSummary extends StatelessWidget {
  const _TransferOrderSummary({
    required this.movie,
    required this.showtime,
    required this.seats,
    required this.food,
  });

  final Movie movie;
  final Showtime showtime;
  final List<String> seats;
  final List<String> food;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        children: [
          _InfoLine(label: 'Phim', value: movie.title),
          _InfoLine(label: 'Rap', value: showtime.branch),
          _InfoLine(label: 'Phong', value: showtime.hall),
          _InfoLine(
            label: 'Suat',
            value: '${showtime.date} - ${showtime.time}',
          ),
          _InfoLine(label: 'Ghe', value: seats.join(', ')),
          _InfoLine(
            label: 'Combo',
            value: food.isEmpty ? 'Khong chon' : food.join(', '),
          ),
        ],
      ),
    );
  }
}
