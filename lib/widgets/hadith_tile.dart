import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/content_db.dart';

class HadithTile extends StatelessWidget {
  final HadithRow hadith;
  const HadithTile({super.key, required this.hadith});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'হাদিস নং: ${hadith.num}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
            if (hadith.arabic.isNotEmpty) ...[
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.rtl,
                child: SelectableText(
                  hadith.arabic,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 20, height: 1.9),
                ),
              ),
            ],
            const SizedBox(height: 10),
            SelectableText(hadith.bangla, style: const TextStyle(fontSize: 16, height: 1.6)),
          ],
        ),
      ),
    );
  }
}
