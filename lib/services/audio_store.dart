import 'dart:io';

import 'package:sqflite/sqflite.dart';

/// সূরার অডিও ফোনে ডাউনলোড করে রাখে (অ্যাপের নিজস্ব জায়গায়), যাতে ইন্টারনেট ছাড়াই চলে।
class AudioStore {
  AudioStore._();

  static Future<Directory> _dir() async {
    final base = await getDatabasesPath();
    final d = Directory('$base/audio');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<String> path(int surah) async => '${(await _dir()).path}/$surah.mp3';

  static Future<bool> exists(int surah) async {
    final f = File(await path(surah));
    return await f.exists() && await f.length() > 1024;
  }

  /// [url] থেকে নামিয়ে ফাইলে রাখে; [onProgress]-এ ০.০ থেকে ১.০ পর্যন্ত অগ্রগতি আসে।
  static Future<void> download(int surah, String url, void Function(double) onProgress) async {
    final target = await path(surah);
    final part = File('$target.part');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final total = res.contentLength;
      final sink = part.openWrite();
      var got = 0;
      try {
        await for (final chunk in res) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0) onProgress(got / total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      final old = File(target);
      if (await old.exists()) await old.delete();
      await part.rename(target);
    } catch (e) {
      if (await part.exists()) {
        try {
          await part.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> delete(int surah) async {
    final f = File(await path(surah));
    if (await f.exists()) await f.delete();
  }
}
