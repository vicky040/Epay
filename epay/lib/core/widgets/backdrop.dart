import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme.dart';

/// The drifting blue "constellation" field used behind every screen.
class ConstellationBackdrop extends StatefulWidget {
  final Widget child;
  final int nodes;
  final bool animate;

  const ConstellationBackdrop({
    super.key,
    required this.child,
    this.nodes = 26,
    this.animate = true,
  });

  @override
  State<ConstellationBackdrop> createState() => _ConstellationBackdropState();
}

class _ConstellationBackdropState extends State<ConstellationBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  late final List<_Node> _n;

  @override
  void initState() {
    super.initState();
    final r = math.Random(7);
    _n = List.generate(
      widget.nodes,
      (_) => _Node(
        x: r.nextDouble(),
        y: r.nextDouble(),
        dx: (r.nextDouble() - 0.5) * 0.06,
        dy: (r.nextDouble() - 0.5) * 0.06,
        r: 1.4 + r.nextDouble() * 2.4,
        bright: r.nextDouble() > 0.55,
      ),
    );
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.screenGradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) =>
                    CustomPaint(painter: _ConstellationPainter(_n, _c.value)),
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _Node {
  double x, y, dx, dy, r;
  bool bright;
  _Node({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.r,
    required this.bright,
  });
}

class _ConstellationPainter extends CustomPainter {
  final List<_Node> nodes;
  final double t;
  _ConstellationPainter(this.nodes, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final pts = <Offset>[];
    for (final n in nodes) {
      // gentle ping-pong drift
      final ox = math.sin((t * 2 * math.pi) + n.x * 6) * n.dx;
      final oy = math.cos((t * 2 * math.pi) + n.y * 6) * n.dy;
      pts.add(Offset((n.x + ox) * size.width, (n.y + oy) * size.height));
    }

    final line = Paint()
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    const maxD = 150.0;
    for (var i = 0; i < pts.length; i++) {
      for (var j = i + 1; j < pts.length; j++) {
        final d = (pts[i] - pts[j]).distance;
        if (d < maxD) {
          line.color = AppColors.sky.withValues(alpha: 0.18 * (1 - d / maxD));
          canvas.drawLine(pts[i], pts[j], line);
        }
      }
    }

    for (var i = 0; i < pts.length; i++) {
      final n = nodes[i];
      final c = n.bright ? AppColors.sky : AppColors.primary;
      canvas.drawCircle(
        pts[i],
        n.r * 2.6,
        Paint()..color = c.withValues(alpha: 0.12),
      );
      canvas.drawCircle(pts[i], n.r, Paint()..color = c.withValues(alpha: 0.75));
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) => old.t != t;
}

/// Rounded header panel with the brand gradient — used on the Home / Account
/// hero areas.
class GradientHeader extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  const GradientHeader({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = const EdgeInsets.fromLTRB(18, 0, 18, 22),
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        ),
      ),
      child: SafeArea(bottom: false, child: child),
    );
  }
}
