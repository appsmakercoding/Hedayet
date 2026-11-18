import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;

const List<MapEntry<String, String>> _qazaItems = [
  MapEntry('fajr', 'ফজর'),
  MapEntry('zuhr', 'যোহর'),
  MapEntry('asr', 'আসর'),
  MapEntry('maghrib', 'মাগরিব'),
  MapEntry('isha', 'এশা'),
  MapEntry('witr', 'বিতর'),
];

/// কাযা নামাজের হিসাব। সংখ্যাগুলো শুধু ফোনে সংরক্ষিত থাকে।
class QazaScreen extends StatefulWidget {
  const QazaScreen({super.key});

  @override
  State<QazaScreen> createState() => _QazaScreenState();
}

class _QazaScreenState extends State<QazaScreen> {
  final Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    for (final e in _qazaItems) {
      _counts[e.key] = p.getInt('qaza_${e.key}') ?? 0;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _set(String key, int value) async {
    final v = value < 0 ? 0 : (value > 99999 ? 99999 : value);
    final p = await SharedPreferences.getInstance();
    await p.setInt('qaza_$key', v);
    if (!mounted) return;
    setState(() => _counts[key] = v);
  }

  Future<void> _edit(String key, String name) async {
    final c = TextEditingController(text: '${_counts[key] ?? 0}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$name: কাযার সংখ্যা'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'সংখ্যা লিখুন (ইংরেজি অঙ্কে)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(c.text.trim())),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
    c.dispose();
    if (result != null) await _set(key, result);
  }

  @override
  Widget build(BuildContext context) {
    var total = 0;
    for (final v in _counts.values) {
      total += v;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('কাযা নামাজ', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('মোট কাযা বাকি', style: TextStyle(color: AppColors.subtle)),
                        const SizedBox(height: 4),
                        Text(
                          '${bn(total)} ওয়াক্ত',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'যত ওয়াক্ত কাযা আছে সংখ্যায় ট্যাপ করে বসান। কাযা আদায় করলে বিয়োগ (−) চাপুন।',
                  style: TextStyle(fontSize: 13, color: AppColors.subtle, height: 1.5),
                ),
                const SizedBox(height: 8),
                for (final e in _qazaItems)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(e.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          IconButton(
                            tooltip: 'একটি আদায় হয়েছে',
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            onPressed: (_counts[e.key] ?? 0) <= 0 ? null : () => _set(e.key, (_counts[e.key] ?? 0) - 1),
                          ),
                          InkWell(
                            onTap: () => _edit(e.key, e.value),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 56),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              alignment: Alignment.center,
                              child: Text(
                                bn(_counts[e.key] ?? 0),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'একটি কাযা যোগ করুন',
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: () => _set(e.key, (_counts[e.key] ?? 0) + 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'কাযা নামাজের নিয়ম ও হিসাব নিয়ে বিশ্বস্ত আলেমের পরামর্শ নিন। এই সংখ্যা শুধু আপনার ফোনে থাকে।',
                  style: TextStyle(fontSize: 11.5, color: AppColors.subtle, height: 1.5),
                ),
              ],
            ),
    );
  }
}
