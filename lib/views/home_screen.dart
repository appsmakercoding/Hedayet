import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../widgets/option_card.dart';
import '../widgets/prayer_status_card.dart';
import '../widgets/qibla_compass.dart';
import 'hadith_screen.dart';
import 'learning_screen.dart';
import 'prayer_reminder_screen.dart';
import 'qibla_screen.dart';
import 'quran_screen.dart';
import 'search_screen.dart';
import 'services_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'ডার্ক / লাইট মোড',
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () => ThemeController.set(isDarkTheme(context) ? ThemeMode.light : ThemeMode.dark),
        child: Icon(isDarkTheme(context) ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const _Header(),
                  const PrayerStatusCard(),
                  _HomeBanner(
                    title: 'নামাজ শিক্ষা',
                    subtitle: 'শিক্ষামূলক ভিডিও, ইউটিউব ও PDF',
                    icon: Icons.school_rounded,
                    color: Colors.teal.shade600,
                    onTap: () => _go(context, const LearningScreen()),
                  ),
                  _HomeBanner(
                    title: 'সকল সেবা',
                    subtitle: 'ক্যালেন্ডার, সেটিংস ও আরও সেবা',
                    icon: Icons.apps_rounded,
                    color: Colors.indigo.shade400,
                    onTap: () => _go(context, const ServicesScreen()),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(18),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      OptionCard(
                        title: 'নামাজ রিমাইন্ডার',
                        icon: Icons.access_time_filled_rounded,
                        color: Colors.amber.shade800,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrayerReminderScreen()),
                        ),
                      ),
                      OptionCard(
                        title: 'কুরআন',
                        icon: Icons.menu_book_rounded,
                        color: Colors.green.shade700,
                        onTap: () => _go(context, const QuranScreen()),
                      ),
                      OptionCard(
                        title: 'হাদিস',
                        icon: Icons.library_books_rounded,
                        color: Colors.blue.shade800,
                        onTap: () => _go(context, const HadithScreen()),
                      ),
                      OptionCard(
                        title: 'অনুসন্ধান',
                        icon: Icons.search_rounded,
                        color: Colors.purple.shade700,
                        onTap: () => _go(context, const SearchScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: 10),
              child: Text(
                'Powered By Hasan',
                style: TextStyle(fontSize: 12, letterSpacing: 0.6, color: Colors.black45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HomeBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkTheme(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: dark ? Border.all(color: AppColors.gold.withOpacity(0.35)) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.16),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.subtle)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.subtle),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.darkGreen, AppColors.primaryGreen],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const Text(
            AppConstants.bismillah,
            style: TextStyle(color: AppColors.gold, fontSize: 20),
          ),
          const SizedBox(height: 14),

          // --- নতুন স্পষ্ট ও প্রিমিয়াম লোগো ডিজাইন ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.gold, width: 2), // গোল্ডেন বর্ডার
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/images/home_header.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high, // সর্বোচ্চ হাই-রেজোলিউশন শার্পনেস
                  ),
                ),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QiblaScreen()),
                ),
                child: const QiblaCompass(size: 110, compact: true),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text(
            AppConstants.appName,
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            AppConstants.tagline,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
