import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme.dart';

/// The EPay mark drawn in code — crisp at any size, no asset decode needed.
class EpayLogo extends StatelessWidget {
  final double size;
  final bool rounded;
  final bool showShadow;

  const EpayLogo({
    super.key,
    this.size = 56,
    this.rounded = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sky, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(rounded ? size * 0.235 : 0),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.35),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: CustomPaint(painter: _EpayGlyphPainter()),
    );
  }
}

class _EpayGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100.0;
    final white = Paint()..color = Colors.white;
    final cyan = Paint()..color = AppColors.cyan;

    RRect bar(double x, double y, double w, double h) => RRect.fromRectAndRadius(
          Rect.fromLTWH(x * u, y * u, w * u, h * u),
          Radius.circular(h * u / 2),
        );

    // "E": spine + three bars
    canvas.drawRRect(bar(21, 26, 10.5, 48), white);
    canvas.drawRRect(bar(21, 26, 35, 10.5), white);
    canvas.drawRRect(bar(21, 44.75, 26, 10.5), white);
    canvas.drawRRect(bar(21, 63.5, 35, 10.5), white);

    // Rising arrow
    final a = Offset(60 * u, 73 * u);
    final tip = Offset(80 * u, 27 * u);
    final d = tip - a;
    final len = d.distance;
    final dir = Offset(d.dx / len, d.dy / len);
    final perp = Offset(-dir.dy, dir.dx);

    const headLen = 15.0;
    const headHalf = 9.5;
    const shaftW = 8.0;

    final shaftEnd = tip - dir * (headLen * 0.82 * u);
    canvas.drawLine(
      a,
      shaftEnd,
      Paint()
        ..color = AppColors.cyan
        ..strokeWidth = shaftW * u
        ..strokeCap = StrokeCap.round,
    );

    final hb = tip - dir * (headLen * u);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(hb.dx + perp.dx * headHalf * u, hb.dy + perp.dy * headHalf * u)
      ..lineTo(hb.dx - perp.dx * headHalf * u, hb.dy - perp.dy * headHalf * u)
      ..close();
    canvas.drawPath(path, cyan);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Horizontal lockup: mark + "EPay" wordmark.
class EpayWordmark extends StatelessWidget {
  final double height;
  final bool onDark;
  const EpayWordmark({super.key, this.height = 40, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EpayLogo(size: height, showShadow: !onDark),
        SizedBox(width: height * 0.26),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: height * 0.62,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
            children: [
              TextSpan(
                text: 'E',
                style: TextStyle(color: onDark ? AppColors.cyan : AppColors.sky),
              ),
              TextSpan(
                text: 'Pay',
                style: TextStyle(color: onDark ? Colors.white : AppColors.navy),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular avatar that falls back to the EPay mark.
class EpayAvatar extends StatelessWidget {
  final String? url;
  final double size;
  const EpayAvatar({super.key, this.url, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: 0,
        child: SizedBox(
          width: size * 0.62,
          height: size * 0.62,
          child: CustomPaint(painter: _MonoGlyphPainter()),
        ),
      ),
    );

    if (url == null || url!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _MonoGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100.0;
    final blue = Paint()..color = AppColors.primary;
    final cyan = Paint()..color = AppColors.sky;

    RRect bar(double x, double y, double w, double h) => RRect.fromRectAndRadius(
          Rect.fromLTWH(x * u, y * u, w * u, h * u),
          Radius.circular(h * u / 2),
        );

    canvas.drawRRect(bar(14, 20, 13, 60), blue);
    canvas.drawRRect(bar(14, 20, 42, 13), blue);
    canvas.drawRRect(bar(14, 43.5, 32, 13), blue);
    canvas.drawRRect(bar(14, 67, 42, 13), blue);

    final a = Offset(64 * u, 78 * u);
    final tip = Offset(88 * u, 24 * u);
    final d = tip - a;
    final dir = Offset(d.dx / d.distance, d.dy / d.distance);
    final perp = Offset(-dir.dy, dir.dx);
    canvas.drawLine(
      a,
      tip - dir * (14 * u),
      Paint()
        ..color = AppColors.sky
        ..strokeWidth = 9 * u
        ..strokeCap = StrokeCap.round,
    );
    final hb = tip - dir * (17 * u);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(hb.dx + perp.dx * 11 * u, hb.dy + perp.dy * 11 * u)
        ..lineTo(hb.dx - perp.dx * 11 * u, hb.dy - perp.dy * 11 * u)
        ..close(),
      cyan,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated splash/auth hero: the mark with a soft pulsing halo.
class PulsingLogo extends StatefulWidget {
  final double size;
  const PulsingLogo({super.key, this.size = 92});

  @override
  State<PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<PulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          padding: EdgeInsets.all(widget.size * 0.18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.sky.withValues(alpha: 0.06 + 0.07 * t),
          ),
          child: Transform.scale(scale: 0.97 + 0.03 * t, child: child),
        );
      },
      child: EpayLogo(size: widget.size),
    );
  }
}

/// Small decorative sparkle used on reward dialogs.
class RewardBurst extends StatelessWidget {
  final double size;
  const RewardBurst({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _BurstPainter()));
}

class _BurstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final p = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.035;
    for (var i = 0; i < 12; i++) {
      final ang = (i / 12) * 2 * math.pi;
      final inner = r * (i.isEven ? 0.55 : 0.68);
      final outer = r * (i.isEven ? 0.95 : 0.82);
      p.color = (i.isEven ? AppColors.gold : AppColors.sky).withValues(alpha: 0.85);
      canvas.drawLine(
        c + Offset(math.cos(ang), math.sin(ang)) * inner,
        c + Offset(math.cos(ang), math.sin(ang)) * outer,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
