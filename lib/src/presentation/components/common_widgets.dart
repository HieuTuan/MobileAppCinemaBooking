part of '../../app.dart';

class _CineAppBar extends AppBar {
  _CineAppBar({
    required String title,
    required DemoUser user,
    required VoidCallback onLogout,
  }) : super(
         title: Text(title),
         backgroundColor: _surface,
         actions: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 8),
             child: Center(
               child: Text(
                 _roleLabel(user.role),
                 style: const TextStyle(
                   color: _gold,
                   fontWeight: FontWeight.w800,
                 ),
               ),
             ),
           ),
           IconButton(
             onPressed: onLogout,
             icon: const Icon(Icons.logout),
             tooltip: 'Dang xuat',
           ),
         ],
       );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _gold),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({
    required this.seatTotal,
    required this.foodTotal,
    required this.discount,
    required this.total,
  });

  final int seatTotal;
  final int foodTotal;
  final int discount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gold.withValues(alpha: .2)),
      ),
      child: Column(
        children: [
          _InfoLine(label: 'Ghe', value: _currency.format(seatTotal)),
          _InfoLine(label: 'Am thuc', value: _currency.format(foodTotal)),
          _InfoLine(
            label: 'VIP Gold 20%',
            value: '-${_currency.format(discount)}',
          ),
          const Divider(),
          _InfoLine(
            label: 'Tong thanh toan',
            value: _currency.format(total),
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: _muted)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
                color: strong ? _gold : _stone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.color,
    required this.textColor,
    required this.label,
  });

  final Color color;
  final Color textColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _muted)),
      ],
    );
  }
}

class _ScreenGlow extends StatelessWidget {
  const _ScreenGlow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 280,
          height: 5,
          decoration: BoxDecoration(
            color: _gold,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: .6),
                blurRadius: 18,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'MAN HINH',
          style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 1.2),
        ),
      ],
    );
  }
}

class _CinematicBackdrop extends StatefulWidget {
  const _CinematicBackdrop();

  @override
  State<_CinematicBackdrop> createState() => _CinematicBackdropState();
}

class _CinematicBackdropState extends State<_CinematicBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _CinemaBackdropPainter(progress: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _CinemaBackdropPainter extends CustomPainter {
  const _CinemaBackdropPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = _obsidian;
    canvas.drawRect(Offset.zero & size, base);

    final lightPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              _gold.withValues(alpha: .18),
              _gold.withValues(alpha: .05),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * (.18 + .08 * sin(progress * pi * 2)),
                size.height * .2,
              ),
              radius: size.shortestSide * .58,
            ),
          );
    canvas.drawRect(Offset.zero & size, lightPaint);

    final emeraldPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              _emerald.withValues(alpha: .12),
              _emerald.withValues(alpha: .035),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * (.88 + .05 * cos(progress * pi * 2)),
                size.height * .72,
              ),
              radius: size.shortestSide * .46,
            ),
          );
    canvas.drawRect(Offset.zero & size, emeraldPaint);

    final beamPaint = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 9; i++) {
      final y = size.height * ((i / 8 + progress * .18) % 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 48), beamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CinemaBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
