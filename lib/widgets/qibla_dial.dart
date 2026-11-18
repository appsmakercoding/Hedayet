import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// কম্পাসের গোল ডায়াল। ডায়াল ফোনের দিকের উল্টো দিকে ঘোরে, ফলে "উ" সবসময় উত্তরের দিকে থাকে।
/// কালো ঘনক = কাবা শরীফ। ওপরের স্থির ত্রিভুজ ফোন যেদিকে মুখ করে আছে সেদিক।
/// কাবা ঘনক ওপরে এলে আপনি কিবলার দিকে ফিরে আছেন।
class QiblaDial extends StatelessWidget {
  final double size;
  final double heading;
  final double qibla;
  final bool aligned;
  final bool active;

  const QiblaDial({
    super.key,
    required this.size,
    required this.heading,
    required this.qibla,
    this.aligned = false,
    this.active = true,
  });

  Alignment _at(double deg, double radius) {
    final a = deg * math.pi / 180.0;
    return Alignment(math.sin(a) * radius, -math.cos(a) * radius);
  }

  @override
  Widget build(BuildContext context) {
    final accent = aligned ? Colors.lightGreenAccent : AppColors.gold;
    final letter = TextStyle(color: Colors.white, fontSize: size * 0.1, fontWeight: FontWeight.bold);
    final cube = size * 0.15;

    return Opacity(
      opacity: active ? 1.0 : 0.55,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
                border: Border.all(color: accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
            Transform.rotate(
              angle: -heading * math.pi / 180.0,
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: _at(0, 0.80),
                      child: Text('উ', style: letter.copyWith(color: Colors.redAccent.shade100)),
                    ),
                    Align(alignment: _at(90, 0.80), child: Text('পূ', style: letter)),
                    Align(alignment: _at(180, 0.80), child: Text('দ', style: letter)),
                    Align(alignment: _at(270, 0.80), child: Text('প', style: letter)),
                    Align(
                      alignment: _at(qibla, 0.58),
                      child: Container(
                        width: cube,
                        height: cube,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: accent, width: 1.5),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: qibla * math.pi / 180.0,
                      child: Icon(Icons.navigation_rounded, size: size * 0.30, color: accent),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Icon(Icons.arrow_drop_down_rounded, size: size * 0.24, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
