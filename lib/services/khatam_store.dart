import 'package:shared_preferences/shared_preferences.dart';

class KhatamPlan {
  final DateTime start;
  final int days;
  final int totalRead;
  const KhatamPlan(this.start, this.days, this.totalRead);
}

/// কুরআন খতম পরিকল্পনা ও দৈনিক পড়ার হিসাব। সবকিছু ফোনেই সংরক্ষিত হয়।
class KhatamStore {
  KhatamStore._();

  static const int totalAyahs = 6236;

  static const String _kStart = 'khatam_start';
  static const String _kDays = 'khatam_days';
  static const String _kRead = 'khatam_read';
  static const String _kLog = 'khatam_log';

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

  static Future<KhatamPlan?> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kStart);
    final days = p.getInt(_kDays);
    if (s == null || days == null) return null;
    final start = DateTime.tryParse(s);
    if (start == null) return null;
    return KhatamPlan(start, days, p.getInt(_kRead) ?? 0);
  }

  static Future<void> create(int days) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kStart, dayKey(DateTime.now()));
    await p.setInt(_kDays, days);
    await p.setInt(_kRead, 0);
    await p.remove(_kLog);
  }

  static Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kStart);
    await p.remove(_kDays);
    await p.remove(_kRead);
    await p.remove(_kLog);
  }

  static Map<String, int> _parseLog(SharedPreferences p) {
    final out = <String, int>{};
    for (final line in p.getStringList(_kLog) ?? <String>[]) {
      final i = line.lastIndexOf(':');
      if (i <= 0) continue;
      final n = int.tryParse(line.substring(i + 1));
      if (n != null) out[line.substring(0, i)] = n;
    }
    return out;
  }

  static Future<int> todayCount() async {
    final p = await SharedPreferences.getInstance();
    return _parseLog(p)[dayKey(DateTime.now())] ?? 0;
  }

  /// আজকের পড়ার সংখ্যায় [n] যোগ করে (ঋণাত্মক হলে কমায়)। মোট পড়াও সেই অনুযায়ী বদলায়।
  static Future<void> addToday(int n) async {
    final p = await SharedPreferences.getInstance();
    final log = _parseLog(p);
    final key = dayKey(DateTime.now());
    final today = log[key] ?? 0;
    final read = p.getInt(_kRead) ?? 0;

    final newRead = _clamp(read + n, 0, totalAyahs);
    final delta = newRead - read;
    final newToday = _clamp(today + delta, 0, totalAyahs);

    log[key] = newToday;
    await p.setInt(_kRead, newRead);
    await p.setStringList(
      _kLog,
      [for (final e in log.entries) '${e.key}:${e.value}'],
    );
  }

  /// টানা কত দিন কিছু না কিছু পড়া হয়েছে (আজ না পড়ে থাকলে গতকাল থেকে গোনা হয়)।
  static Future<int> streak() async {
    final p = await SharedPreferences.getInstance();
    final log = _parseLog(p);
    var day = DateTime.now();
    if ((log[dayKey(day)] ?? 0) <= 0) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while ((log[dayKey(day)] ?? 0) > 0) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }
}
