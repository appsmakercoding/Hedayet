import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart';

String _two(int n) => n < 10 ? '০${bn(n)}' : bn(n);

String _dur(Duration d) {
  final t = d.isNegative ? Duration.zero : d;
  return '${_two(t.inHours)}:${_two(t.inMinutes % 60)}:${_two(t.inSeconds % 60)}';
}

/// নিজের মসজিদের নাম ও জামাতের সময় নিজে বসিয়ে রাখা; পরের জামাতের কাউন্টডাউন দেখায়।
class MyMosqueScreen extends StatefulWidget {
  const MyMosqueScreen({super.key});

  @override
  State<MyMosqueScreen> createState() => _MyMosqueScreenState();
}

class _MyMosqueScreenState extends State<MyMosqueScreen> {
  final TextEditingController _name = TextEditingController();
  final Map<String, int> _times = <String, int>{};
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _name.text = prefs.getString('mosque_name') ?? '';
    for (final p in kPrayers) {
      _times[p.key] = prefs.getInt('jamaat_${p.key}') ?? -1;
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveName(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mosque_name', v.trim());
    if (mounted) setState(() {});
  }

  Future<void> _pick(PrayerInfo p) async {
    final current = _times[p.key] ?? -1;
    final base = current >= 0 ? current : p.defaultMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base ~/ 60, minute: base % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jamaat_${p.key}', minutes);
    if (mounted) setState(() => _times[p.key] = minutes);
  }

  Future<void> _clear(PrayerInfo p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jamaat_${p.key}');
    if (mounted) setState(() => _times[p.key] = -1);
  }

  /// এখন থেকে পরের সেট করা জামাত (আজ না থাকলে আগামীকালের প্রথমটি)।
  MapEntry<PrayerInfo, DateTime>? _next() {
    MapEntry<PrayerInfo, DateTime>? best;
    for (var dayOffset = 0; dayOffset <= 1; dayOffset++) {
      for (final p in kPrayers) {
        final m = _times[p.key] ?? -1;
        if (m < 0) continue;
        final at = DateTime(_now.year, _now.month, _now.day + dayOffset, m ~/ 60, m % 60);
        if (at.isAfter(_now) && (best == null || at.isBefore(best.value))) {
          best = MapEntry(p, at);
        }
      }
      if (best != null) break;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final next = _next();
    final title = _name.text.trim().isEmpty ? 'আমার মসজিদ' : _name.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('আমার মসজিদ', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          Container(
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
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (next == null)
                  const Text(
                    'জামাতের সময় বসালে এখানে পরের জামাত ও কাউন্টডাউন দেখাবে।',
                    style: TextStyle(color: Colors.white70, fontSize: 13.5),
                  )
                else ...[
                  Text(
                    'পরের জামাত: ${next.key.name} • ${formatTimeBn(next.value.hour * 60 + next.value.minute)}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dur(next.value.difference(_now)),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'মসজিদের নাম',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home_work_rounded),
            ),
            onChanged: _saveName,
          ),
          const SizedBox(height: 14),
          const Text('জামাতের সময়', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Card(
            child: Column(
              children: [
                for (final p in kPrayers)
                  ListTile(
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      (_times[p.key] ?? -1) >= 0 ? formatTimeBn(_times[p.key]!) : 'সময় সেট করা নেই',
                    ),
                    trailing: (_times[p.key] ?? -1) >= 0
                        ? IconButton(
                            tooltip: 'মুছুন',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => _clear(p),
                          )
                        : const Icon(Icons.edit_rounded, color: AppColors.subtle),
                    onTap: () => _pick(p),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'সময়গুলো আপনার নিজের বসানো। মসজিদে জামাতের সময় বদলালে এখানেও বদলে নিন।',
            style: TextStyle(fontSize: 11.5, color: AppColors.subtle),
          ),
        ],
      ),
    );
  }
}
