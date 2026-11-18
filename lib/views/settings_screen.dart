import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_settings.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/content_config.dart';
import '../core/hijri.dart';
import '../core/prayer_rules.dart';
import '../data/prayer_data.dart' show bn;
import '../data/reminder_data.dart';
import '../services/notification_service.dart';
import '../widgets/reminder_tile.dart';
import 'backup_screen.dart';
import 'prayer_reminder_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _warn = false;
  double _asr = PrayerRules.asrFactor;
  String _method = AppSettings.calcMethod;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = await AppSettings.warnProhibited();
    if (mounted) setState(() => _warn = w);
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _setAsr(double? v) async {
    if (v == null) return;
    setState(() => _asr = v);
    await AppSettings.setAsrFactor(v);
    try {
      await NotificationService.instance.rescheduleAll();
    } catch (_) {}
    _snack('আসরের পদ্ধতি বদলেছে। হোমের সময় হালনাগাদ হতে অ্যাপ আবার খুলুন।');
  }

  Future<void> _setMethod(String? v) async {
    if (v == null) return;
    setState(() => _method = v);
    await AppSettings.setCalcMethod(v);
    try {
      await NotificationService.instance.rescheduleAll();
    } catch (_) {}
    _snack('ওয়াক্ত গণনার পদ্ধতি বদলেছে। হোমের সময় হালনাগাদ হতে অ্যাপ আবার খুলুন।');
  }

  Future<void> _setWarn(bool v) async {
    setState(() => _warn = v);
    await AppSettings.setWarnProhibited(v);
    try {
      await NotificationService.instance.rescheduleAll();
    } catch (_) {}
    _snack(v ? 'নিষিদ্ধ সময়ের সতর্কতা চালু (শুধু GPS আজান চালু থাকলে কাজ করবে)' : 'নিষিদ্ধ সময়ের সতর্কতা বন্ধ');
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.accent)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        children: [
          _title('থিম'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.mode,
            builder: (context, mode, _) => Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: mode,
                  title: const Text('ডার্ক মোড'),
                  onChanged: (v) => ThemeController.set(v ?? ThemeMode.dark),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: mode,
                  title: const Text('লাইট মোড'),
                  onChanged: (v) => ThemeController.set(v ?? ThemeMode.light),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: mode,
                  title: const Text('ফোনের সেটিং অনুযায়ী'),
                  onChanged: (v) => ThemeController.set(v ?? ThemeMode.system),
                ),
              ],
            ),
          ),
          _title('নামাজের সময়'),
          RadioListTile<double>(
            value: 2.0,
            groupValue: _asr,
            title: const Text('আসর: হানাফি'),
            subtitle: const Text('ছায়া বস্তুর দ্বিগুণ হলে আসরের শুরু'),
            onChanged: _setAsr,
          ),
          RadioListTile<double>(
            value: 1.0,
            groupValue: _asr,
            title: const Text('আসর: শাফেয়ী, মালেকী, হাম্বলী'),
            subtitle: const Text('ছায়া বস্তুর সমান হলে আসরের শুরু'),
            onChanged: _setAsr,
          ),
          _title('ফজর ও এশার গণনা পদ্ধতি'),
          for (final m in PrayerRules.methods)
            RadioListTile<String>(
              value: m.key,
              groupValue: _method,
              title: Text(m.name, style: const TextStyle(fontSize: 14.5)),
              onChanged: _setMethod,
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              'স্থানীয় মসজিদ বা ইসলামিক ফাউন্ডেশনের সময়ের সঙ্গে মিলিয়ে যেটি কাছাকাছি, সেটি বেছে নিন।',
              style: TextStyle(fontSize: 11.5, color: AppColors.subtle, height: 1.5),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.alarm_rounded),
            title: const Text('আজান ও রিমাইন্ডার'),
            subtitle: const Text('GPS অনুযায়ী বা হাতে সেট করা সময়'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerReminderScreen())),
          ),
          SwitchListTile(
            value: _warn,
            activeColor: AppColors.primaryGreen,
            title: const Text('নিষিদ্ধ সময়ের সতর্কতা'),
            subtitle: const Text('নিষিদ্ধ সময় শুরুর ৫ মিনিট আগে নোটিফিকেশন (GPS আজান চালু থাকলে)'),
            onChanged: _setWarn,
          ),
          _title('লেখার আকার'),
          ValueListenableBuilder<double>(
            valueListenable: AppSettings.textScale,
            builder: (context, scale, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in AppSettings.textScaleOptions)
                    ChoiceChip(
                      label: Text(o.value),
                      selected: scale == o.key,
                      onSelected: (_) => AppSettings.setTextScale(o.key),
                    ),
                ],
              ),
            ),
          ),
          for (var g = 0; g < kReminderGroupTitles.length; g++) ...[
            _title('রিমাইন্ডার: ${kReminderGroupTitles[g]}'),
            for (final r in kDailyReminders.where((x) => x.group == g)) ReminderTile(reminder: r),
          ],
          _title('হিজরি তারিখ'),
          ValueListenableBuilder<int>(
            valueListenable: AppSettings.hijriAdjust,
            builder: (context, adj, _) {
              final h = Hijri.fromGregorian(DateTime.now(), adjust: adj);
              return ListTile(
                title: Text('আজ: ${bn(h.day)} ${Hijri.monthName(h.month)} ${bn(h.year)}'),
                subtitle: Text(
                  adj == 0
                      ? 'চাঁদ দেখার সঙ্গে না মিললে এখান থেকে আগে-পরে করুন'
                      : (adj > 0 ? '${bn(adj)} দিন এগিয়ে ধরা হয়েছে' : '${bn(-adj)} দিন পিছিয়ে ধরা হয়েছে'),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: adj <= -2 ? null : () => AppSettings.setHijriAdjust(adj - 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: adj >= 2 ? null : () => AppSettings.setHijriAdjust(adj + 1),
                    ),
                  ],
                ),
              );
            },
          ),
          _title('তথ্য সংরক্ষণ'),
          ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: const Text('ব্যাকআপ ও পুনরুদ্ধার'),
            subtitle: const Text('নতুন ফোনে বুকমার্ক, খতম, আমল ইত্যাদি নিয়ে যান'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
          ),
          _title('অ্যাপ সম্পর্কে'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text(AppConstants.appName),
            subtitle: Text(AppConstants.buildTag),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              '${ContentConfig.quranCredit}\n\n${ContentConfig.hadithCredit}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.subtle, height: 1.5),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: Text(
              'নামাজের সময় আপনার GPS অবস্থান থেকে হিসাব করা (ফজর ও এশা আপনার বাছাই করা পদ্ধতির কোণে), তাই আনুমানিক। নিষিদ্ধ সময় ও অন্যান্য মাসআলায় বিশ্বস্ত আলেমের পরামর্শ নিন।',
              style: TextStyle(fontSize: 11.5, color: AppColors.subtle, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
