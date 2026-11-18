import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_settings.dart';
import '../core/app_theme.dart';
import '../data/prayer_data.dart' show bn;
import '../services/backup_service.dart';
import '../services/notification_service.dart';

/// ব্যাকআপ ও পুনরুদ্ধার। তথ্য ক্লিপবোর্ডে কপি হয়; ব্যবহারকারী নিজের পছন্দের জায়গায় (নোট, মেসেজ ইত্যাদি)
/// রেখে দেন। কোনো সার্ভারে কিছু যায় না।
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      final text = await BackupService.export();
      await Clipboard.setData(ClipboardData(text: text));
      _snack('ব্যাকআপ কপি হয়েছে। এখন নোট বা নিজের কাছে মেসেজ করে রেখে দিন।');
    } catch (e) {
      _snack('ব্যাকআপ নেওয়া যায়নি');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clip?.text ?? '';
    if (text.trim().isEmpty) {
      _snack('ক্লিপবোর্ডে কিছু নেই। আগে ব্যাকআপের লেখাটি কপি করুন।');
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ব্যাকআপ ফিরিয়ে আনবেন?'),
        content: const Text('ব্যাকআপে থাকা তথ্য এখনকার তথ্যের ওপর বসবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('হ্যাঁ, ফিরিয়ে আনুন')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final n = await BackupService.restore(text);
      await AppSettings.load();
      await ThemeController.load();
      try {
        await NotificationService.instance.rescheduleAll();
      } catch (_) {}
      _snack('${bn(n)}টি তথ্য ফিরে এসেছে। সব ঠিকমতো দেখতে অ্যাপ বন্ধ করে আবার খুলুন।');
    } on FormatException {
      _snack('ক্লিপবোর্ডের লেখাটি হেদায়েতের ব্যাকআপ নয়');
    } catch (e) {
      _snack('ফিরিয়ে আনা যায়নি');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ব্যাকআপ ও পুনরুদ্ধার', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'বুকমার্ক, কুরআনের শেষ পড়া, খতম, কাযা, আমল, তাসবীহ, সদকার খাতা ও সেটিংস নতুন ফোনে নিতে চাইলে এখান থেকে ব্যাকআপ নিন।',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('১. ব্যাকআপ নিন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'বাটন চাপলে সব তথ্য একটি লেখা হয়ে কপি হবে। সেটি নিজের নোট অ্যাপে বা নিজেকে পাঠানো মেসেজে রেখে দিন।',
                    style: TextStyle(color: AppColors.subtle, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _backup,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('ব্যাকআপ কপি করুন'),
                  ),
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
                  const Text('২. ফিরিয়ে আনুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'নতুন ফোনে অ্যাপ ইনস্টল করে ব্যাকআপের লেখাটি কপি করুন, তারপর এই বাটন চাপুন।',
                    style: TextStyle(color: AppColors.subtle, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.paste_rounded),
                    label: const Text('ক্লিপবোর্ড থেকে ফিরিয়ে আনুন'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'কুরআন ও হাদিসের ডেটা ব্যাকআপে থাকে না; নতুন ফোনে সেগুলো আবার ডাউনলোড করতে হবে। ব্যাকআপের লেখা কোনো সার্ভারে যায় না, তাই এটি নিরাপদ জায়গায় রাখার দায়িত্ব আপনার।',
            style: TextStyle(fontSize: 11.5, color: AppColors.subtle, height: 1.5),
          ),
        ],
      ),
    );
  }
}
