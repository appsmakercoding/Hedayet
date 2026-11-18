import 'package:flutter/material.dart';

import '../core/app_colors.dart';

import '../core/content_config.dart';
import '../services/content_db.dart';
import '../widgets/hadith_tile.dart';

/// একটি অধ্যায়ের হাদিস ধারাবাহিকভাবে; স্ক্রল করলে আরও লোড হয়।
class HadithBookScreen extends StatefulWidget {
  final int book;
  final String title;
  const HadithBookScreen({super.key, required this.book, required this.title});

  @override
  State<HadithBookScreen> createState() => _HadithBookScreenState();
}

class _HadithBookScreenState extends State<HadithBookScreen> {
  static const int _pageSize = 30;
  final ScrollController _controller = ScrollController();
  final List<HadithRow> _items = [];
  bool _loading = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >= _controller.position.maxScrollExtent - 400) {
        _loadMore();
      }
    });
    _loadMore();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || _done) return;
    setState(() => _loading = true);
    List<HadithRow> page = [];
    try {
      page = await ContentDb.instance.getHadiths(widget.book, limit: _pageSize, offset: _items.length);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _items.addAll(page);
      if (page.length < _pageSize) _done = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      body: ListView.builder(
        controller: _controller,
        padding: const EdgeInsets.all(12),
        itemCount: _items.length + 1,
        itemBuilder: (context, i) {
          if (i < _items.length) return HadithTile(hadith: _items[i]);
          if (_loading) {
            return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
          }
          if (_done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(ContentConfig.hadithCredit, style: TextStyle(fontSize: 11, color: AppColors.subtle)),
            );
          }
          return const SizedBox(height: 40);
        },
      ),
    );
  }
}
