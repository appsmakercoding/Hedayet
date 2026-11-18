import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart';

class PrayerDetailScreen extends StatelessWidget {
  final PrayerInfo prayer;
  const PrayerDetailScreen({super.key, required this.prayer});

  Widget _surahBlock(String title, List<SurahSuggestion> list) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.accent)),
          const SizedBox(height: 6),
          for (int i = 0; i < list.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${bn(i + 1)}ম রাকাত: ${list[i].label}', style: const TextStyle(fontSize: 15)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${prayer.name} নামাজ', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('রাকাতের বিবরণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 10),
                  for (final r in prayer.rakats)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r, style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('প্রস্তাবিত সূরা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  const Text(
                    'সূরা ফাতিহার পর, কুরআনের ক্রম বজায় রেখে (আগে বড়, পরে ছোট)।',
                    style: TextStyle(fontSize: 13, color: AppColors.subtle),
                  ),
                  const SizedBox(height: 12),
                  _surahBlock('সুন্নত নামাজে', prayer.sunnahPair),
                  _surahBlock('ফরজ নামাজে', prayer.fardPair),
                  if (prayer.witr.isNotEmpty) _surahBlock('বিতর নামাজে', prayer.witr),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'তালিকাটি হানাফি ফিকহের প্রচলিত নিয়ম অনুযায়ী সাজানো। কোনো প্রশ্ন থাকলে স্থানীয় আলেমের পরামর্শ নিন।',
            style: TextStyle(fontSize: 12, color: AppColors.subtle),
          ),
        ],
      ),
    );
  }
}
