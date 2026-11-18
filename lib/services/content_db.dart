import 'package:sqflite/sqflite.dart';

class VerseRow {
  final int surah;
  final int ayah;
  final String arabic;
  final String bangla;

  /// বাংলা হরফে উচ্চারণ (না থাকলে খালি)।
  final String translit;
  const VerseRow(this.surah, this.ayah, this.arabic, this.bangla, {this.translit = ''});
}

class HadithRow {
  final int id;
  final String num;
  final int book;
  final String arabic;
  final String bangla;
  const HadithRow(this.id, this.num, this.book, this.arabic, this.bangla);
}

class HadithBook {
  final int book;
  final String name;
  final int count;
  const HadithBook(this.book, this.name, this.count);
}

class SearchResult<T> {
  final int total;
  final List<T> items;
  const SearchResult(this.total, this.items);
}

/// ডাউনলোড করা কুরআন ও হাদিসের স্থানীয় ডেটাবেস। অফলাইনে পড়া ও খোঁজার জন্য।
class ContentDb {
  ContentDb._();
  static final ContentDb instance = ContentDb._();

  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      '$dir/hedayet_content.db',
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // পুরনো ইনস্টলে উচ্চারণের কলাম যোগ করা হয় এবং কুরআন খালি করা হয়,
          // ফলে অ্যাপ নিজেই আবার ডাউনলোডের কার্ড দেখাবে (উচ্চারণসহ)।
          await db.execute("ALTER TABLE quran ADD COLUMN translit TEXT NOT NULL DEFAULT ''");
          await db.delete('quran');
        }
      },
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE quran (surah INTEGER NOT NULL, ayah INTEGER NOT NULL, '
          'arabic TEXT NOT NULL, bangla TEXT NOT NULL, translit TEXT NOT NULL DEFAULT \'\', '
          'PRIMARY KEY (surah, ayah))',
        );
        await db.execute(
          'CREATE TABLE hadith (id INTEGER PRIMARY KEY AUTOINCREMENT, num TEXT NOT NULL, '
          'book INTEGER NOT NULL, arabic TEXT NOT NULL, bangla TEXT NOT NULL)',
        );
        await db.execute('CREATE INDEX idx_hadith_book ON hadith (book, id)');
        await db.execute('CREATE TABLE hadith_books (book INTEGER PRIMARY KEY, name TEXT NOT NULL)');
      },
    );
  }

  // ---------- অবস্থা ----------

  Future<bool> isQuranReady() async {
    final db = await _database;
    final n = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM quran'));
    return (n ?? 0) >= 6236;
  }

  Future<bool> isHadithReady() async {
    final db = await _database;
    final n = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM hadith'));
    return (n ?? 0) > 0;
  }

  // ---------- সংরক্ষণ ----------

  Future<void> replaceQuran(List<VerseRow> rows) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('quran');
      final batch = txn.batch();
      for (final r in rows) {
        batch.insert('quran', {
          'surah': r.surah,
          'ayah': r.ayah,
          'arabic': r.arabic,
          'bangla': r.bangla,
          'translit': r.translit,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> replaceHadith(Map<int, String> books, List<HadithRow> rows) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('hadith');
      await txn.delete('hadith_books');
      final batch = txn.batch();
      books.forEach((book, name) {
        batch.insert('hadith_books', {'book': book, 'name': name});
      });
      for (final r in rows) {
        batch.insert('hadith', {'num': r.num, 'book': r.book, 'arabic': r.arabic, 'bangla': r.bangla});
      }
      await batch.commit(noResult: true);
    });
  }

  // ---------- পড়া ----------

  Future<List<VerseRow>> getVerses(int surah) async {
    final db = await _database;
    final rows = await db.query('quran', where: 'surah = ?', whereArgs: [surah], orderBy: 'ayah');
    return rows
        .map((r) => VerseRow(
              r['surah'] as int,
              r['ayah'] as int,
              r['arabic'] as String,
              r['bangla'] as String,
              translit: (r['translit'] as String?) ?? '',
            ))
        .toList();
  }

  Future<List<HadithBook>> getHadithBooks() async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT h.book AS book, COALESCE(b.name, \'\') AS name, COUNT(*) AS cnt '
      'FROM hadith h LEFT JOIN hadith_books b ON b.book = h.book '
      'GROUP BY h.book ORDER BY h.book',
    );
    return rows.map((r) => HadithBook(r['book'] as int, r['name'] as String, r['cnt'] as int)).toList();
  }

  Future<List<HadithRow>> getHadiths(int book, {required int limit, required int offset}) async {
    final db = await _database;
    final rows = await db.query(
      'hadith',
      where: 'book = ?',
      whereArgs: [book],
      orderBy: 'id',
      limit: limit,
      offset: offset,
    );
    return rows.map(_hadithFrom).toList();
  }

  HadithRow _hadithFrom(Map<String, Object?> r) => HadithRow(
        r['id'] as int,
        r['num'] as String,
        r['book'] as int,
        r['arabic'] as String,
        r['bangla'] as String,
      );

  // ---------- অনুসন্ধান ----------

  static String _norm(String col) => "REPLACE(REPLACE($col,'ী','ি'),'ূ','ু')";

  Future<SearchResult<VerseRow>> searchQuran(List<String> variants, {int limit = 40}) async {
    final db = await _database;
    final where = variants.map((_) => '${_norm('bangla')} LIKE ?').join(' OR ');
    final args = variants.map((v) => '%$v%').toList();
    final total = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM quran WHERE $where', args)) ?? 0;
    final rows = await db.rawQuery(
      'SELECT surah, ayah, arabic, bangla FROM quran WHERE $where ORDER BY surah, ayah LIMIT $limit',
      args,
    );
    final items = rows
        .map((r) => VerseRow(r['surah'] as int, r['ayah'] as int, r['arabic'] as String, r['bangla'] as String))
        .toList();
    return SearchResult(total, items);
  }

  Future<SearchResult<HadithRow>> searchHadith(List<String> variants, {int limit = 40}) async {
    final db = await _database;
    final where = variants.map((_) => '${_norm('bangla')} LIKE ?').join(' OR ');
    final args = variants.map((v) => '%$v%').toList();
    final total = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM hadith WHERE $where', args)) ?? 0;
    final rows = await db.rawQuery(
      'SELECT id, num, book, arabic, bangla FROM hadith WHERE $where ORDER BY id LIMIT $limit',
      args,
    );
    return SearchResult(total, rows.map(_hadithFrom).toList());
  }
}
