import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;
import '../data/surah_data.dart';
import 'surah_screen.dart';

/// নির্বাচিত সূরার তালিকা (যেমন ছোট সূরা, জনপ্রিয় সূরা)।
class SurahListScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<int> numbers;

  const SurahListScreen({super.key, required this.title, required this.subtitle, required this.numbers});

  @override
  Widget build(BuildContext context) {
    final items = <SurahInfo>[];
    for (final n in numbers) {
      if (n >= 1 && n <= kSurahs.length) items.add(kSurahs[n - 1]);
    }
    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: items.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(subtitle, style: const TextStyle(color: AppColors.subtle, fontSize: 13)),
            );
          }
          final s = items[i - 1];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryGreen,
                child: Text(bn(s.number), style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              title: Text(s.nameBn, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${s.meaningBn} • আয়াত: ${bn(s.verses)}'),
              trailing: Text(s.nameAr, style: const TextStyle(fontSize: 20, color: AppColors.gold)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahScreen(surah: s))),
            ),
          );
        },
      ),
    );
  }
}
