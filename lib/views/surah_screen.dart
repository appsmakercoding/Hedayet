import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';
import '../core/content_config.dart';
import '../data/prayer_data.dart' show bn;
import '../data/surah_data.dart';
import '../services/bookmark_store.dart';
import '../services/content_db.dart';
import '../services/content_downloader.dart';
import '../widgets/audio_bar.dart';
import '../widgets/download_card.dart';

const String _bismillahTranslit = 'বিসমিল্লাহির রাহমানির রাহীম';

class SurahScreen extends StatefulWidget {
  final SurahInfo surah;

  /// বুকমার্ক থেকে খুললে এই আয়াতের কাছাকাছি স্ক্রল করে।
  final int? initialAyah;
  const SurahScreen({super.key, required this.surah, this.initialAyah});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  late Future<List<VerseRow>> _future;
  double _arabicSize = 26;
  final ScrollController _scroll = ScrollController();
  Set<int> _marked = <int>{};
  bool _jumped = false;

  /// হিফজ মোড: আরবি লুকানো থাকে, মুখস্থ বলে ট্যাপ করে মিলিয়ে নিতে হয়।
  bool _hifz = false;
  final Set<int> _revealed = <int>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
    _loadFontSize();
    BookmarkStore.setLast(widget.surah.number);
    _loadMarks();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMarks() async {
    final all = await BookmarkStore.all();
    if (!mounted) return;
    setState(() {
      _marked = all.where((e) => e.surah == widget.surah.number).map((e) => e.ayah).toSet();
    });
  }

  Future<void> _toggleMark(int ayah) async {
    await BookmarkStore.toggle(widget.surah.number, ayah);
    await _loadMarks();
  }

  void _jumpToInitial() {
    final a = widget.initialAyah;
    if (_jumped || a == null || !mounted || !_scroll.hasClients) return;
    _jumped = true;
    final target = ((a - 1) * 330.0).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.jumpTo(target);
  }

  Future<List<VerseRow>> _load() async {
    try {
      final rows = await ContentDb.instance.getVerses(widget.surah.number);
      if (rows.isNotEmpty && widget.initialAyah != null) {
        Future.delayed(const Duration(milliseconds: 500), _jumpToInitial);
      }
      return rows;
    } catch (_) {
      return <VerseRow>[];
    }
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getDouble('quran_arabic_size');
    if (v != null && mounted) setState(() => _arabicSize = v);
  }

  Future<void> _changeSize(double delta) async {
    final next = (_arabicSize + delta).clamp(20.0, 44.0);
    setState(() => _arabicSize = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_arabic_size', next);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.surah;
    final showBismillah = s.number != 1 && s.number != 9;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.nameBn, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: _hifz ? 'হিফজ মোড বন্ধ করুন' : 'হিফজ মোড: আরবি লুকিয়ে নিজেকে পরীক্ষা করুন',
            icon: Icon(_hifz ? Icons.visibility_rounded : Icons.visibility_off_rounded),
            onPressed: () => setState(() {
              _hifz = !_hifz;
              _revealed.clear();
            }),
          ),
          IconButton(
            tooltip: 'লেখা ছোট করুন',
            icon: const Icon(Icons.text_decrease),
            onPressed: () => _changeSize(-2),
          ),
          IconButton(
            tooltip: 'লেখা বড় করুন',
            icon: const Icon(Icons.text_increase),
            onPressed: () => _changeSize(2),
          ),
        ],
      ),
      bottomNavigationBar: AudioBar(url: ContentConfig.audioUrl(s.number), title: 'সূরা ${s.nameBn}', surah: s.number),
      body: FutureBuilder<List<VerseRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final verses = snapshot.data ?? <VerseRow>[];
          if (verses.isEmpty) {
            return ListView(
              children: [
                DownloadCard(
                  title: 'কুরআনের ডেটা নেই',
                  description: 'সূরা পড়তে আরবি টেক্সট, বাংলা অনুবাদ ও বাংলা উচ্চারণ একবার ডাউনলোড করুন। অডিও নিচের বাটনে এখনই শোনা যাবে।',
                  action: ContentDownloader.downloadQuran,
                  onDone: _reload,
                ),
              ],
            );
          }
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: verses.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Text(
                        '${s.nameAr}  •  ${s.meaningBn}  •  আয়াত ${bn(s.verses)}',
                        style: const TextStyle(color: AppColors.subtle, fontSize: 13),
                      ),
                      if (showBismillah)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            AppConstants.bismillah,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: _arabicSize, color: AppColors.accent),
                          ),
                        ),
                      if (showBismillah)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            _bismillahTranslit,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: AppColors.accent),
                          ),
                        ),
                    ],
                  ),
                );
              }
              if (index == verses.length + 1) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(ContentConfig.quranCredit, style: TextStyle(fontSize: 11, color: AppColors.subtle)),
                );
              }
              final v = verses[index - 1];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primaryGreen,
                            child: Text(bn(v.ayah), style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                          const Spacer(),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: _marked.contains(v.ayah) ? 'বুকমার্ক মুছুন' : 'বুকমার্ক করুন',
                            icon: Icon(
                              _marked.contains(v.ayah) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: _marked.contains(v.ayah) ? AppColors.gold : AppColors.subtle,
                            ),
                            onPressed: () => _toggleMark(v.ayah),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_hifz && !_revealed.contains(v.ayah))
                        InkWell(
                          onTap: () => setState(() => _revealed.add(v.ayah)),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'আরবি লুকানো আছে। মুখস্থ বলে ট্যাপ করে মিলিয়ে নিন।',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.accent),
                            ),
                          ),
                        )
                      else ...[
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: SelectableText(
                          v.arabic,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: _arabicSize, height: 2.0),
                        ),
                      ),
                      if (v.translit.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SelectableText(
                          'উচ্চারণ: ${v.translit}',
                          style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.accent),
                        ),
                      ],
                      ],
                      const SizedBox(height: 10),
                      SelectableText('অর্থ: ${v.bangla}', style: const TextStyle(fontSize: 16, height: 1.6)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
