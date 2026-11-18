import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;

class _Entry {
  final DateTime date;
  final int amount;
  final String note;
  const _Entry(this.date, this.amount, this.note);

  String get raw => '${date.year}-${date.month}-${date.day}|$amount|${note.replaceAll('|', ' ')}';

  static _Entry? parse(String raw) {
    final parts = raw.split('|');
    if (parts.length < 2) return null;
    final d = parts[0].split('-');
    if (d.length != 3) return null;
    final y = int.tryParse(d[0]);
    final m = int.tryParse(d[1]);
    final day = int.tryParse(d[2]);
    final amount = int.tryParse(parts[1]);
    if (y == null || m == null || day == null || amount == null) return null;
    final note = parts.length > 2 ? parts.sublist(2).join(' ') : '';
    return _Entry(DateTime(y, m, day), amount, note);
  }
}

const List<String> _monthsBn = [
  '',
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

/// ব্যক্তিগত দান-সদকার খাতা। সব হিসাব শুধু ফোনে সংরক্ষিত থাকে।
class SadaqaScreen extends StatefulWidget {
  const SadaqaScreen({super.key});

  @override
  State<SadaqaScreen> createState() => _SadaqaScreenState();
}

class _SadaqaScreenState extends State<SadaqaScreen> {
  static const String _key = 'sadaqa_v1';

  List<_Entry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final list = <_Entry>[];
    for (final raw in p.getStringList(_key) ?? <String>[]) {
      final e = _Entry.parse(raw);
      if (e != null) list.add(e);
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() {
      _entries = list;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, [for (final e in _entries) e.raw]);
  }

  Future<void> _add() async {
    final amountC = TextEditingController();
    final noteC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন দান যোগ করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountC,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'টাকার পরিমাণ (ইংরেজি অঙ্কে)'),
            ),
            TextField(
              controller: noteC,
              decoration: const InputDecoration(labelText: 'নোট (ঐচ্ছিক)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('যোগ করুন')),
        ],
      ),
    );
    final amount = int.tryParse(amountC.text.trim());
    final note = noteC.text.trim();
    amountC.dispose();
    noteC.dispose();
    if (ok != true || amount == null || amount <= 0) return;

    final now = DateTime.now();
    _entries.insert(0, _Entry(DateTime(now.year, now.month, now.day), amount, note));
    await _save();
    await _load();
  }

  Future<void> _delete(_Entry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('এই হিসাবটি মুছবেন?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('হ্যাঁ')),
        ],
      ),
    );
    if (ok != true) return;
    _entries.remove(e);
    await _save();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    var thisMonth = 0;
    var thisYear = 0;
    var all = 0;
    for (final e in _entries) {
      all += e.amount;
      if (e.date.year == now.year) {
        thisYear += e.amount;
        if (e.date.month == now.month) thisMonth += e.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('সদকার খাতা', style: TextStyle(fontWeight: FontWeight.bold))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('দান যোগ'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('${_monthsBn[now.month]} মাসে দান', style: const TextStyle(color: AppColors.subtle)),
                        const SizedBox(height: 4),
                        Text(
                          '৳ ${bn(thisMonth)}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'এ বছর ৳ ${bn(thisYear)}  •  মোট ৳ ${bn(all)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.subtle),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'এখনো কোনো হিসাব নেই। নিচের বাটন চেপে প্রথম দানটি যোগ করুন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.subtle, height: 1.5),
                    ),
                  ),
                for (final e in _entries)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.volunteer_activism_rounded, color: AppColors.accent),
                      title: Text('৳ ${bn(e.amount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${bn(e.date.day)} ${_monthsBn[e.date.month]} ${bn(e.date.year)}'
                        '${e.note.isEmpty ? '' : '  •  ${e.note}'}',
                      ),
                      trailing: IconButton(
                        tooltip: 'মুছুন',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _delete(e),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'এই হিসাব শুধু আপনার ফোনে থাকে, কোনো সার্ভারে যায় না।',
                  style: TextStyle(fontSize: 11.5, color: AppColors.subtle),
                ),
              ],
            ),
    );
  }
}
