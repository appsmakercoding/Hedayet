import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;
import '../data/surah_data.dart';
import '../services/content_db.dart';
import '../services/content_downloader.dart';
import '../widgets/download_card.dart';
import 'surah_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  bool _ready = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    bool ready = true;
    try {
      ready = await ContentDb.instance.isQuranReady();
    } catch (_) {
      ready = false;
    }
    if (mounted) setState(() => _ready = ready);
  }

  List<SurahInfo> get _filtered {
    final q = _filter.trim();
    if (q.isEmpty) return kSurahs;
    return kSurahs.where((s) {
      return s.nameBn.contains(q) || s.meaningBn.contains(q) || '${s.number}' == q || bn(s.number) == q;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('আল কুরআন', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          if (!_ready)
            DownloadCard(
              title: 'কুরআনের ডেটা ডাউনলোড করুন',
              description:
                  'আরবি টেক্সট, বাংলা অনুবাদ ও বাংলা উচ্চারণ একবার নামালে পরে ইন্টারনেট ছাড়াই পড়তে পারবেন (প্রায় ৬–৭ MB)। '
                  'ডাউনলোড ছাড়াও সূরার অডিও অনলাইনে শোনা যায়।',
              action: ContentDownloader.downloadQuran,
              onDone: _check,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              onChanged: (v) => setState(() => _filter = v),
              decoration: InputDecoration(
                hintText: 'সূরার নাম বা নম্বর লিখুন',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = list[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryGreen,
                    child: Text(bn(s.number), style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  title: Text(s.nameBn, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${s.meaningBn} • আয়াত: ${bn(s.verses)}'),
                  trailing: Text(s.nameAr, style: const TextStyle(fontSize: 20, color: AppColors.accent)),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SurahScreen(surah: s)),
                    );
                    _check();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
