import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;

const List<MapEntry<String, String>> _amols = [
  MapEntry('fajr', 'ফজরের নামাজ'),
  MapEntry('zuhr', 'যোহরের নামাজ'),
  MapEntry('asr', 'আসরের নামাজ'),
  MapEntry('maghrib', 'মাগরিবের নামাজ'),
  MapEntry('isha', 'এশার নামাজ'),
  MapEntry('quran', 'কুরআন তিলাওয়াত'),
  MapEntry('dhikr', 'যিকির ও তাসবীহ'),
  MapEntry('tahajjud', 'তাহাজ্জুদ'),
  MapEntry('duha', 'চাশতের নামাজ'),
  MapEntry('sadaqa', 'দান-সাদাকা'),
  MapEntry('fast', 'নফল রোযা'),
];

const List<String> _shortDays = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি', 'রবি'];

String _keyOf(DateTime d) {
  final m = d.month < 10 ? '0${d.month}' : '${d.month}';
  final day = d.day < 10 ? '0${d.day}' : '${d.day}';
  return 'amol_${d.year}$m$day';
}

/// দৈনিক আমলের তালিকা ও গত ৭ দিনের অগ্রগতি। সবকিছু ফোনে সংরক্ষিত থাকে।
class AmolScreen extends StatefulWidget {
  const AmolScreen({super.key});

  @override
  State<AmolScreen> createState() => _AmolScreenState();
}

class _AmolScreenState extends State<AmolScreen> {
  late DateTime _today;
  late DateTime _day;
  Set<String> _done = <String>{};
  final Map<String, int> _week = <String, int>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _day = _today;
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final done = (prefs.getStringList(_keyOf(_day)) ?? <String>[]).toSet();
    final week = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final d = DateTime(_today.year, _today.month, _today.day - i);
      week[_keyOf(d)] = (prefs.getStringList(_keyOf(d)) ?? <String>[]).length;
    }
    if (!mounted) return;
    setState(() {
      _done = done;
      _week
        ..clear()
        ..addAll(week);
    });
  }

  Future<void> _toggle(String k) async {
    setState(() {
      if (!_done.remove(k)) _done.add(k);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyOf(_day), _done.toList());
    await _load();
  }

  void _shift(int delta) {
    final next = DateTime(_day.year, _day.month, _day.day + delta);
    if (next.isAfter(_today)) return;
    setState(() => _day = next);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = _amols.length;
    final count = _done.length;
    final isToday = _day == _today;
    return Scaffold(
      appBar: AppBar(title: const Text('আমল ট্র্যাকার', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          Row(
            children: [
              IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left_rounded, size: 30)),
              Expanded(
                child: Text(
                  isToday ? 'আজ' : '${bn(_day.day)}/${bn(_day.month)}/${bn(_day.year)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: isToday ? null : () => _shift(1),
                icon: const Icon(Icons.chevron_right_rounded, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: count / total,
              minHeight: 10,
              color: AppColors.accent,
              backgroundColor: AppColors.subtle.withOpacity(0.25),
            ),
          ),
          const SizedBox(height: 6),
          Text('${bn(count)}/${bn(total)} সম্পন্ন', style: const TextStyle(color: AppColors.subtle)),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                for (final a in _amols)
                  CheckboxListTile(
                    value: _done.contains(a.key),
                    activeColor: AppColors.primaryGreen,
                    title: Text(a.value),
                    onChanged: (_) => _toggle(a.key),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('গত ৭ দিন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 6; i >= 0; i--)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final d = DateTime(_today.year, _today.month, _today.day - i);
                        final c = _week[_keyOf(d)] ?? 0;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(bn(c), style: const TextStyle(fontSize: 11, color: AppColors.subtle)),
                            const SizedBox(height: 3),
                            Container(
                              height: 6 + 62.0 * c / total,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: c == 0 ? AppColors.subtle.withOpacity(0.3) : AppColors.accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_shortDays[d.weekday - 1], style: const TextStyle(fontSize: 11)),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
