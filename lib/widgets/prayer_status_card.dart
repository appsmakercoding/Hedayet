import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/prayer_timeline.dart';
import '../data/prayer_data.dart' show bn, formatTimeBn;
import '../services/location_service.dart';
import '../services/notification_service.dart';

String _two(int n) => n < 10 ? '০${bn(n)}' : bn(n);

/// সময়কে বাংলা ঘড়ির রূপে: ০১:২২:০৫
String _dur(Duration d) {
  final t = d.isNegative ? Duration.zero : d;
  return '${_two(t.inHours)}:${_two(t.inMinutes % 60)}:${_two(t.inSeconds % 60)}';
}

/// নিকটতম মিনিটে গোল করে বাংলা সময়, যেমন "ভোর ৫:৫৭"।
String _clock(DateTime t) {
  final m = (t.hour * 60 + t.minute + (t.second >= 30 ? 1 : 0)) % 1440;
  return formatTimeBn(m);
}

String _dayLabel(DateTime t, DateTime now) {
  final a = DateTime(t.year, t.month, t.day);
  final b = DateTime(now.year, now.month, now.day);
  final diff = a.difference(b).inDays;
  if (diff == 0) return 'আজ';
  if (diff == 1) return 'আগামীকাল';
  return '';
}

/// হোমপেজের কার্ড: বর্তমান ওয়াক্ত, পরের নামাজ, নিষিদ্ধ সময়ের কাউন্টডাউন।
class PrayerStatusCard extends StatefulWidget {
  const PrayerStatusCard({super.key});

  @override
  State<PrayerStatusCard> createState() => _PrayerStatusCardState();
}

class _PrayerStatusCardState extends State<PrayerStatusCard> {
  UserLocation _loc = LocationService.fallback;
  PrayerTimeline? _timeline;
  DateTime _now = DateTime.now();
  DateTime? _builtDay;
  bool _locating = false;
  String? _note;
  Timer? _timer;

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _redBg => _dark ? const Color(0x33E53935) : Colors.red.shade50;
  Color get _redText => _dark ? Colors.red.shade200 : Colors.red.shade800;
  Color get _redStrong => _dark ? Colors.red.shade300 : Colors.red.shade700;
  Color get _greenBg => _dark ? const Color(0x3343A047) : Colors.green.shade50;
  Color get _greenText => _dark ? Colors.green.shade200 : Colors.green.shade800;
  Color get _greenStrong => _dark ? Colors.green.shade300 : Colors.green.shade700;
  Color get _orange => _dark ? Colors.orange.shade300 : Colors.orange.shade900;

  @override
  void initState() {
    super.initState();
    _rebuild(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _rebuild(DateTime now) {
    _timeline = PrayerTimeline.build(now, _loc.lat, _loc.lon);
    _builtDay = DateTime(now.year, now.month, now.day);
    _now = now;
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      final today = DateTime(now.year, now.month, now.day);
      if (_builtDay == null || _builtDay != today) {
        _rebuild(now);
      } else {
        _now = now;
      }
    });
  }

  Future<void> _init() async {
    final saved = await LocationService.loadSaved();
    if (!mounted) return;
    setState(() {
      _loc = saved;
      _rebuild(DateTime.now());
    });

    final has = await LocationService.hasPermission();
    final asked = await LocationService.wasAsked();
    if (has || !asked) {
      await _detect();
    } else if (!saved.fromGps) {
      if (mounted) setState(() => _note = 'GPS পাওয়া যায়নি, ঢাকার হিসাবে দেখানো হচ্ছে।');
    }
  }

