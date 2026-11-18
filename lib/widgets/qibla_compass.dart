import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../core/qibla.dart';
import '../data/prayer_data.dart' show bn;
import '../services/location_service.dart';
import 'qibla_dial.dart';

/// ফোনের কম্পাস সেন্সর ও GPS অবস্থান মিলিয়ে কিবলার দিক দেখায়।
/// [compact] = true হলে হোমপেজের ছোট রূপ (নিচে এক লাইনের লেখা)।
class QiblaCompass extends StatefulWidget {
  final double size;
  final bool compact;

  const QiblaCompass({super.key, required this.size, this.compact = false});

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass> {
  StreamSubscription<CompassEvent>? _sub;
  double? _heading;
  bool _noSensor = false;

  @override
  void initState() {
    super.initState();
    final stream = FlutterCompass.events;
    if (stream == null) {
      _noSensor = true;
    } else {
      _sub = stream.listen(
        _onEvent,
        onError: (Object _) {
          if (mounted) setState(() => _noSensor = true);
        },
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(CompassEvent event) {
    final h = event.heading;
    if (h == null) {
      if (mounted) setState(() => _noSensor = true);
      return;
    }
    final target = (h % 360.0 + 360.0) % 360.0;
    final old = _heading;
    double next;
    if (old == null) {
      next = target;
    } else {
      // কাঁপুনি কমাতে ধীরে ধীরে নতুন মানে সরে যায়
      final delta = ((target - old + 540.0) % 360.0) - 180.0;
      next = (old + delta * 0.25 + 360.0) % 360.0;
    }
    if (!mounted) return;
    setState(() {
      _heading = next;
      _noSensor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserLocation>(
      valueListenable: LocationService.current,
      builder: (context, loc, _) {
        final qibla = Qibla.bearing(loc.lat, loc.lon);
        final heading = _heading;
        final diff = heading == null ? 0.0 : Qibla.signedDiff(qibla, heading);
        final aligned = heading != null && diff.abs() < 4.0;

        final String status;
        if (_noSensor) {
          status = 'কম্পাস সেন্সর নেই';
        } else if (heading == null) {
          status = 'সেন্সর থেকে তথ্য আসছে…';
        } else if (aligned) {
          status = 'কিবলার দিকে ফিরে আছেন';
        } else if (widget.compact) {
          status = 'কিবলা';
        } else {
          status = diff > 0
              ? 'ডানে ${bn(diff.abs().round())}° ঘুরুন'
              : 'বামে ${bn(diff.abs().round())}° ঘুরুন';
        }

        final dial = QiblaDial(
          size: widget.size,
          heading: heading ?? 0.0,
          qibla: qibla,
          aligned: aligned,
          active: heading != null,
        );

        final statusText = Text(
          status,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: aligned ? Colors.lightGreenAccent : Colors.white,
            fontSize: widget.compact ? 12 : 18,
            fontWeight: widget.compact ? FontWeight.normal : FontWeight.bold,
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            dial,
            SizedBox(height: widget.compact ? 10 : 14),
            widget.compact
                ? SizedBox(
                    width: widget.size,
                    child: FittedBox(fit: BoxFit.scaleDown, child: statusText),
                  )
                : statusText,
          ],
        );
      },
    );
  }
}
