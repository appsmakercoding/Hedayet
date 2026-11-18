import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLocation {
  final double lat;
  final double lon;

  /// true হলে GPS থেকে নেওয়া, false হলে ডিফল্ট (ঢাকা)।
  final bool fromGps;
  const UserLocation(this.lat, this.lon, this.fromGps);
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

/// GPS থেকে অবস্থান নেয় এবং ফোনে সংরক্ষণ করে রাখে (পরের বার ইন্টারনেট বা GPS ছাড়াই কাজ চলে)।
class LocationService {
  LocationService._();

  /// GPS না পেলে ঢাকার অবস্থান ধরা হয়।
  static const UserLocation fallback = UserLocation(23.8103, 90.4125, false);

  /// বর্তমান অবস্থান। হোমপেজের কার্ড ও কিবলা কম্পাস একই মান দেখে, বদলালে নিজে থেকে আপডেট হয়।
  static final ValueNotifier<UserLocation> current = ValueNotifier<UserLocation>(fallback);

  static const String _kLat = 'loc_lat';
  static const String _kLon = 'loc_lon';
  static const String _kAsked = 'loc_asked';

  static Future<UserLocation> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_kLat);
    final lon = prefs.getDouble(_kLon);
    if (lat == null || lon == null) return fallback;
    final saved = UserLocation(lat, lon, true);
    current.value = saved;
    return saved;
  }

  /// আগে কখনো অনুমতি চাওয়া হয়েছে কিনা।
  static Future<bool> wasAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAsked) ?? false;
  }

  /// অনুমতি আগেই দেওয়া আছে কিনা (প্রশ্ন না করে দেখে)।
  static Future<bool> hasPermission() async {
    try {
      final p = await Geolocator.checkPermission();
      return p == LocationPermission.whileInUse || p == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// GPS থেকে বর্তমান অবস্থান নেয়। ব্যর্থ হলে [LocationException] ছোড়ে (বাংলা বার্তাসহ)।
  static Future<UserLocation> detect() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException('ফোনের লোকেশন (GPS) বন্ধ আছে। চালু করে আবার চেষ্টা করুন।');
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      await prefs.setBool(_kAsked, true);
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw const LocationException('লোকেশনের অনুমতি দেওয়া হয়নি।');
    }
    if (perm == LocationPermission.deniedForever) {
      throw const LocationException(
        'লোকেশনের অনুমতি বন্ধ আছে। ফোনের সেটিংস → অ্যাপ → হেদায়েত → অনুমতি থেকে চালু করুন।',
      );
    }

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 20),
      );
    } catch (_) {
      pos = await Geolocator.getLastKnownPosition();
    }
    if (pos == null) {
      throw const LocationException('অবস্থান পাওয়া যায়নি। খোলা জায়গায় গিয়ে আবার চেষ্টা করুন।');
    }

    await prefs.setDouble(_kLat, pos.latitude);
    await prefs.setDouble(_kLon, pos.longitude);
    final loc = UserLocation(pos.latitude, pos.longitude, true);
    current.value = loc;
    return loc;
  }
}
