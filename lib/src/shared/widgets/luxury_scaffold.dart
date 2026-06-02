import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class LuxuryScaffold extends StatelessWidget {
  const LuxuryScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions = const [],
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final Widget child;
  final String? title;
  final List<Widget> actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(
                title!,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: actions,
            ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          const _PearlBackground(),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _PearlBackground extends StatelessWidget {
  const _PearlBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PearlPainter(), size: Size.infinite);
  }
}

class _PearlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, AppColors.pearl, AppColors.ivory],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42)
      ..color = AppColors.gold.withValues(alpha: .16);
    canvas.drawCircle(Offset(size.width * .88, size.height * .12), 110, glow);
    canvas.drawCircle(Offset(size.width * .1, size.height * .78), 130, glow);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .7);
    for (var i = 0; i < 9; i++) {
      final y = size.height * (i / 8);
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 20) {
        path.lineTo(x, y + math.sin((x / 80) + i) * 8);
      }
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
