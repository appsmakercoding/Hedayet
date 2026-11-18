import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../data/islamic_data.dart';
import '../data/prayer_data.dart' show bn;
import '../data/surah_data.dart';
import '../services/content_db.dart';
import 'surah_screen.dart';
import 'web_screen.dart';

// ---------- সাহায্যকারী ----------

IconData _catIcon(String id) {
  switch (id) {
    case 'duas':
      return Icons.favorite_rounded;
    case 'quran_duas':
      return Icons.menu_book_rounded;
    case 'quran_verses':
      return Icons.auto_stories_rounded;
    case 'sunnah':
      return Icons.verified_rounded;
    case 'basics':
      return Icons.account_balance_rounded;
    case 'prophets':
      return Icons.groups_rounded;
    case 'hajj_umrah':
      return Icons.location_city_rounded;
    case 'islamic_names':
      return Icons.badge_rounded;
    case 'quran_learning':
      return Icons.school_rounded;
    default:
      return Icons.menu_book_rounded;
  }
}

Color _catColor(String id) {
  switch (id) {
    case 'duas':
      return Colors.pink.shade400;
    case 'quran_duas':
      return Colors.green.shade700;
    case 'quran_verses':
      return Colors.teal.shade600;
    case 'sunnah':
      return Colors.blue.shade600;
    case 'basics':
      return Colors.indigo.shade400;
    case 'prophets':
      return Colors.orange.shade700;
    case 'hajj_umrah':
      return Colors.brown.shade400;
    case 'islamic_names':
      return Colors.purple.shade400;
    default:
      return Colors.cyan.shade700;
  }
}

class _Ref {
  final int surah;
  final int from;
  final int to;
  const _Ref(this.surah, this.from, this.to);
}

_Ref? _parseRef(String ref) {
  final parts = ref.split(':');
  if (parts.length != 2) return null;
  final s = int.tryParse(parts[0]);
  if (s == null || s < 1 || s > kSurahs.length) return null;
  final range = parts[1].split('-');
  final a = int.tryParse(range[0]);
  final b = range.length > 1 ? int.tryParse(range[1]) : a;
  if (a == null || b == null) return null;
  return _Ref(s, a, b);
}

String _refLabel(String ref) {
  final r = _parseRef(ref);
  if (r == null) return ref;
  final name = kSurahs[r.surah - 1].nameBn;
  final tail = r.to != r.from ? '-${bn(r.to)}' : '';
  return 'সূরা $name: ${bn(r.from)}$tail';
}

// ---------- লাইব্রেরির মূল পাতা ----------

class IslamicLibraryScreen extends StatelessWidget {
  const IslamicLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ইসলামি লাইব্রেরি', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          for (final c in IslamicData.categories)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _catColor(c.id).withOpacity(0.16),
                  child: Icon(_catIcon(c.id), color: _catColor(c.id)),
                ),
                title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${c.subtitle} • ${bn(IslamicData.byCategory(c.id).length)}টি'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => IslamicListScreen(category: c)),
                ),
              ),
            ),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.amber.shade700.withOpacity(0.16),
                child: Icon(Icons.quiz_rounded, color: Colors.amber.shade700),
              ),
              title: const Text('ইসলামি কুইজ', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${bn(IslamicData.quiz.length)}টি প্রশ্ন থেকে প্রতিবার ১০টি'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueGrey.shade400.withOpacity(0.16),
                child: Icon(Icons.link_rounded, color: Colors.blueGrey.shade400),
              ),
              title: const Text('উৎস ও লিংক', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('বিস্তারিত পড়ার জন্য বাংলা বই ও ওয়েবসাইট'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SourcesScreen())),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- ক্যাটাগরির তালিকা (খোঁজাসহ) ----------

class IslamicListScreen extends StatefulWidget {
  final IslamicCategory category;
  const IslamicListScreen({super.key, required this.category});

  @override
  State<IslamicListScreen> createState() => _IslamicListScreenState();
}

