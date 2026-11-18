import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;
import '../data/surah_data.dart';
import '../services/bookmark_store.dart';
import '../services/content_db.dart';
import 'surah_screen.dart';

class _Item {
  final BookmarkEntry entry;
  final VerseRow? verse;
  const _Item(this.entry, this.verse);
}

/// বুকমার্ক করা আয়াত ও শেষ পড়া সূরা।
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<_Item> _items = [];
  int? _last;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await BookmarkStore.all();
    final last = await BookmarkStore.lastSurah();
    final cache = <int, List<VerseRow>>{};
    final items = <_Item>[];
    for (final e in entries) {
      List<VerseRow> verses = cache[e.surah] ?? <VerseRow>[];
      if (!cache.containsKey(e.surah)) {
        try {
          verses = await ContentDb.instance.getVerses(e.surah);
        } catch (_) {
          verses = <VerseRow>[];
        }
        cache[e.surah] = verses;
      }
      VerseRow? found;
      for (final v in verses) {
        if (v.ayah == e.ayah) found = v;
      }
      items.add(_Item(e, found));
    }
    items.sort((a, b) {
      final c = a.entry.surah.compareTo(b.entry.surah);
      return c != 0 ? c : a.entry.ayah.compareTo(b.entry.ayah);
    });
    if (!mounted) return;
    setState(() {
      _items = items;
      _last = last;
      _loading = false;
    });
  }

  Future<void> _remove(BookmarkEntry e) async {
    await BookmarkStore.toggle(e.surah, e.ayah);
    await _load();
  }

  Future<void> _open(int surah, {int? ayah}) async {
    if (surah < 1 || surah > kSurahs.length) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurahScreen(surah: kSurahs[surah - 1], initialAyah: ayah)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('বুকমার্ক', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                if (_last != null && _last! >= 1 && _last! <= kSurahs.length)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history_rounded, color: AppColors.gold),
                      title: Text('শেষ পড়া: সূরা ${kSurahs[_last! - 1].nameBn}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('চাপলে আবার খুলবে'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _open(_last!),
                    ),
                  ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'এখনো কোনো আয়াত বুকমার্ক করা হয়নি। সূরা পড়ার সময় আয়াতের ডানে বুকমার্ক আইকনে চাপ দিন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.subtle),
                    ),
                  ),
                for (final it in _items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _open(it.entry.surah, ayah: it.entry.ayah),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'সূরা ${kSurahs[it.entry.surah - 1].nameBn} • আয়াত ${bn(it.entry.ayah)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'বুকমার্ক মুছুন',
                                  icon: const Icon(Icons.bookmark_remove_rounded, color: AppColors.subtle),
                                  onPressed: () => _remove(it.entry),
                                ),
                              ],
                            ),
                            if (it.verse != null) ...[
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  it.verse!.arabic,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 20, height: 1.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Text(
                                  it.verse!.bangla,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, color: AppColors.subtle),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
