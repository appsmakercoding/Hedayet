import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_settings.dart';
import '../core/hijri.dart';
import '../data/prayer_data.dart' show bn;

String _bnDate(DateTime d) => '${bn(d.day)} ${kGregorianMonthsBn[d.month - 1]} ${bn(d.year)}';

String _hijriText(HijriDate h) => '${bn(h.day)} ${Hijri.monthName(h.month)} ${bn(h.year)}';

/// ইংরেজি মাসের ক্যালেন্ডার, প্রতিটি দিনের নিচে হিজরি তারিখ; নিচে আসন্ন ইসলামি দিবস।
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Set<String> _eventKeys(int adj) {
    final hy = Hijri.fromGregorian(_month, adjust: adj).year;
    final keys = <String>{};
    for (var y = hy - 1; y <= hy + 1; y++) {
      for (final e in Hijri.events) {
        final g = Hijri.toGregorian(y, e.month, e.day, adjust: adj);
        keys.add('${g.year}-${g.month}-${g.day}');
      }
    }
    return keys;
  }

  Widget _cell(int day, int days, int adj, DateTime now, Set<String> marks, bool friday) {
    if (day < 1 || day > days) return const SizedBox(height: 54);
    final date = DateTime(_month.year, _month.month, day);
    final h = Hijri.fromGregorian(date, adjust: adj);
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isEvent = marks.contains('${date.year}-${date.month}-${date.day}');
    final mainColor = isToday ? Colors.white : (friday ? AppColors.accent : null);
    return Container(
      height: 54,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primaryGreen : null,
        borderRadius: BorderRadius.circular(10),
        border: isEvent && !isToday ? Border.all(color: AppColors.gold, width: 1.4) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bn(day),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainColor),
          ),
          Text(
            bn(h.day),
            style: TextStyle(fontSize: 10.5, color: isToday ? Colors.white70 : AppColors.subtle),
          ),
        ],
      ),
    );
  }

  Widget _grid(int adj, DateTime now) {
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = (first.weekday + 1) % 7;
    final rows = ((offset + days) / 7).ceil();
    final marks = _eventKeys(adj);
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: _cell(r * 7 + c - offset + 1, days, adj, now, marks, c == 6)),
            ],
          ),
      ],
    );
  }

  String _daysLeft(DateTime date, DateTime now) {
    final diff = DateTime(date.year, date.month, date.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'আজ';
    if (diff == 1) return 'আগামীকাল';
    return '${bn(diff)} দিন পরে';
  }

  @override
  Widget build(BuildContext context) {
    const weekdays = ['শনি', 'রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র'];
    return Scaffold(
      appBar: AppBar(title: const Text('ক্যালেন্ডার', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ValueListenableBuilder<int>(
        valueListenable: AppSettings.hijriAdjust,
        builder: (context, adj, _) {
          final now = DateTime.now();
          final firstH = Hijri.fromGregorian(DateTime(_month.year, _month.month, 1), adjust: adj);
          final lastH = Hijri.fromGregorian(DateTime(_month.year, _month.month + 1, 0), adjust: adj);
          final hijriRange = firstH.month == lastH.month && firstH.year == lastH.year
              ? '${Hijri.monthName(firstH.month)} ${bn(firstH.year)}'
              : '${Hijri.monthName(firstH.month)} – ${Hijri.monthName(lastH.month)} ${bn(lastH.year)}';
          final upcoming = Hijri.upcoming(now, adjust: adj);
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left_rounded, size: 30)),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${kGregorianMonthsBn[_month.month - 1]} ${bn(_month.year)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(hijriRange, style: const TextStyle(fontSize: 13, color: AppColors.subtle)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right_rounded, size: 30)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: Text(
                          weekdays[i],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: i == 6 ? AppColors.accent : AppColors.subtle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              _grid(adj, now),
              const SizedBox(height: 6),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _month = DateTime(now.year, now.month)),
                    icon: const Icon(Icons.today_rounded, size: 18),
                    label: const Text('আজকের মাসে যান'),
                  ),
                  const Spacer(),
                  Text(
                    'আজ: ${_hijriText(Hijri.fromGregorian(now, adjust: adj))}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.subtle),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('আসন্ন গুরুত্বপূর্ণ দিন', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              for (final e in upcoming)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryGreen,
                      child: Icon(Icons.event_rounded, color: Colors.white),
                    ),
                    title: Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${kWeekdaysBn[e.key.weekday - 1]}, ${_bnDate(e.key)}'
                      '${e.value.note.isEmpty ? '' : '\n${e.value.note}'}',
                    ),
                    isThreeLine: e.value.note.isNotEmpty,
                    trailing: Text(_daysLeft(e.key, now), style: const TextStyle(fontSize: 12.5)),
                  ),
                ),
              const SizedBox(height: 6),
              const Text(
                'হিজরি তারিখ হিসাবভিত্তিক। চাঁদ দেখার ওপর নির্ভর করায় বাংলাদেশের আসল তারিখ ১–২ দিন আলাদা হতে পারে। সেটিংসে হিজরি তারিখ আগে-পরে করতে পারবেন।',
                style: TextStyle(fontSize: 11.5, color: AppColors.subtle, height: 1.5),
              ),
            ],
          );
        },
      ),
    );
  }
}
