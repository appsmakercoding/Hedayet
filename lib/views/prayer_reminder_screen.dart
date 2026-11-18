import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_settings.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../data/prayer_data.dart';
import '../services/notification_service.dart';
import '../services/prayer_store.dart';
import 'prayer_detail_screen.dart';

class PrayerReminderScreen extends StatefulWidget {
  const PrayerReminderScreen({super.key});

  @override
  State<PrayerReminderScreen> createState() => _PrayerReminderScreenState();
}

class _PrayerReminderScreenState extends State<PrayerReminderScreen> {
  final Map<String, int> _minutes = {};
  final Map<String, bool> _enabled = {};
  bool _loading = true;
  bool _gps = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _gps = (await AppSettings.azanMode()) == 'gps';
    for (final p in kPrayers) {
      _minutes[p.key] = await PrayerStore.getMinutes(p);
      _enabled[p.key] = await PrayerStore.getEnabled(p);
    }
    if (!mounted) return;
    setState(() => _loading = false);
    try {
      await NotificationService.instance.requestPermissions();
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setGps(bool value) async {
    setState(() => _gps = value);
    await AppSettings.setAzanMode(value ? 'gps' : 'manual');
    try {
      await NotificationService.instance.rescheduleAll();
      _snack(value ? 'GPS অনুযায়ী আজান চালু হয়েছে' : 'হাতে সেট করা সময়ে আজান চালু হয়েছে');
    } catch (e) {
      _snack('আজান সেট করা যায়নি: $e');
    }
  }

  Future<void> _apply(PrayerInfo p) async {
    if (_gps) {
      try {
        await NotificationService.instance.rescheduleAll();
        _snack('GPS সময় অনুযায়ী আজান হালনাগাদ হয়েছে');
      } catch (e) {
        _snack('আজান সেট করা যায়নি: $e');
      }
      return;
    }
    try {
      if (_enabled[p.key] ?? true) {
        await NotificationService.instance.schedulePrayer(p, _minutes[p.key]!);
        _snack('${p.name}: ${formatTimeBn(_minutes[p.key]!)} এ আজান সেট হয়েছে');
      } else {
        await NotificationService.instance.cancelPrayer(p);
        _snack('${p.name}-এর আজান বন্ধ করা হয়েছে');
      }
    } catch (e) {
      _snack('আজান সেট করা যায়নি: $e');
    }
  }

  Future<void> _pickTime(PrayerInfo p) async {
    final current = _minutes[p.key]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: '${p.name} নামাজের সময়',
    );
    if (picked == null) return;
    final value = picked.hour * 60 + picked.minute;
    setState(() => _minutes[p.key] = value);
    await PrayerStore.setMinutes(p, value);
    await _apply(p);
  }

  Future<void> _toggle(PrayerInfo p, bool value) async {
    setState(() => _enabled[p.key] = value);
    await PrayerStore.setEnabled(p, value);
    await _apply(p);
  }

  Future<void> _test() async {
    try {
      await NotificationService.instance.showTest();
    } catch (e) {
      _snack('পরীক্ষা ব্যর্থ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নামাজ রিমাইন্ডার', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: SwitchListTile(
                    value: _gps,
                    activeColor: AppColors.primaryGreen,
                    title: const Text('GPS অনুযায়ী আজান', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                      'প্রতিদিনের সূর্যোদয়-সূর্যাস্তের হিসাব করা সময়ে আজান বাজবে। আগামী ৭ দিনের জন্য সেট হয়, অ্যাপ খুললে নতুন করে সেট হয়। বন্ধ রাখলে নিচের হাতে সেট করা সময় কাজ করবে।',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    onChanged: _setGps,
                  ),
                ),
                const SizedBox(height: 4),
                Card(
                  color: isDarkTheme(context) ? const Color(0xFF3A3318) : Colors.amber.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'নিচের সময়গুলো সাধারণ ধরে বসানো। আপনার এলাকার সময়সূচি দেখে প্রতিটি ওয়াক্তের সময় বদলে নিন।',
                      style: TextStyle(fontSize: 13.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final p in kPrayers) _prayerCard(p),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _test,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('আজান পরীক্ষা করুন'),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'আজান ঠিকমতো না বাজলে: ফোনের সেটিংস → অ্যাপ → হেদায়েত → ব্যাটারি থেকে '
                      '"Unrestricted" বা "সীমাহীন" করুন এবং নোটিফিকেশন ও অ্যালার্মের অনুমতি দিন।',
                      style: TextStyle(fontSize: 13, color: AppColors.subtle),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(AppConstants.buildTag, style: TextStyle(fontSize: 12, color: AppColors.subtle)),
                ),
              ],
            ),
    );
  }

  Widget _prayerCard(PrayerInfo p) {
    final enabled = _enabled[p.key] ?? true;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alarm, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      Text(
                        formatTimeBn(_minutes[p.key]!),
                        style: TextStyle(fontSize: 16, color: enabled ? AppColors.accent : Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(value: enabled, activeColor: AppColors.primaryGreen, onChanged: (v) => _toggle(p, v)),
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _pickTime(p),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: const Text('সময় বদলান'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PrayerDetailScreen(prayer: p)),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: const Text('রাকাত ও সূরা'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
