import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// অ্যাপের সব সংরক্ষিত তথ্য (বুকমার্ক, খতম, কাযা, আমল, সেটিংস ইত্যাদি) একটি লেখায় নিয়ে আসে
/// এবং সেই লেখা থেকে ফিরিয়ে দেয়। কোনো সার্ভার বা ক্লাউড ব্যবহার হয় না;
/// ব্যবহারকারী লেখাটি নিজেই নিজের কাছে রাখেন।
class BackupService {
  BackupService._();

  static const String _magic = 'hedayet-backup-v1';

  static Future<String> export() async {
    final p = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    for (final k in p.getKeys()) {
      final v = p.get(k);
      if (v is bool) {
        data[k] = {'t': 'b', 'v': v};
      } else if (v is int) {
        data[k] = {'t': 'i', 'v': v};
      } else if (v is double) {
        data[k] = {'t': 'd', 'v': v};
      } else if (v is String) {
        data[k] = {'t': 's', 'v': v};
      } else if (v is List) {
        data[k] = {'t': 'l', 'v': v.map((e) => e.toString()).toList()};
      }
    }
    return jsonEncode({'app': _magic, 'data': data});
  }

  /// সফল হলে ফিরিয়ে দেওয়া তথ্যের সংখ্যা ফেরত দেয়। লেখাটি ঠিক না হলে FormatException ছোড়ে।
  static Future<int> restore(String text) async {
    final decoded = jsonDecode(text.trim());
    if (decoded is! Map || decoded['app'] != _magic || decoded['data'] is! Map) {
      throw const FormatException('এটি হেদায়েতের ব্যাকআপ নয়');
    }
    final data = decoded['data'] as Map;
    final p = await SharedPreferences.getInstance();
    var n = 0;
    for (final e in data.entries) {
      final key = e.key.toString();
      final item = e.value;
      if (item is! Map) continue;
      final v = item['v'];
      switch (item['t']) {
        case 'b':
          if (v is bool) {
            await p.setBool(key, v);
            n++;
          }
          break;
        case 'i':
          if (v is int) {
            await p.setInt(key, v);
            n++;
          }
          break;
        case 'd':
          if (v is num) {
            await p.setDouble(key, v.toDouble());
            n++;
          }
          break;
        case 's':
          if (v is String) {
            await p.setString(key, v);
            n++;
          }
          break;
        case 'l':
          if (v is List) {
            await p.setStringList(key, v.map((x) => x.toString()).toList());
            n++;
          }
          break;
      }
    }
    return n;
  }
}
