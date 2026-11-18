import 'package:shared_preferences/shared_preferences.dart';
import '../data/prayer_data.dart';

/// ব্যবহারকারীর সেট করা সময় ও চালু/বন্ধ অবস্থা সংরক্ষণ করে।
class PrayerStore {
  static Future<int> getMinutes(PrayerInfo p) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('minutes_${p.key}') ?? p.defaultMinutes;
  }

  static Future<void> setMinutes(PrayerInfo p, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minutes_${p.key}', minutes);
  }

  static Future<bool> getEnabled(PrayerInfo p) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('enabled_${p.key}') ?? true;
  }

  static Future<void> setEnabled(PrayerInfo p, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enabled_${p.key}', value);
  }
}
