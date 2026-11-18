import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;

class _Dhikr {
  final String arabic;
  final String name;
  final int target;
  const _Dhikr(this.arabic, this.name, this.target);
}

const List<_Dhikr> _dhikrs = [
  _Dhikr('سُبْحَانَ ٱللَّهِ', 'সুবহানাল্লাহ', 33),
  _Dhikr('ٱلْحَمْدُ لِلَّهِ', 'আলহামদুলিল্লাহ', 33),
  _Dhikr('ٱللَّهُ أَكْبَرُ', 'আল্লাহু আকবার', 34),
  _Dhikr('لَا إِلَٰهَ إِلَّا ٱللَّهُ', 'লা ইলাহা ইল্লাল্লাহ', 100),
  _Dhikr('أَسْتَغْفِرُ ٱللَّهَ', 'আসতাগফিরুল্লাহ', 100),
  _Dhikr('', 'মুক্ত গণনা', 0),
];

/// ডিজিটাল তাসবীহ। প্রতিটি যিকিরের সংখ্যা আলাদা করে ফোনে সংরক্ষিত থাকে।
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _index = 0;
  final List<int> _counts = List<int>.filled(_dhikrs.length, 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _index = (prefs.getInt('tasbih_index') ?? 0).clamp(0, _dhikrs.length - 1);
      for (var i = 0; i < _dhikrs.length; i++) {
        _counts[i] = prefs.getInt('tasbih_$i') ?? 0;
      }
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_index', _index);
    await prefs.setInt('tasbih_$_index', _counts[_index]);
  }

  void _tap() {
    final d = _dhikrs[_index];
    setState(() => _counts[_index]++);
    if (d.target > 0 && _counts[_index] % d.target == 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    _save();
  }

  void _undo() {
    if (_counts[_index] == 0) return;
    setState(() => _counts[_index]--);
    _save();
  }

  void _reset() {
    setState(() => _counts[_index] = 0);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final d = _dhikrs[_index];
    final count = _counts[_index];
    final progress = d.target > 0 ? ((count % d.target) / d.target) : 0.0;
    final rounds = d.target > 0 ? count ~/ d.target : 0;
    return Scaffold(
      appBar: AppBar(title: const Text('তাসবীহ', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < _dhikrs.length; i++)
                  ChoiceChip(
                    label: Text(_dhikrs[i].name),
                    selected: i == _index,
                    onSelected: (_) {
                      setState(() => _index = i);
                      _save();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 22),
            if (d.arabic.isNotEmpty)
              Text(
                d.arabic,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30, height: 1.8, color: AppColors.gold),
              ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _tap,
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: d.target > 0 ? (progress == 0 && count > 0 ? 1.0 : progress) : 0,
                        strokeWidth: 10,
                        color: AppColors.accent,
                        backgroundColor: AppColors.subtle.withOpacity(0.25),
                      ),
                    ),
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bn(count),
                            style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            d.target > 0 ? 'লক্ষ্য: ${bn(d.target)}' : 'ট্যাপ করুন',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (d.target > 0)
              Text('পূর্ণ হয়েছে: ${bn(rounds)} বার', style: const TextStyle(color: AppColors.subtle)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _undo,
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('একটি কমান'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('শূন্য করুন'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
