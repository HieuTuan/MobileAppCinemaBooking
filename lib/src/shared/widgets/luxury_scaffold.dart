import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: title == null
            ? null
            : _PremiumAppBar(title: title!, actions: actions),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        body: Stack(
          children: [
            const _PearlBackground(),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}

class _PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PremiumAppBar({required this.title, required this.actions});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isBrand = title == 'CineLuxe';
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      height: preferredSize.height + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isBrand && Navigator.of(context).canPop())
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            const _BrandIcon(),
            const SizedBox(width: 10),
            const Flexible(
              child: _BrandWordmark(),
            ),
            const Spacer(),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: .4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_movies_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFF59E0B), Colors.white, Color(0xFFF59E0B)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: const Text(
        'CineLuxe',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
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
      ..color = AppColors.gold.withValues(alpha: .08);
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
