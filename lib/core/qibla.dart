import 'dart:math' as math;

/// কাবা শরীফের অবস্থানের সাপেক্ষে কিবলার দিক ও দূরত্বের হিসাব।
class Qibla {
  Qibla._();

  static const double kaabaLat = 21.4225;
  static const double kaabaLon = 39.8262;

  static double _rad(double d) => d * math.pi / 180.0;

  /// উত্তর থেকে ঘড়ির কাঁটার দিকে ডিগ্রিতে কিবলার দিক (০–৩৬০)।
  static double bearing(double lat, double lon) {
    final p1 = _rad(lat);
    final p2 = _rad(kaabaLat);
    final dl = _rad(kaabaLon - lon);
    final y = math.sin(dl) * math.cos(p2);
    final x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
    final b = math.atan2(y, x) * 180.0 / math.pi;
    return (b + 360.0) % 360.0;
  }

  /// কাবা শরীফ থেকে সোজা দূরত্ব, কিলোমিটারে।
  static double distanceKm(double lat, double lon) {
    const r = 6371.0;
    final p1 = _rad(lat);
    final p2 = _rad(kaabaLat);
    final dp = p2 - p1;
    final dl = _rad(kaabaLon - lon);
    final a = math.pow(math.sin(dp / 2), 2) + math.cos(p1) * math.cos(p2) * math.pow(math.sin(dl / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  /// [heading] থেকে [target]-এ পৌঁছাতে কত ডিগ্রি ঘুরতে হবে। ধনাত্মক = ডানে, ঋণাত্মক = বামে।
  static double signedDiff(double target, double heading) {
    return ((target - heading + 540.0) % 360.0) - 180.0;
  }

  static String directionName(double bearing) {
    const names = [
      'উত্তর',
      'উত্তর-পূর্ব',
      'পূর্ব',
      'দক্ষিণ-পূর্ব',
      'দক্ষিণ',
      'দক্ষিণ-পশ্চিম',
      'পশ্চিম',
      'উত্তর-পশ্চিম',
    ];
    final i = (((bearing + 22.5) % 360.0) / 45.0).floor() % 8;
    return names[i];
  }
}
