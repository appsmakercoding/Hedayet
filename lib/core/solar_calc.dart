import 'dart:math' as math;

import 'prayer_rules.dart';

/// একটি দিনের ওয়াক্তের সময় (ফোনের স্থানীয় সময়ে)।
class DayTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime sunset;
  final DateTime isha;

  const DayTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.sunset,
    required this.isha,
  });
}

class _Sun {
  final double decl;
  final double eqt;
  const _Sun(this.decl, this.eqt);
}

/// অক্ষাংশ-দ্রাঘিমাংশ থেকে সূর্যোদয়, সূর্যাস্ত, যোহর, আসর, ফজর ও এশার সময় হিসাব করে।
/// ইন্টারনেট লাগে না। হিসাবের পদ্ধতি PrayTimes.org-এর মতো।
class SolarCalc {
  SolarCalc._();

  static double _rad(double d) => d * math.pi / 180.0;
  static double _deg(double r) => r * 180.0 / math.pi;
  static double _sin(double d) => math.sin(_rad(d));
  static double _cos(double d) => math.cos(_rad(d));
  static double _tan(double d) => math.tan(_rad(d));
  static double _asin(double x) => _deg(math.asin(x));
  static double _acos(double x) => _deg(math.acos(x));
  static double _atan2(double y, double x) => _deg(math.atan2(y, x));
  static double _acot(double x) => _deg(math.atan2(1.0, x));

  static double _fix(double a, double m) => a - m * (a / m).floorToDouble();
  static double _fixAngle(double a) => _fix(a, 360.0);
  static double _fixHour(double a) => _fix(a, 24.0);

  static double _julian(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100.0).floorToDouble();
    final b = 2 - a + (a / 4.0).floorToDouble();
    return (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() +
        day +
        b -
        1524.5;
  }

  static _Sun _sun(double jd) {
    final d = jd - 2451544.5;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));
    final e = 23.439 - 0.00000036 * d;
    final ra = _atan2(_cos(e) * _sin(l), _cos(l)) / 15.0;
    final eqt = q / 15.0 - _fixHour(ra);
    final decl = _asin(_sin(e) * _sin(l));
    return _Sun(decl, eqt);
  }

  /// [date]-এর দিনের সময় হিসাব করে। অক্ষাংশ এমন হলে (মেরুর কাছে) যে হিসাব সম্ভব নয়, তখন null।
  static DayTimes? compute(DateTime date, double lat, double lon, double tzHours) {
    final jd = _julian(date.year, date.month, date.day) - lon / (15.0 * 24.0);

    double mid(double t) => _fixHour(12 - _sun(jd + t).eqt);

    double? angleTime(double angle, double t, bool ccw) {
      final s = _sun(jd + t);
      final noon = mid(t);
      final x = (-_sin(angle) - _sin(s.decl) * _sin(lat)) / (_cos(s.decl) * _cos(lat));
      if (x.isNaN || x < -1.0 || x > 1.0) return null;
      final diff = _acos(x) / 15.0;
      return ccw ? noon - diff : noon + diff;
    }

    double? asrTime(double factor, double t) {
      final s = _sun(jd + t);
      final angle = -_acot(factor + _tan((lat - s.decl).abs()));
      return angleTime(angle, t, false);
    }

    var fajr = 5.0;
    var sunrise = 6.0;
    var dhuhr = 12.0;
    var asr = 13.0;
    var sunset = 18.0;
    var isha = 18.0;

    for (var i = 0; i < 3; i++) {
      final nf = angleTime(PrayerRules.fajrAngle, fajr / 24.0, true);
      final nsr = angleTime(0.833, sunrise / 24.0, true);
      final nd = mid(dhuhr / 24.0);
      final na = asrTime(PrayerRules.asrFactor, asr / 24.0);
      final nss = angleTime(0.833, sunset / 24.0, false);
      final ni = angleTime(PrayerRules.ishaAngle, isha / 24.0, false);
      if (nf == null || nsr == null || na == null || nss == null || ni == null) {
        return null;
      }
      fajr = nf;
      sunrise = nsr;
      dhuhr = nd;
      asr = na;
      sunset = nss;
      isha = ni;
    }

    final offset = tzHours - lon / 15.0;
    final midnight = DateTime(date.year, date.month, date.day);
    DateTime at(double hours) {
      final seconds = ((hours + offset) * 3600).round();
      return midnight.add(Duration(seconds: seconds));
    }

    return DayTimes(
      fajr: at(fajr),
      sunrise: at(sunrise),
      dhuhr: at(dhuhr),
      asr: at(asr),
      sunset: at(sunset),
      isha: at(isha),
    );
  }
}