class _IslamicListScreenState extends State<IslamicListScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = IslamicData.byCategory(widget.category.id);
    final q = _q.trim();
    final items = q.isEmpty
        ? all
        : all
            .where((e) =>
                e.title.contains(q) ||
                e.banglaMeaning.contains(q) ||
                e.banglaPronunciation.contains(q) ||
                e.reference.contains(q))
            .toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.title, style: const TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'খুঁজুন...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('কিছু পাওয়া যায়নি', style: TextStyle(color: AppColors.subtle)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final e = items[i];
                      final sub = e.quranRef.isNotEmpty
                          ? _refLabel(e.quranRef)
                          : (e.reference.isNotEmpty ? e.reference : e.banglaMeaning);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => IslamicDetailScreen(item: e)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------- বিস্তারিত পাতা ----------

class IslamicDetailScreen extends StatelessWidget {
  final IslamicItem item;
  const IslamicDetailScreen({super.key, required this.item});

  String _plainText() {
    final b = StringBuffer(item.title);
    if (item.arabicText.isNotEmpty) b.write('\n${item.arabicText}');
    if (item.banglaPronunciation.isNotEmpty) b.write('\nউচ্চারণ: ${item.banglaPronunciation}');
    if (item.quranRef.isEmpty) b.write('\nঅর্থ: ${item.banglaMeaning}');
    if (item.quranRef.isNotEmpty) b.write('\n${_refLabel(item.quranRef)}');
    if (item.reference.isNotEmpty) b.write('\nসূত্র: ${item.reference}');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বিস্তারিত', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'কপি করুন',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _plainText()));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('কপি হয়েছে')));
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (item.arabicText.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    item.arabicText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, height: 2.0),
                  ),
                ),
              ),
            ),
          if (item.banglaPronunciation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'উচ্চারণ: ${item.banglaPronunciation}',
              style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.accent),
            ),
          ],
          if (item.quranRef.isEmpty) ...[
            const SizedBox(height: 12),
            Text('অর্থ: ${item.banglaMeaning}', style: const TextStyle(fontSize: 16, height: 1.6)),
          ],
          if (item.quranRef.isNotEmpty) ...[
            const SizedBox(height: 4),
            _QuranRefView(refText: item.quranRef),
          ],
          if (item.reference.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.bookmark_border_rounded, size: 18, color: AppColors.subtle),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('সূত্র: ${item.reference}', style: const TextStyle(fontSize: 13.5, color: AppColors.subtle)),
                ),
              ],
            ),
          ],
          if (item.extraInfo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(item.extraInfo, style: const TextStyle(fontSize: 13, height: 1.5)),
              ),
            ),
          ],
          if (item.link.isNotEmpty) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WebScreen(title: item.title, url: item.link)),
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('বিস্তারিত উৎসে পড়ুন'),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'সূত্রের নম্বর ও বিষয়বস্তু আলেমের কাছে যাচাই করে নিন।',
            style: TextStyle(fontSize: 11.5, color: AppColors.subtle),
          ),
        ],
      ),
    );
  }
}

/// কুরআনের আয়াত (সূরা:আয়াত) অ্যাপে ডাউনলোড করা কুরআন থেকে এনে দেখায়।
class _QuranRefView extends StatefulWidget {
  final String refText;
  const _QuranRefView({required this.refText});

  @override
  State<_QuranRefView> createState() => _QuranRefViewState();
}

class _QuranRefViewState extends State<_QuranRefView> {
  late final _Ref? _ref;
  late final Future<List<VerseRow>> _future;

  @override
  void initState() {
    super.initState();
    _ref = _parseRef(widget.refText);
    _future = _load();
  }

  Future<List<VerseRow>> _load() async {
    final r = _ref;
    if (r == null) return <VerseRow>[];
    try {
      final all = await ContentDb.instance.getVerses(r.surah);
      return all.where((v) => v.ayah >= r.from && v.ayah <= r.to).toList();
    } catch (_) {
      return <VerseRow>[];
    }
  }

