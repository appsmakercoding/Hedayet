import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;
import '../services/content_db.dart';
import '../services/content_downloader.dart';
import '../widgets/download_card.dart';
import 'hadith_book_screen.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  bool _loading = true;
  List<HadithBook> _books = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<HadithBook> books = [];
    try {
      if (await ContentDb.instance.isHadithReady()) {
        books = await ContentDb.instance.getHadithBooks();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সহীহ বুখারী', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? ListView(
                  children: [
                    DownloadCard(
                      title: 'হাদিসের ডেটা ডাউনলোড করুন',
                      description:
                          'সহীহ বুখারীর আরবি ও বাংলা হাদিস একবার নামালে পরে ইন্টারনেট ছাড়াই পড়তে পারবেন (প্রায় ১০–১৫ MB)। '
                          'ওয়াইফাই থাকলে ভালো।',
                      action: ContentDownloader.downloadHadith,
                      onDone: _load,
                    ),
                  ],
                )
              : ListView.separated(
                  itemCount: _books.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final b = _books[i];
                    final name = b.name.isEmpty ? 'অধ্যায় ${bn(b.book)}' : b.name;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryGreen,
                        child: Text(bn(b.book), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('হাদিস সংখ্যা: ${bn(b.count)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HadithBookScreen(book: b.book, title: name)),
                      ),
                    );
                  },
                ),
    );
  }
}
