import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// হেদায়েত লোগো: সবুজ বৃত্তের ভেতরে সোনালি অর্ধচন্দ্র ও তারা।
class HedayetLogo extends StatelessWidget {
  final double size;
  const HedayetLogo({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    canvas.drawCircle(c, r, Paint()..color = AppColors.gold.withOpacity(0.30));
    canvas.drawCircle(c, r * 0.92, Paint()..color = AppColors.darkGreen);
    canvas.drawCircle(
      c,
      r * 0.92,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.04,
    );

    final moon = Path()
      ..addOval(Rect.fromCircle(center: c.translate(-r * 0.08, 0), radius: r * 0.52));
    final cut = Path()
      ..addOval(Rect.fromCircle(center: c.translate(r * 0.14, -r * 0.06), radius: r * 0.43));
    final crescent = Path.combine(PathOperation.difference, moon, cut);
    canvas.drawPath(crescent, Paint()..color = AppColors.gold);

    final starCenter = c.translate(r * 0.30, -r * 0.02);
    canvas.drawPath(_star(starCenter, r * 0.16), Paint()..color = AppColors.gold);
  }

  Path _star(Offset center, double outer) {
    final inner = outer * 0.42;
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
