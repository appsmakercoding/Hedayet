import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_settings.dart';
import '../data/prayer_data.dart' show formatTimeBn;
import '../data/reminder_data.dart';
import '../services/notification_service.dart';

/// একটি দৈনিক রিমাইন্ডারের চালু/বন্ধ ও সময় বদলানোর সারি।
class ReminderTile extends StatefulWidget {
  final DailyReminder reminder;
  const ReminderTile({super.key, required this.reminder});

  @override
  State<ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends State<ReminderTile> {
  bool _on = false;
  int _minutes = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _minutes = widget.reminder.defaultMinutes;
    _load();
  }

  Future<void> _load() async {
    final on = await AppSettings.reminderEnabled(widget.reminder.key);
    final m = await AppSettings.reminderMinutes(widget.reminder.key, widget.reminder.defaultMinutes);
    if (!mounted) return;
    setState(() {
      _on = on;
      _minutes = m;
      _loaded = true;
    });
  }

  Future<void> _apply() async {
    try {
      await NotificationService.instance.applyDailyReminders();
    } catch (_) {}
  }

  Future<void> _toggle(bool v) async {
    setState(() => _on = v);
    await AppSettings.setReminderEnabled(widget.reminder.key, v);
    if (v) {
      try {
        await NotificationService.instance.requestPermissions();
      } catch (_) {}
    }
    await _apply();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
    );
    if (t == null) return;
    final m = t.hour * 60 + t.minute;
    setState(() => _minutes = m);
    await AppSettings.setReminderMinutes(widget.reminder.key, m);
    await _apply();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications_active_rounded, color: AppColors.accent),
      title: Text(widget.reminder.title),
      subtitle: Text(
        '${widget.reminder.weekday == null ? 'প্রতিদিন' : 'প্রতি ${kWeekdayNamesBn[widget.reminder.weekday!]}'} '
        '${formatTimeBn(_minutes)} • সময় বদলাতে ট্যাপ করুন',
      ),
      onTap: _loaded ? _pickTime : null,
      trailing: Switch(
        value: _on,
        activeColor: AppColors.primaryGreen,
        onChanged: _loaded ? _toggle : null,
      ),
    );
  }
}
