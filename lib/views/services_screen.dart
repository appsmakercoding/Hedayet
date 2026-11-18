import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/location_service.dart';
import 'amol_screen.dart';
import 'bookmarks_screen.dart';
import 'calendar_screen.dart';
import 'islamic_library_screen.dart';
import 'khatam_screen.dart';
import 'hadith_screen.dart';
import 'learning_screen.dart';
import 'my_mosque_screen.dart';
import 'prayer_reminder_screen.dart';
import 'qaza_screen.dart';
import 'sadaqa_screen.dart';
import 'qibla_screen.dart';
import 'quran_screen.dart';
import 'roza_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'surah_list_screen.dart';
import 'tasbih_screen.dart';
import 'web_screen.dart';
import 'zakat_screen.dart';

const List<String> _mapHosts = ['google.com', 'gstatic.com', 'googleapis.com', 'googleusercontent.com', 'ggpht.com'];

Widget _mosqueFinder() {
  final loc = LocationService.current.value;
  final url = 'https://www.google.com/maps/search/mosque/@${loc.lat.toStringAsFixed(5)},${loc.lon.toStringAsFixed(5)},15z?hl=bn';
  return WebScreen(title: 'মসজিদ খুঁজি', url: url, allowedHosts: _mapHosts);
}

class _Item {
  final String label;
  final IconData icon;
  final Color color;
  final Widget Function() page;
  const _Item(this.label, this.icon, this.color, this.page);
}

class _Section {
  final String title;
  final Color color;
  final List<_Item> items;
  const _Section(this.title, this.color, this.items);
}

/// সব সেবা এক জায়গায়, তিন অংশে সাজানো।
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  List<_Section> _sections() {
    return [
      _Section('ইলম ও আমল', Colors.green, [
        _Item('কুরআন', Icons.menu_book_rounded, Colors.green.shade700, () => const QuranScreen()),
        _Item('হাদিস', Icons.library_books_rounded, Colors.blue.shade700, () => const HadithScreen()),
        _Item('নামাজ শিক্ষা', Icons.school_rounded, Colors.teal.shade600, () => const LearningScreen()),
        _Item('অনুসন্ধান', Icons.search_rounded, Colors.purple.shade600, () => const SearchScreen()),
        _Item('ছোট সূরা', Icons.auto_stories_rounded, Colors.lightGreen.shade700, () => SurahListScreen(
              title: 'ছোট সূরা (আমপারা)',
              subtitle: '৭৮ থেকে ১১৪ নম্বর সূরা',
              numbers: [for (var n = 78; n <= 114; n++) n],
            )),
        _Item('জনপ্রিয় সূরা', Icons.star_rounded, Colors.amber.shade700, () => const SurahListScreen(
              title: 'জনপ্রিয় সূরা',
              subtitle: 'ফাতিহা, কাহফ, সাজদাহ, ইয়াসীন, রহমান, ওয়াকিআ, জুমুআ, মুলক ও শেষ তিন সূরা',
              numbers: [1, 18, 32, 36, 55, 56, 62, 67, 112, 113, 114],
            )),
        _Item('ইসলামি লাইব্রেরি', Icons.local_library_rounded, Colors.pink.shade400, () => const IslamicLibraryScreen()),
        _Item('ইসলামি কুইজ', Icons.quiz_rounded, Colors.amber.shade700, () => const QuizScreen()),
        _Item('বুকমার্ক', Icons.bookmark_rounded, Colors.orange.shade700, () => const BookmarksScreen()),
        _Item('আমল ট্র্যাকার', Icons.checklist_rounded, Colors.cyan.shade700, () => const AmolScreen()),
        _Item('কুরআন খতম প্ল্যানার', Icons.flag_rounded, Colors.green.shade600, () => const KhatamScreen()),
        _Item('কাযা নামাজ', Icons.event_repeat_rounded, Colors.brown.shade500, () => const QazaScreen()),
        _Item('সদকার খাতা', Icons.volunteer_activism_rounded, Colors.pink.shade400, () => const SadaqaScreen()),
      ]),
      _Section('সেবা', Colors.orange, [
        _Item('নামাজ রিমাইন্ডার', Icons.access_time_filled_rounded, Colors.amber.shade800, () => const PrayerReminderScreen()),
        _Item('কিবলা', Icons.explore_rounded, Colors.indigo.shade500, () => const QiblaScreen()),
        _Item('মসজিদ খুঁজি', Icons.place_rounded, Colors.red.shade400, _mosqueFinder),
        _Item('আমার মসজিদ', Icons.home_work_rounded, Colors.brown.shade400, () => const MyMosqueScreen()),
        _Item('যাকাত ও ফিতরা', Icons.volunteer_activism_rounded, Colors.green.shade800, () => const ZakatScreen()),
        _Item('রোযা: সেহরি-ইফতার', Icons.nights_stay_rounded, Colors.deepPurple.shade400, () => const RozaScreen()),
      ]),
      _Section('বিবিধ', Colors.purple, [
        _Item('তাসবীহ', Icons.touch_app_rounded, Colors.teal.shade700, () => const TasbihScreen()),
        _Item('ক্যালেন্ডার ও গুরুত্বপূর্ণ দিন', Icons.calendar_month_rounded, Colors.deepOrange.shade400, () => const CalendarScreen()),
        _Item('সেটিংস', Icons.settings_rounded, Colors.blueGrey.shade600, () => const SettingsScreen()),
      ]),
    ];
  }

  Widget _tile(BuildContext context, _Item item) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.page())),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: item.color.withOpacity(0.16),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();
    return Scaffold(
      appBar: AppBar(title: const Text('সকল সেবা', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          for (final s in sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 22,
                    decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ],
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: [for (final item in s.items) _tile(context, item)],
            ),
          ],
        ],
      ),
    );
  }
}