  Future<void> _detect() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _note = null;
    });
    try {
      final loc = await LocationService.detect();
      if (!mounted) return;
      setState(() {
        _loc = loc;
        _rebuild(DateTime.now());
      });
      // GPS-ভিত্তিক আজান চালু থাকলে নতুন অবস্থান অনুযায়ী সময় আবার সেট হয়
      NotificationService.instance.rescheduleAll().catchError((Object _) {});
    } on LocationException catch (e) {
      if (mounted) setState(() => _note = e.message);
    } catch (_) {
      if (mounted) setState(() => _note = 'অবস্থান পাওয়া যায়নি। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tl = _timeline;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: _dark ? AppColors.darkSurface : Colors.white,
        border: _dark ? Border.all(color: AppColors.gold.withOpacity(0.35)) : null,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: tl == null ? _failed() : _content(tl),
    );
  }

  Widget _failed() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'এই অবস্থানের জন্য নামাজের সময় হিসাব করা যায়নি।',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 8),
          _locationRow(),
        ],
      ),
    );
  }

  Widget _content(PrayerTimeline tl) {
    final now = _now;
    final cur = tl.currentWaqt(now);
    final next = tl.nextFardWaqt(now);
    final win = tl.currentWindow(now);
    final upcoming = tl.upcomingWindows(now);

    return Column(
      children: [
        _waqtHeader(cur, next, now),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _prohibitedBox(win, upcoming, now),
              const SizedBox(height: 12),
              const Text(
                'নিষিদ্ধ সময়',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              for (final w in upcoming) _windowRow(w, w == win, now),
              const SizedBox(height: 8),
              _locationRow(),
              const SizedBox(height: 4),
              const Text(
                'সময়গুলো আপনার GPS অবস্থান থেকে হিসাব করা (আনুমানিক)। নিষিদ্ধ সময়ের বিষয়ে আলেমের পরামর্শ নিন।',
                style: TextStyle(fontSize: 11, color: AppColors.subtle),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _waqtHeader(Waqt? cur, Waqt? next, DateTime now) {
    final isFard = cur?.isFard ?? false;
    final String title;
    final String sub;
    if (cur == null) {
      title = '—';
      sub = '';
    } else if (isFard) {
      title = '${cur.name} নামাজের ওয়াক্ত';
      sub = 'ওয়াক্ত শেষ হতে বাকি: ${_dur(cur.end.difference(now))}';
    } else {
      title = cur.name;
      sub = 'এখন কোনো ফরজ নামাজের ওয়াক্ত নেই';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkGreen, AppColors.primaryGreen],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('এখন চলছে', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
          if (next != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'পরের নামাজ: ${next.name} • ${_clock(next.start)}  (${_dur(next.start.difference(now))} পরে)',
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _prohibitedBox(ProhibitedWindow? win, List<ProhibitedWindow> upcoming, DateTime now) {
    if (win != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _redBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.block_rounded, color: _redStrong, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'এখন নামাজ নিষিদ্ধ সময়',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _redText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${win.name} • মোট ${bn(win.minutes)} মিনিট',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'শেষ হতে বাকি: ${_dur(win.end.difference(now))}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _redStrong),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final nextWin = upcoming.isEmpty ? null : upcoming.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _greenBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: _greenStrong, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'এখন নামাজ পড়া যাবে',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _greenText),
                ),
                if (nextWin != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'পরের নিষিদ্ধ সময় (${nextWin.name}) শুরু হতে: ${_dur(nextWin.start.difference(now))}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowRow(ProhibitedWindow w, bool active, DateTime now) {
    final day = _dayLabel(w.start, now);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: active ? Colors.red.shade600 : Colors.black26,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              day.isEmpty ? w.name : '$day • ${w.name}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${_clock(w.start)} – ${_clock(w.end)}',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? _redStrong : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRow() {
    final text = _note ?? (_loc.fromGps ? 'আপনার GPS অবস্থান অনুযায়ী হিসাব' : 'ঢাকার হিসাবে দেখানো হচ্ছে');
    return Row(
      children: [
        Icon(
          _loc.fromGps ? Icons.location_on_rounded : Icons.location_off_rounded,
          size: 18,
          color: _loc.fromGps ? AppColors.accent : _orange,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: _note != null ? _orange : AppColors.subtle,
            ),
          ),
        ),
        if (_locating)
          const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          IconButton(
            tooltip: 'অবস্থান আপডেট করুন',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.my_location_rounded, size: 22, color: AppColors.accent),
            onPressed: _detect,
          ),
      ],
    );
  }
}
