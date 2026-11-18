import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;
import '../data/surah_data.dart';
import '../services/content_db.dart';
import '../widgets/hadith_tile.dart';
import 'hadith_screen.dart';
import 'quran_screen.dart';
import 'surah_screen.dart';

/// কুরআন ও হাদিসের ডেটাবেসে বাংলা শব্দ দিয়ে খোঁজা (ডাউনলোডের পর অফলাইনেও চলে)।
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _quranReady = false;
  bool _hadithReady = false;
  bool _searching = false;
  bool _searched = false;
  SearchResult<VerseRow>? _quran;
  SearchResult<HadithRow>? _hadith;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    bool q = false;
    bool h = false;
    try {
      q = await ContentDb.instance.isQuranReady();
      h = await ContentDb.instance.isHadithReady();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _quranReady = q;
      _hadithReady = h;
    });
  }

  /// "কুরবানী"/"কোরবানী" এর মতো বানানভেদ ধরার জন্য কয়েকটি রূপ।
  List<String> _variants(String q) {
    final set = <String>{q, q.replaceAll('কুর', 'কোর'), q.replaceAll('কোর', 'কুর')};
    return set.map((e) => e.replaceAll('ী', 'ি').replaceAll('ূ', 'ু')).toSet().toList();
  }

  Future<void> _search() async {
    final q = _controller.text.trim().replaceAll('%', '').replaceAll('_', '');
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _error = '';
    });
    try {
      final variants = _variants(q);
      final quran = _quranReady ? await ContentDb.instance.searchQuran(variants) : null;
      final hadith = _hadithReady ? await ContentDb.instance.searchHadith(variants) : null;
      if (!mounted) return;
      setState(() {
        _quran = quran;
        _hadith = hadith;
        _searched = true;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'অনুসন্ধান করা যায়নি: $e';
        _searching = false;
      });
    }
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent)),
      );

  Widget _quranHit(VerseRow v) {
    final info = kSurahs.firstWhere((s) => s.number == v.surah, orElse: () => kSurahs.first);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahScreen(surah: info))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('সূরা ${info.nameBn}, আয়াত ${bn(v.ayah)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(v.arabic, textAlign: TextAlign.right, style: const TextStyle(fontSize: 20, height: 1.9)),
              ),
              const SizedBox(height: 8),
              Text(v.bangla, style: const TextStyle(fontSize: 15, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noData = !_quranReady && !_hadithReady;
    return Scaffold(
      appBar: AppBar(title: const Text('অনুসন্ধান', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'যেমন: কুরবানী, নামাজ, সবর',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          if (noData)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'অনুসন্ধানের জন্য আগে কুরআন ও হাদিসের ডেটা একবার ডাউনলোড করতে হবে।',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen()))
                            .then((_) => _refresh()),
                        child: const Text('কুরআন ডাউনলোড'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithScreen()))
                            .then((_) => _refresh()),
                        child: const Text('হাদিস ডাউনলোড'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      children: [
                        if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
                        if (!_searched && _error.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('একটি শব্দ লিখে খুঁজুন। কুরআন ও হাদিস দুটোতেই খোঁজা হবে।',
                                style: TextStyle(color: AppColors.subtle)),
                          ),
                        if (_searched && _quran != null) ...[
                          _sectionTitle('কুরআন: ${bn(_quran!.total)}টি ফল'
                              '${_quran!.total > _quran!.items.length ? ' (প্রথম ${bn(_quran!.items.length)}টি)' : ''}'),
                          for (final v in _quran!.items) _quranHit(v),
                        ],
                        if (_searched && _hadith != null) ...[
                          _sectionTitle('হাদিস: ${bn(_hadith!.total)}টি ফল'
                              '${_hadith!.total > _hadith!.items.length ? ' (প্রথম ${bn(_hadith!.items.length)}টি)' : ''}'),
                          for (final h in _hadith!.items) HadithTile(hadith: h),
                        ],
                        if (_searched && !_quranReady)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('কুরআনের ডেটা ডাউনলোড করা নেই, তাই কুরআনে খোঁজা হয়নি।',
                                style: TextStyle(color: AppColors.subtle, fontSize: 13)),
                          ),
                        if (_searched && !_hadithReady)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('হাদিসের ডেটা ডাউনলোড করা নেই, তাই হাদিসে খোঁজা হয়নি।',
                                style: TextStyle(color: AppColors.subtle, fontSize: 13)),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
