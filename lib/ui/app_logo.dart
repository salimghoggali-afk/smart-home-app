import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// The app mark: a house outline with a warm lit window.
///
/// [glow] goes from 0 to 1 and lights the window, used by the splash animation.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120, this.glow = 1});

  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LogoPainter(glow.clamp(0, 1).toDouble())),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.glow);
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;

    // Rounded tile with a teal gradient.
    final tile = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.28));
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF19C2A8), Color(0xFF0A6F7A)],
        ).createShader(rect),
    );

    // House outline.
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final house = Path()
      ..moveTo(s * 0.24, s * 0.48)
      ..lineTo(s * 0.50, s * 0.25)
      ..lineTo(s * 0.76, s * 0.48)
      ..moveTo(s * 0.31, s * 0.43)
      ..lineTo(s * 0.31, s * 0.74)
      ..lineTo(s * 0.69, s * 0.74)
      ..lineTo(s * 0.69, s * 0.43);
    canvas.drawPath(house, stroke);

    // Lit window with a soft halo.
    final c = Offset(s * 0.50, s * 0.56);
    final r = s * 0.085;
    if (glow > 0) {
      canvas.drawCircle(
        c,
        r * (1.6 + glow * 1.4),
        Paint()
          ..color = AppColors.warm.withValues(alpha: 0.35 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06),
      );
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Color.lerp(Colors.white.withValues(alpha: 0.35),
            AppColors.warm, glow)!,
    );

    // Small signal arcs on the roof: the "smart" part.
    final arc = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * glow)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.04
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 2; i++) {
      final rr = s * 0.07 * i;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(s * 0.50, s * 0.21), radius: rr),
        -math.pi * 0.78,
        math.pi * 0.56,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.glow != glow;
}
