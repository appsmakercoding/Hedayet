import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;
import '../data/reminder_data.dart';
import '../data/surah_data.dart';
import '../services/khatam_store.dart';
import '../widgets/reminder_tile.dart';
import 'surah_screen.dart';

class _Pos {
  final SurahInfo surah;
  final int ayah;
  const _Pos(this.surah, this.ayah);
}

/// কুরআন খতম প্ল্যানার: কত দিনে খতম করবেন ঠিক করলে দৈনিক লক্ষ্য হিসাব করে দেয়।
class KhatamScreen extends StatefulWidget {
  const KhatamScreen({super.key});

  @override
  State<KhatamScreen> createState() => _KhatamScreenState();
}

class _KhatamScreenState extends State<KhatamScreen> {
  KhatamPlan? _plan;
  int _today = 0;
  int _streak = 0;
  bool _loading = true;
  int _chosenDays = 30;

  static const List<int> _options = [7, 15, 30, 60, 90, 180];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plan = await KhatamStore.load();
    final today = await KhatamStore.todayCount();
    final streak = await KhatamStore.streak();
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _today = today;
      _streak = streak;
      _loading = false;
    });
  }

  Future<void> _add(int n) async {
    await KhatamStore.addToday(n);
    await _load();
  }

  Future<void> _start() async {
    await KhatamStore.create(_chosenDays);
    await _load();
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('পরিকল্পনা মুছবেন?'),
        content: const Text('এতে এখনকার খতমের সব হিসাব মুছে যাবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('হ্যাঁ, মুছুন')),
        ],
      ),
    );
    if (ok != true) return;
    await KhatamStore.reset();
    await _load();
  }

  /// ক্রমানুসারে পড়লে [read] সংখ্যক আয়াত পড়ার পর পরের আয়াত কোনটি।
  _Pos _position(int read) {
    var acc = 0;
    for (final s in kSurahs) {
      if (read < acc + s.verses) return _Pos(s, read - acc + 1);
      acc += s.verses;
    }
    final last = kSurahs.last;
    return _Pos(last, last.verses);
  }

  Widget _chooser() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'কত দিনে কুরআন খতম করতে চান?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'কুরআনের ৬২৩৬টি আয়াতকে দিন দিয়ে ভাগ করে প্রতিদিনের লক্ষ্য হিসাব করা হবে।',
          style: TextStyle(color: AppColors.subtle, height: 1.5),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _options)
              ChoiceChip(
                label: Text('${bn(d)} দিন'),
                selected: _chosenDays == d,
                onSelected: (_) => setState(() => _chosenDays = d),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'দৈনিক প্রায় ${bn((KhatamStore.totalAyahs / _chosenDays).ceil())}টি আয়াত',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.accent),
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.flag_rounded),
          label: const Text('শুরু করুন'),
        ),
      ],
    );
  }

  Widget _planView(KhatamPlan plan) {
    final now = DateTime.now();
    final todayMid = DateTime(now.year, now.month, now.day);
    final startMid = DateTime(plan.start.year, plan.start.month, plan.start.day);
    final dayIndex = (todayMid.difference(startMid).inHours / 24).round();
    final left = plan.days - dayIndex;
    final daysLeft = left < 1 ? 1 : left;
    final overdue = dayIndex >= plan.days;

    const total = KhatamStore.totalAyahs;
    final readBefore = plan.totalRead - _today;
    final target = ((total - readBefore) / daysLeft).ceil();
    final done = plan.totalRead >= total;
    final progress = plan.totalRead / total;
    final pos = _position(plan.totalRead);
    final dayNumber = dayIndex + 1 > plan.days ? plan.days : dayIndex + 1;

    if (done) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.emoji_events_rounded, size: 72, color: AppColors.gold),
          const SizedBox(height: 12),
          const Text(
            'আলহামদুলিল্লাহ! খতম সম্পন্ন হয়েছে।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'আল্লাহ আপনার তিলাওয়াত কবুল করুন।',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.subtle),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () async {
              await KhatamStore.reset();
              await _load();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('নতুন খতম শুরু করুন'),
          ),
        ],
      );
    }

    final remainToday = target - _today;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'দিন ${bn(dayNumber)}/${bn(plan.days)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.subtle),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    color: AppColors.primaryGreen,
                    backgroundColor: AppColors.subtle.withOpacity(0.25),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'পড়া হয়েছে ${bn(plan.totalRead)}/${bn(total)} আয়াত (${bn((progress * 100).floor())}%)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (overdue) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'নির্ধারিত সময় পার হয়েছে। চাইলে নিচ থেকে নতুন পরিকল্পনা করতে পারেন।',
                    style: TextStyle(fontSize: 12.5, color: Colors.orange),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('আজকের লক্ষ্য', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  '${bn(_today)}/${bn(target)} আয়াত',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
                const SizedBox(height: 4),
                Text(
                  remainToday <= 0
                      ? 'আজকের লক্ষ্য পূরণ হয়েছে, আলহামদুলিল্লাহ।'
                      : 'আজ আর ${bn(remainToday)}টি আয়াত বাকি।',
                  style: const TextStyle(color: AppColors.subtle),
                ),
                if (_streak > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'টানা ${bn(_streak)} দিন তিলাওয়াত করছেন।',
                    style: const TextStyle(color: AppColors.subtle),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('আজ কত আয়াত পড়লেন?', style: TextStyle(fontSize: 13.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final n in const [10, 20, 50, 100])
                      ElevatedButton(onPressed: () => _add(n), child: Text('+${bn(n)}')),
                    if (remainToday > 0)
                      ElevatedButton.icon(
                        onPressed: () => _add(remainToday),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('লক্ষ্য পূরণ'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _today <= 0 ? null : () => _add(-10),
                  child: const Text('ভুল হলে ১০টি কমান'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book_rounded, color: AppColors.accent),
            title: Text('পরের পড়া: ${pos.surah.nameBn}, আয়াত ${bn(pos.ayah)}'),
            subtitle: const Text('ক্রমানুসারে পড়লে এখান থেকে শুরু করুন'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SurahScreen(surah: pos.surah, initialAyah: pos.ayah),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Card(
          child: ReminderTile(
            reminder: kDailyReminders.firstWhere((r) => r.key == 'quran'),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('পরিকল্পনা মুছুন'),
        ),
        const SizedBox(height: 10),
        const Text(
          'হিসাব আয়াত সংখ্যা ধরে আপনার ফোনেই সংরক্ষিত থাকে; কোনো সার্ভারে যায় না।',
          style: TextStyle(fontSize: 11.5, color: AppColors.subtle, height: 1.5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('কুরআন খতম প্ল্যানার', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_plan == null ? _chooser() : _planView(_plan!)),
    );
  }
}
