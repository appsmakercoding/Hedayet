import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/bangla_translit.dart';
import '../core/content_config.dart';
import '../data/prayer_data.dart' show bn;
import 'content_db.dart';

typedef ProgressCallback = void Function(String message);

/// কুরআন ও হাদিসের ডেটা একবার ইন্টারনেট থেকে নামিয়ে ফোনের ডেটাবেসে রাখে।
class ContentDownloader {
  // ---------- নেটওয়ার্ক ----------

  static Future<String> _getText(String base, String name, String label, ProgressCallback onProgress) async {
    Object? lastError;
    for (final url in ['$base/$name.min.json', '$base/$name.json']) {
      try {
        return await _download(url, label, onProgress);
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('$label নামানো যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন। ($lastError)');
  }

  static Future<String> _download(String url, String label, ProgressCallback onProgress) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 40));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 40))) {
        bytes.addAll(chunk);
        onProgress('$label নামছে… ${bn((bytes.length / 1024).round())} KB');
      }
      return utf8.decode(bytes);
    } finally {
      client.close(force: true);
    }
  }

  // ---------- কুরআন ----------

  static Future<void> downloadQuran(ProgressCallback onProgress) async {
    List<dynamic>? arabic;
    Object? lastError;
    for (final name in ContentConfig.arabicQuranEditions) {
      try {
        final body = await _getText(ContentConfig.quranBase, name, 'আরবি টেক্সট', onProgress);
        onProgress('আরবি টেক্সট যাচাই হচ্ছে…');
        final rows = await compute(_parseQuranEdition, body);
        if (rows.length == 6236) {
          arabic = rows;
          break;
        }
        lastError = 'আয়াত সংখ্যা ${bn(rows.length)} পাওয়া গেছে, ৬২৩৬ হওয়ার কথা';
      } catch (e) {
        lastError = e;
      }
    }
    if (arabic == null) {
      throw Exception('আরবি টেক্সট পাওয়া যায়নি: $lastError');
    }

    final bnBody = await _getText(ContentConfig.quranBase, ContentConfig.banglaQuranEdition, 'বাংলা অনুবাদ', onProgress);
    onProgress('বাংলা অনুবাদ যাচাই হচ্ছে…');
    final bangla = await compute(_parseQuranEdition, bnBody);
    if (bangla.length != 6236) {
      throw Exception('বাংলা অনুবাদে আয়াত সংখ্যা ${bn(bangla.length)}, ৬২৩৬ হওয়ার কথা');
    }

    final banglaMap = <String, String>{};
    for (final r in bangla) {
      final m = r as Map;
      banglaMap['${m['s']}:${m['a']}'] = m['t'] as String;
    }

    final translitRows = await _downloadTranslit(onProgress);
    final translitMap = <String, String>{};
    for (final r in translitRows) {
      final m = r as Map;
      translitMap['${m['s']}:${m['a']}'] = m['t'] as String;
    }

    final rows = <VerseRow>[];
    for (final r in arabic) {
      final m = r as Map;
      final s = m['s'] as int;
      final a = m['a'] as int;
      final translation = banglaMap['$s:$a'];
      if (translation == null) {
        throw Exception('বাংলা অনুবাদে সূরা ${bn(s)} আয়াত ${bn(a)} পাওয়া যায়নি');
      }
      rows.add(VerseRow(
        s,
        a,
        _cleanArabic(s, a, m['t'] as String),
        translation.trim(),
        translit: translitMap['$s:$a'] ?? '',
      ));
    }

    onProgress('ফোনে সংরক্ষণ হচ্ছে…');
    await ContentDb.instance.replaceQuran(rows);
  }

  /// ইংরেজি উচ্চারণ নামিয়ে বাংলা হরফে রূপান্তর করে ({s, a, t} তালিকা ফেরত দেয়)।
  static Future<List<dynamic>> _downloadTranslit(ProgressCallback onProgress) async {
    Object? lastError;
    for (final url in ContentConfig.translitUrls) {
      try {
        final body = await _download(url, 'উচ্চারণ', onProgress);
        onProgress('উচ্চারণ বাংলায় রূপান্তর হচ্ছে…');
        final rows = await compute(_parseTranslit, body);
        if (rows.length == 6236) return rows;
        lastError = 'উচ্চারণে আয়াত সংখ্যা ${bn(rows.length)} পাওয়া গেছে, ৬২৩৬ হওয়ার কথা';
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('উচ্চারণ নামানো যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন। ($lastError)');
  }

  // ---------- হাদিস ----------

  static Future<void> downloadHadith(ProgressCallback onProgress) async {
    final bnBody = await _getText(ContentConfig.hadithBase, ContentConfig.banglaHadithEdition, 'হাদিস (বাংলা)', onProgress);
    onProgress('বাংলা হাদিস যাচাই হচ্ছে…');
    final bnData = await compute(_parseHadithEdition, bnBody) as Map;

    final arBody = await _getText(ContentConfig.hadithBase, ContentConfig.arabicHadithEdition, 'হাদিস (আরবি)', onProgress);
    onProgress('আরবি হাদিস যাচাই হচ্ছে…');
    final arData = await compute(_parseHadithEdition, arBody) as Map;

    final arabicByNum = <String, String>{};
    for (final r in (arData['items'] as List)) {
      final m = r as Map;
      arabicByNum[m['num'] as String] = m['text'] as String;
    }

    final books = <int, String>{};
    (bnData['books'] as Map).forEach((k, v) {
      final n = int.tryParse('$k');
      if (n != null) books[n] = '$v';
    });

    final rows = <HadithRow>[];
    for (final r in (bnData['items'] as List)) {
      final m = r as Map;
      final number = m['num'] as String;
      rows.add(HadithRow(0, number, m['book'] as int, (arabicByNum[number] ?? '').trim(), (m['text'] as String).trim()));
    }
    if (rows.isEmpty) {
      throw Exception('হাদিসের তালিকা খালি এসেছে');
    }

    onProgress('ফোনে সংরক্ষণ হচ্ছে…');
    await ContentDb.instance.replaceHadith(books, rows);
  }

  // ---------- আরবি পরিষ্কার ----------

  /// কিছু উৎসে প্রতিটি সূরার ১ম আয়াতের শুরুতে বিসমিল্লাহ জুড়ে থাকে; সেটি আলাদা দেখানো হয়, তাই এখানে বাদ দেওয়া হয়।
  static String _cleanArabic(int surah, int ayah, String text) {
    final t = text.trim();
    if (ayah != 1 || surah == 1) return t;
    final words = t.split(RegExp(r'\s+'));
    if (words.length < 5) return t;
    const target = ['بسم', 'الله', 'الرحمن', 'الرحيم'];
    for (var i = 0; i < 4; i++) {
      if (_plain(words[i]) != target[i]) return t;
    }
    return words.sublist(4).join(' ');
  }

  static String _plain(String word) {
    final sb = StringBuffer();
    for (final r in word.runes) {
      final isMark = (r >= 0x064B && r <= 0x065F) ||
          r == 0x0670 ||
          r == 0x0640 ||
          (r >= 0x06D6 && r <= 0x06ED) ||
          (r >= 0x08D3 && r <= 0x08FF);
      if (isMark) continue;
      sb.writeCharCode(r == 0x0671 ? 0x0627 : r);
    }
    return sb.toString();
  }
}

// ---------- আলাদা থ্রেডে JSON পড়ার ফাংশন (top-level হতে হয়) ----------

List<dynamic> _parseQuranEdition(String body) {
  final data = jsonDecode(body) as Map<String, dynamic>;
  final list = data['quran'] as List<dynamic>;
  final out = <dynamic>[];
  for (final e in list) {
    final m = e as Map<String, dynamic>;
    out.add({
      's': (m['chapter'] as num).toInt(),
      'a': (m['verse'] as num).toInt(),
      't': (m['text'] ?? '') as String,
    });
  }
  return out;
}

List<dynamic> _parseTranslit(String body) {
  final data = jsonDecode(body) as List<dynamic>;
  final out = <dynamic>[];
  for (final c in data) {
    final chapter = c as Map<String, dynamic>;
    final s = (chapter['id'] as num).toInt();
    for (final v in (chapter['verses'] as List<dynamic>)) {
      final m = v as Map<String, dynamic>;
      final latin = (m['transliteration'] ?? '') as String;
      final arabic = (m['text'] ?? '') as String;
      out.add({
        's': s,
        'a': (m['id'] as num).toInt(),
        't': BanglaTranslit.convert(latin, arabic),
      });
    }
  }
  return out;
}

Object _parseHadithEdition(String body) {
  final data = jsonDecode(body) as Map<String, dynamic>;
  final meta = (data['metadata'] ?? <String, dynamic>{}) as Map<String, dynamic>;
  final sections = (meta['section'] ?? <String, dynamic>{}) as Map<String, dynamic>;
  final items = <dynamic>[];
  for (final h in (data['hadiths'] as List<dynamic>)) {
    final m = h as Map<String, dynamic>;
    final ref = (m['reference'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    items.add({
      'num': '${m['hadithnumber']}',
      'book': (ref['book'] as num?)?.toInt() ?? 0,
      'text': (m['text'] ?? '') as String,
    });
  }
  final books = <String, dynamic>{};
  sections.forEach((k, v) => books[k] = '$v');
  return {'books': books, 'items': items};
}
