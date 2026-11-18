import 'prayer_rules.dart';
import 'solar_calc.dart';

/// একটি ওয়াক্ত (বা ফরজ নামাজ নেই এমন সময়)।
class Waqt {
  final String name;
  final DateTime start;
  final DateTime end;
  final bool isFard;
  const Waqt(this.name, this.start, this.end, this.isFard);
}

/// নামাজ নিষিদ্ধ সময়ের একটি জানালা।
class ProhibitedWindow {
  final String name;
  final DateTime start;
  final DateTime end;
  const ProhibitedWindow(this.name, this.start, this.end);

  int get minutes => end.difference(start).inMinutes;
}

/// গতকাল, আজ ও আগামীকালের সময় থেকে ওয়াক্ত ও নিষিদ্ধ সময়ের তালিকা বানায়।
class PrayerTimeline {
  final DayTimes today;
  final List<Waqt> waqts;
  final List<ProhibitedWindow> windows;

  const PrayerTimeline(this.today, this.waqts, this.windows);

  static PrayerTimeline? build(DateTime now, double lat, double lon) {
    final tz = now.timeZoneOffset.inMinutes / 60.0;
    final days = <DayTimes>[];
    for (var i = -1; i <= 1; i++) {
      final d = SolarCalc.compute(DateTime(now.year, now.month, now.day + i), lat, lon, tz);
      if (d == null) return null;
      days.add(d);
    }

    final waqts = <Waqt>[];
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final nextFajr = i + 1 < days.length ? days[i + 1].fajr : d.fajr.add(const Duration(days: 1));
      waqts.add(Waqt('ফজর', d.fajr, d.sunrise, true));
      waqts.add(Waqt('চাশতের সময়', d.sunrise, d.dhuhr, false));
      waqts.add(Waqt('যোহর', d.dhuhr, d.asr, true));
      waqts.add(Waqt('আসর', d.asr, d.sunset, true));
      waqts.add(Waqt('মাগরিব', d.sunset, d.isha, true));
      waqts.add(Waqt('এশা', d.isha, nextFajr, true));
    }

    final windows = <ProhibitedWindow>[];
    for (var i = 1; i < days.length; i++) {
      final d = days[i];
      windows.add(ProhibitedWindow(
        'সূর্যোদয়ের সময়',
        d.sunrise,
        d.sunrise.add(Duration(minutes: PrayerRules.sunriseMinutes)),
      ));
      windows.add(ProhibitedWindow(
        'ঠিক দুপুরের সময়',
        d.dhuhr.subtract(Duration(minutes: PrayerRules.zawalMinutes)),
        d.dhuhr,
      ));
      windows.add(ProhibitedWindow(
        'সূর্যাস্তের সময়',
        d.sunset.subtract(Duration(minutes: PrayerRules.sunsetMinutes)),
        d.sunset,
      ));
    }

    return PrayerTimeline(days[1], waqts, windows);
  }

  Waqt? currentWaqt(DateTime now) {
    for (final w in waqts) {
      if (!now.isBefore(w.start) && now.isBefore(w.end)) return w;
    }
    return null;
  }

  /// এখনকার পরের ফরজ নামাজের ওয়াক্ত।
  Waqt? nextFardWaqt(DateTime now) {
    for (final w in waqts) {
      if (w.isFard && w.start.isAfter(now)) return w;
    }
    return null;
  }

  ProhibitedWindow? currentWindow(DateTime now) {
    for (final w in windows) {
      if (!now.isBefore(w.start) && now.isBefore(w.end)) return w;
    }
    return null;
  }

  /// চলমান (থাকলে) ও আসন্ন নিষিদ্ধ সময়, সময়ক্রমে।
  List<ProhibitedWindow> upcomingWindows(DateTime now, {int count = 3}) {
    final out = <ProhibitedWindow>[];
    for (final w in windows) {
      if (w.end.isAfter(now)) {
        out.add(w);
        if (out.length >= count) break;
      }
    }
    return out;
  }
}
