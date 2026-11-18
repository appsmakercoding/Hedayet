import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_settings.dart';
import '../core/prayer_rules.dart';
import '../core/solar_calc.dart';
import '../data/prayer_data.dart';
import '../data/reminder_data.dart';
import 'location_service.dart';
import 'prayer_store.dart';

typedef PrayerTapHandler = void Function(String prayerKey);

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  PrayerTapHandler? onPrayerTap;
  String? launchPayload;

  // আজানের শব্দ বদলাতে হলে চ্যানেলের নাম বদলাতে হয় (v2 -> v3)।
  static const String _channelId = 'azan_channel_v2';
  static const String _channelName = 'আজান ও নামাজের সময়';
  static const String _soundName = 'azan'; // android/app/src/main/res/raw/azan.*

  // নিষিদ্ধ সময়ের সতর্কতা ও GPS-ভিত্তিক আজানের জন্য
  static const String _warnChannelId = 'prohibited_channel_v1';
  static const String _warnChannelName = 'নিষিদ্ধ সময়ের সতর্কতা';
  static const int _gpsBase = 3000;
  static const int _warnBase = 3500;
  static const int _gpsDays = 7;

  // দৈনিক যিকির ও কুরআন রিমাইন্ডারের জন্য
  static const String _reminderChannelId = 'reminder_channel_v1';
  static const String _reminderChannelName = 'দৈনিক রিমাইন্ডার';

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) onPrayerTap?.call(payload);
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      launchPayload = launch?.notificationResponse?.payload;
    }

    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'নামাজের ওয়াক্তে আজান ও রাকাতের তথ্য',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_soundName),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _warnChannelId,
        _warnChannelName,
        description: 'নামাজ নিষিদ্ধ সময় শুরুর আগে মনে করিয়ে দেয়',
        importance: Importance.high,
      ),
    );

    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        _reminderChannelName,
        description: 'যিকির ও কুরআন তিলাওয়াতের দৈনিক রিমাইন্ডার',
        importance: Importance.high,
      ),
    );
  }

  Future<void> requestPermissions() async {
    await _android?.requestNotificationsPermission();
    final canExact = await _android?.canScheduleExactNotifications() ?? true;
    if (!canExact) {
      await _android?.requestExactAlarmsPermission();
    }
  }

  NotificationDetails _details(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'নামাজের ওয়াক্তে আজান ও রাকাতের তথ্য',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(_soundName),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(body),
      ),
    );
  }

  /// প্রতিদিন নির্দিষ্ট সময়ে বাজবে। সময় ডিভাইসের স্থানীয় ঘড়ি অনুযায়ী ধরা হয়।
  Future<void> schedulePrayer(PrayerInfo p, int minutes) async {
    final now = DateTime.now();
    var local = DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
    if (!local.isAfter(now)) {
      local = local.add(const Duration(days: 1));
    }
    final when = tz.TZDateTime.from(local, tz.UTC);

    final canExact = await _android?.canScheduleExactNotifications() ?? false;

    await _plugin.zonedSchedule(
      p.id,
      p.notificationTitle,
      p.notificationBody,
      when,
      _details(p.notificationBody),
      androidScheduleMode:
          canExact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: p.key,
    );
  }

  Future<void> cancelPrayer(PrayerInfo p) => _plugin.cancel(p.id);

  NotificationDetails _warnDetails(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _warnChannelId,
        _warnChannelName,
        channelDescription: 'নামাজ নিষিদ্ধ সময় শুরুর আগে মনে করিয়ে দেয়',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
    );
  }

  Future<void> _cancelGpsAll() async {
    for (var i = 0; i < _gpsDays * 10; i++) {
      await _plugin.cancel(_gpsBase + i);
      await _plugin.cancel(_warnBase + i);
    }
  }

  /// GPS অবস্থান থেকে হিসাব করা সময়ে আগামী ৭ দিনের আজান (এবং চাইলে নিষিদ্ধ সময়ের সতর্কতা) সেট করে।
  Future<void> scheduleGpsAzan() async {
    await _cancelGpsAll();
    final loc = await LocationService.loadSaved();
    final warn = await AppSettings.warnProhibited();
    final now = DateTime.now();
    final tzHours = now.timeZoneOffset.inMinutes / 60.0;
    final canExact = await _android?.canScheduleExactNotifications() ?? false;
    final mode = canExact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

    for (var day = 0; day < _gpsDays; day++) {
      final date = DateTime(now.year, now.month, now.day + day);
      final t = SolarCalc.compute(date, loc.lat, loc.lon, tzHours);
      if (t == null) continue;

      final times = <String, DateTime>{
        'fajr': t.fajr,
        'zuhr': t.dhuhr.add(const Duration(minutes: PrayerRules.zuhrDelayMinutes)),
        'asr': t.asr,
        'maghrib': t.sunset,
        'isha': t.isha,
      };

      for (var k = 0; k < kPrayers.length; k++) {
        final p = kPrayers[k];
        final at = times[p.key];
        if (at == null || !at.isAfter(now)) continue;
        if (!await PrayerStore.getEnabled(p)) continue;
        await _plugin.zonedSchedule(
          _gpsBase + day * 10 + k,
          p.notificationTitle,
          p.notificationBody,
          tz.TZDateTime.from(at, tz.UTC),
          _details(p.notificationBody),
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: p.key,
        );
      }

      if (warn) {
        final windows = <String, DateTime>{
          'সূর্যোদয়ের সময়': t.sunrise,
          'ঠিক দুপুরের সময়': t.dhuhr.subtract(const Duration(minutes: PrayerRules.zawalMinutes)),
          'সূর্যাস্তের সময়': t.sunset.subtract(const Duration(minutes: PrayerRules.sunsetMinutes)),
        };
        var w = 0;
        for (final entry in windows.entries) {
          final at = entry.value.subtract(const Duration(minutes: 5));
          if (at.isAfter(now)) {
            const body = 'কিছুক্ষণের মধ্যে নামাজ নিষিদ্ধ সময় শুরু হচ্ছে।';
            await _plugin.zonedSchedule(
              _warnBase + day * 10 + w,
              '${entry.key} নিষিদ্ধ সময় আসছে',
              body,
              tz.TZDateTime.from(at, tz.UTC),
              _warnDetails(body),
              androidScheduleMode: mode,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            );
          }
          w++;
        }
      }
    }
  }

  /// অ্যাপ খোলার সময় সংরক্ষিত সেটিং অনুযায়ী সব অ্যালার্ম আবার সেট করে।
  Future<void> rescheduleAll() async {
    await applyDailyReminders();
    final mode = await AppSettings.azanMode();
    if (mode == 'gps') {
      for (final p in kPrayers) {
        try {
          await cancelPrayer(p);
        } catch (_) {}
      }
      try {
        await scheduleGpsAzan();
      } catch (e, st) {
        debugPrint('GPS schedule failed: $e');
        debugPrintStack(stackTrace: st);
      }
      return;
    }

    try {
      await _cancelGpsAll();
    } catch (_) {}
    for (final p in kPrayers) {
      try {
        final enabled = await PrayerStore.getEnabled(p);
        if (enabled) {
          await schedulePrayer(p, await PrayerStore.getMinutes(p));
        } else {
          await cancelPrayer(p);
        }
      } catch (e, st) {
        debugPrint('Schedule failed for ${p.key}: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  NotificationDetails _reminderDetails(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription: 'যিকির ও কুরআন তিলাওয়াতের দৈনিক রিমাইন্ডার',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
    );
  }

  /// প্রতিদিন নির্দিষ্ট সময়ে একটি রিমাইন্ডার বাজবে (সময় ফোনের ঘড়ি অনুযায়ী)।
  Future<void> scheduleDaily(DailyReminder r, int minutes) async {
    final now = DateTime.now();
    var local = DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
    while (!local.isAfter(now) || (r.weekday != null && local.weekday != r.weekday)) {
      local = DateTime(local.year, local.month, local.day + 1, minutes ~/ 60, minutes % 60);
    }
    final canExact = await _android?.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      r.id,
      r.title,
      r.body,
      tz.TZDateTime.from(local, tz.UTC),
      _reminderDetails(r.body),
      androidScheduleMode:
          canExact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          r.weekday == null ? DateTimeComponents.time : DateTimeComponents.dayOfWeekAndTime,
      payload: 'reminder',
    );
  }

  /// সংরক্ষিত সেটিং অনুযায়ী সব দৈনিক রিমাইন্ডার চালু বা বন্ধ করে।
  Future<void> applyDailyReminders() async {
    for (final r in kDailyReminders) {
      try {
        if (await AppSettings.reminderEnabled(r.key)) {
          final minutes = await AppSettings.reminderMinutes(r.key, r.defaultMinutes);
          await scheduleDaily(r, minutes);
        } else {
          await _plugin.cancel(r.id);
        }
      } catch (e) {
        debugPrint('Reminder schedule failed for ${r.key}: $e');
      }
    }
  }

  /// এখনই একটি পরীক্ষামূলক আজান বাজায়।
  Future<void> showTest() async {
    const body = 'এটি একটি পরীক্ষামূলক নোটিফিকেশন। আজানের শব্দ শোনা গেলে সব ঠিক আছে।';
    await _plugin.show(999, 'পরীক্ষামূলক আজান', body, _details(body), payload: 'fajr');
  }
}