  void _openSurah() {
    final r = _ref;
    if (r == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurahScreen(surah: kSurahs[r.surah - 1], initialAyah: r.from)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VerseRow>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
        }
        final verses = snap.data ?? <VerseRow>[];
        if (verses.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_refLabel(widget.refText), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'আরবি, উচ্চারণ ও অর্থ দেখাতে কুরআনের ডেটা একবার ডাউনলোড করা দরকার। কুরআন অংশ খুলে ডাউনলোড করে আবার আসুন।',
                    style: TextStyle(fontSize: 13.5, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _openSurah,
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('কুরআনে খুলুন'),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final v in verses)
              Card(
                margin: const EdgeInsets.only(top: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_refLabel('${_ref!.surah}:${v.ayah}')}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                      const SizedBox(height: 6),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(v.arabic, style: const TextStyle(fontSize: 24, height: 2.0)),
                      ),
                      if (v.translit.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'উচ্চারণ: ${v.translit}',
                          style: const TextStyle(fontSize: 15.5, height: 1.6, color: AppColors.accent),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text('অর্থ: ${v.bangla}', style: const TextStyle(fontSize: 15.5, height: 1.6)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _openSurah,
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('সূরাটি পুরো পড়ুন'),
            ),
          ],
        );
      },
    );
  }
}

// ---------- কুইজ ----------

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizQuestion> _qs;
  int _i = 0;
  int _score = 0;
  int? _picked;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final list = List<QuizQuestion>.of(IslamicData.quiz)..shuffle();
    _qs = list.take(10).toList();
    _i = 0;
    _score = 0;
    _picked = null;
    _done = false;
  }

  void _pick(int idx) {
    if (_picked != null) return;
    setState(() {
      _picked = idx;
      if (idx == _qs[_i].answer) _score++;
    });
  }

  void _next() {
    setState(() {
      if (_i + 1 >= _qs.length) {
        _done = true;
      } else {
        _i++;
        _picked = null;
      }
    });
  }

  Color? _optionColor(int idx, QuizQuestion q) {
    if (_picked == null) return null;
    if (idx == q.answer) return Colors.green.withOpacity(0.25);
    if (idx == _picked) return Colors.red.withOpacity(0.25);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ইসলামি কুইজ', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _done ? _result() : _question(),
    );
  }

  Widget _result() {
    final total = _qs.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 72, color: AppColors.gold),
            const SizedBox(height: 12),
            Text('আপনার স্কোর: ${bn(_score)}/${bn(total)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
              onPressed: () => setState(_start),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('আবার খেলুন'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _question() {
    final q = _qs[_i];
    final isLast = _i + 1 >= _qs.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        LinearProgressIndicator(
          value: (_i + 1) / _qs.length,
          minHeight: 8,
          color: AppColors.accent,
          backgroundColor: AppColors.subtle.withOpacity(0.25),
        ),
        const SizedBox(height: 8),
        Text('প্রশ্ন ${bn(_i + 1)}/${bn(_qs.length)}', style: const TextStyle(color: AppColors.subtle)),
        const SizedBox(height: 12),
        Text(q.question, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, height: 1.5)),
        const SizedBox(height: 14),
        for (var k = 0; k < q.options.length; k++)
          Card(
            color: _optionColor(k, q),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(q.options[k], style: const TextStyle(fontSize: 16)),
              trailing: _picked == null
                  ? null
                  : (k == q.answer
                      ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                      : (k == _picked ? const Icon(Icons.cancel_rounded, color: Colors.red) : null)),
              onTap: () => _pick(k),
            ),
          ),
        if (_picked != null) ...[
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            onPressed: _next,
            child: Text(isLast ? 'ফলাফল দেখুন' : 'পরের প্রশ্ন'),
          ),
        ],
      ],
    );
  }
}

// ---------- উৎস ও লিংক ----------

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = <String>[];
    for (final s in IslamicData.sources) {
      if (!groups.contains(s.group)) groups.add(s.group);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('উৎস ও লিংক', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          for (final g in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
              child: Text(g, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent)),
            ),
            for (final s in IslamicData.sources)
              if (s.group == g)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.link_rounded),
                    title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(s.subtitle),
                    isThreeLine: s.subtitle.length > 60,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WebScreen(title: s.title, url: s.url)),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 10),
          const Text(
            'লিংকগুলো ইন্টারনেটে খোলে। বাইরের ওয়েবসাইটের লেখার দায় ওই সাইটের। PDF লিংক অ্যাপের ভেতরেই PDF ভিউয়ারে দেখাবে।',
            style: TextStyle(fontSize: 11.5, color: AppColors.subtle, height: 1.5),
          ),
        ],
      ),
    );
  }
}
