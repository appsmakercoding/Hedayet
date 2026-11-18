import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../core/app_settings.dart';
import '../core/hijri.dart';
import '../core/solar_calc.dart';
import '../data/prayer_data.dart' show bn, formatTimeBn;
import '../services/location_service.dart';

String _two(int n) => n < 10 ? '০${bn(n)}' : bn(n);

String _dur(Duration d) {
  final t = d.isNegative ? Duration.zero : d;
  return '${_two(t.inHours)}:${_two(t.inMinutes % 60)}:${_two(t.inSeconds % 60)}';
}

String _clock(DateTime t) {
  final m = (t.hour * 60 + t.minute + (t.second >= 30 ? 1 : 0)) % 1440;
  return formatTimeBn(m);
}

class _RamadanRow {
  final int day;
  final DateTime date;
  final DayTimes times;
  const _RamadanRow(this.day, this.date, this.times);
}

/// সেহরি ও ইফতারের সময়, কাউন্টডাউন এবং রমযানের ৩০ দিনের ট্র্যাকার।
class RozaScreen extends StatefulWidget {
  const RozaScreen({super.key});

  @override
  State<RozaScreen> createState() => _RozaScreenState();
}

class _RozaScreenState extends State<RozaScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  final Set<String> _marks = {};
  List<_RamadanRow> _rows = [];
  String _rowsKey = '';
  int _year = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    LocationService.loadSaved();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _ramadanYear(int adj) {
    final today = DateTime(_now.year, _now.month, _now.day);
    var y = Hijri.fromGregorian(today, adjust: adj).year;
    final start = Hijri.toGregorian(y, 9, 1, adjust: adj);
    if (today.isAfter(start.add(const Duration(days: 30)))) y++;
    return y;
  }

  Future<void> _loadMarks(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('roza_$year') ?? <String>[];
    if (!mounted) return;
    setState(() {
      _marks
        ..clear()
        ..addAll(list);
    });
  }

  Future<void> _toggle(String key) async {
    setState(() {
      if (!_marks.remove(key)) _marks.add(key);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('roza_$_year', _marks.toList());
  }

  List<_RamadanRow> _buildRows(int year, int adj, UserLocation loc, double tz) {
    final start = Hijri.toGregorian(year, 9, 1, adjust: adj);
    final rows = <_RamadanRow>[];
    for (var i = 0; i < 30; i++) {
      final date = DateTime(start.year, start.month, start.day + i);
      final t = SolarCalc.compute(date, loc.lat, loc.lon, tz);
      if (t != null) rows.add(_RamadanRow(i + 1, date, t));
    }
    return rows;
  }

  bool _fastDiscouraged(HijriDate h) {
    return (h.month == 10 && h.day == 1) || (h.month == 12 && h.day >= 10 && h.day <= 13);
  }

  String? _sunnahHint(DateTime now, int adj) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final h = Hijri.fromGregorian(tomorrow, adjust: adj);
    if (h.month == 9 || _fastDiscouraged(h)) return null;
    if (h.day >= 13 && h.day <= 15) return 'আগামীকাল আইয়ামে বীযের (মাসের ১৩, ১৪, ১৫ তারিখ) নফল রোযার দিন।';
    if (tomorrow.weekday == DateTime.monday) return 'আগামীকাল সোমবার, নফল রোযার সুযোগ।';
    if (tomorrow.weekday == DateTime.thursday) return 'আগামীকাল বৃহস্পতিবার, নফল রোযার সুযোগ।';
    return null;
  }

  Widget _timeBox(String label, DateTime t, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold, size: 26),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
            const SizedBox(height: 2),
            Text(
              _clock(t),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayCard(DayTimes today, DayTimes tomorrow, HijriDate h) {
    final now = _now;
    final String label;
    final DateTime target;
    if (now.isBefore(today.fajr)) {
      label = 'সেহরির শেষ সময় হতে বাকি';
      target = today.fajr;
    } else if (now.isBefore(today.sunset)) {
      label = 'ইফতার হতে বাকি';
      target = today.sunset;
    } else {
      label = 'পরের সেহরির শেষ সময় হতে বাকি';
      target = tomorrow.fajr;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkGreen, AppColors.primaryGreen],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'আজ: ${bn(h.day)} ${Hijri.monthName(h.month)} ${bn(h.year)}'
            '${h.month == 9 ? ' • রমযান' : ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _timeBox('সেহরির শেষ সময়', today.fajr, Icons.nights_stay_rounded),
              const SizedBox(width: 10),
              _timeBox('ইফতার', today.sunset, Icons.wb_twilight_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            _dur(target.difference(now)),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _row(_RamadanRow r) {
    final isToday = r.date.year == _now.year && r.date.month == _now.month && r.date.day == _now.day;
    final rk = '${r.day}:r';
    final tk = '${r.day}:t';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: isToday
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.gold, width: 1.6),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'রমযান ${bn(r.day)} • ${kWeekdaysBn[r.date.weekday - 1]}, ${bn(r.date.day)} ${kGregorianMonthsBn[r.date.month - 1]}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
            const SizedBox(height: 4),
            Text(
              'সেহরি শেষ ${_clock(r.times.fajr)}  •  ইফতার ${_clock(r.times.sunset)}',
              style: const TextStyle(fontSize: 13, color: AppColors.subtle),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('রোযা রেখেছি'),
                  selected: _marks.contains(rk),
                  onSelected: (_) => _toggle(rk),
                ),
                FilterChip(
                  label: const Text('তারাবীহ পড়েছি'),
                  selected: _marks.contains(tk),
                  onSelected: (_) => _toggle(tk),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('রোযা: সেহরি ও ইফতার', style: TextStyle(fontWeight: FontWeight.bold))),
      body: AnimatedBuilder(
        animation: Listenable.merge([LocationService.current, AppSettings.hijriAdjust]),
        builder: (context, _) {
          final loc = LocationService.current.value;
          final adj = AppSettings.hijriAdjust.value;
          final now = _now;
          final tz = now.timeZoneOffset.inMinutes / 60.0;
          final todayDate = DateTime(now.year, now.month, now.day);
          final today = SolarCalc.compute(todayDate, loc.lat, loc.lon, tz);
          final tomorrow = SolarCalc.compute(DateTime(now.year, now.month, now.day + 1), loc.lat, loc.lon, tz);
          if (today == null || tomorrow == null) {
            return const Center(child: Text('এই অবস্থানের জন্য সময় হিসাব করা যায়নি।'));
          }

          final year = _ramadanYear(adj);
          if (year != _year) {
            _year = year;
            _loadMarks(year);
          }
          final key = '${loc.lat.toStringAsFixed(3)},${loc.lon.toStringAsFixed(3)},$year,$adj';
          if (key != _rowsKey) {
            _rows = _buildRows(year, adj, loc, tz);
            _rowsKey = key;
          }

          final h = Hijri.fromGregorian(todayDate, adjust: adj);
          final hint = _sunnahHint(now, adj);
          final fasted = _marks.where((m) => m.endsWith(':r')).length;
          final taraweeh = _marks.where((m) => m.endsWith(':t')).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
            children: [
              _todayCard(today, tomorrow, h),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.gold),
                      title: Text(hint, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'রমযান ${bn(year)} হিজরির ট্র্যাকার',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'রোযা ${bn(fasted)}/৩০  •  তারাবীহ ${bn(taraweeh)}/৩০',
                style: const TextStyle(fontSize: 13.5, color: AppColors.accent),
              ),
              const SizedBox(height: 10),
              for (final r in _rows) _row(r),
              const Text(
                'রমযানের তারিখ হিসাবভিত্তিক; চাঁদ দেখার সঙ্গে ১–২ দিন আলাদা হতে পারে (সেটিংসে ঠিক করা যায়)। সেহরির শেষ সময় ফজরের শুরুর হিসাব, সতর্কতার জন্য কয়েক মিনিট আগে শেষ করা ভালো। সময়গুলো GPS অবস্থান থেকে আনুমানিক।',
                style: TextStyle(fontSize: 11.5, color: AppColors.subtle, height: 1.5),
              ),
            ],
          );
        },
      ),
    );
  }
}
