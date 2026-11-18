import 'package:shared_preferences/shared_preferences.dart';

class BookmarkEntry {
  final int surah;
  final int ayah;
  const BookmarkEntry(this.surah, this.ayah);
}

/// আয়াতের বুকমার্ক ও "শেষ পড়া সূরা" ফোনে সংরক্ষণ করে।
class BookmarkStore {
  BookmarkStore._();

  static const String _kList = 'bookmarks_v1';
  static const String _kLast = 'last_read_surah';

  static Future<List<BookmarkEntry>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kList) ?? <String>[];
    final out = <BookmarkEntry>[];
    for (final s in raw) {
      final parts = s.split(':');
      if (parts.length != 2) continue;
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      if (a != null && b != null) out.add(BookmarkEntry(a, b));
    }
    return out;
  }

  /// বুকমার্ক থাকলে মুছে, না থাকলে যোগ করে। নতুন অবস্থা (true = বুকমার্ক আছে) ফেরত দেয়।
  static Future<bool> toggle(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kList) ?? <String>[];
    final key = '$surah:$ayah';
    final marked = !raw.contains(key);
    if (marked) {
      raw.add(key);
    } else {
      raw.remove(key);
    }
    await prefs.setStringList(_kList, raw);
    return marked;
  }

  static Future<void> setLast(int surah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLast, surah);
  }

  static Future<int?> lastSurah() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kLast);
  }
}
