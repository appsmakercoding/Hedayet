import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_rules.dart';

/// অ্যাপের সেটিংস (সেটিংস স্ক্রিন থেকে বদলায়)।
class AppSettings {
  AppSettings._();

  /// হিজরি তারিখ এক-দুই দিন আগে-পরে করার সংখ্যা (-২ থেকে +২)।
  static final ValueNotifier<int> hijriAdjust = ValueNotifier<int>(0);

  /// ওয়াক্ত গণনার পদ্ধতির চাবি (prayer_rules.dart-এর methods দেখুন)।
  static String calcMethod = 'karachi';

  /// অ্যাপজুড়ে লেখার আকারের গুণক (১.০ = স্বাভাবিক)।
  static final ValueNotifier<double> textScale = ValueNotifier<double>(1.0);

  static const List<MapEntry<double, String>> textScaleOptions = [
    MapEntry(0.9, 'ছোট'),
    MapEntry(1.0, 'স্বাভাবিক'),
    MapEntry(1.15, 'বড়'),
    MapEntry(1.3, 'অনেক বড়'),
  ];

  static Future<void> setTextScale(double v) async {
    textScale.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_scale', v);
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    textScale.value = prefs.getDouble('text_scale') ?? 1.0;
    calcMethod = prefs.getString('calc_method') ?? 'karachi';
    PrayerRules.applyMethod(calcMethod);
    PrayerRules.asrFactor = prefs.getDouble('asr_factor') ?? 2.0;
    hijriAdjust.value = prefs.getInt('hijri_adjust') ?? 0;
  }

  static Future<void> setCalcMethod(String key) async {
    calcMethod = key;
    PrayerRules.applyMethod(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calc_method', key);
  }

  /// দৈনিক রিমাইন্ডার (যিকির, কুরআন): চালু আছে কিনা ও সময় (মিনিটে)।
  static Future<bool> reminderEnabled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('rem_on_$key') ?? false;
  }

  static Future<void> setReminderEnabled(String key, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rem_on_$key', v);
  }

  static Future<int> reminderMinutes(String key, int fallback) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('rem_min_$key') ?? fallback;
  }

  static Future<void> setReminderMinutes(String key, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rem_min_$key', minutes);
  }

  static Future<void> setAsrFactor(double v) async {
    PrayerRules.asrFactor = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('asr_factor', v);
  }

  static Future<void> setHijriAdjust(int v) async {
    hijriAdjust.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hijri_adjust', v);
  }

  /// 'manual' = ব্যবহারকারীর সেট করা সময়, 'gps' = GPS-এর হিসাব করা সময়।
  static Future<String> azanMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('azan_mode') ?? 'manual';
  }

  static Future<void> setAzanMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('azan_mode', mode);
  }

  /// নিষিদ্ধ সময় শুরুর আগে নোটিফিকেশন দেবে কিনা।
  static Future<bool> warnProhibited() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('warn_prohibited') ?? false;
  }

  static Future<void> setWarnProhibited(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('warn_prohibited', v);
  }
}
