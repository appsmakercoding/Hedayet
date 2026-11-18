import 'package:flutter/material.dart';

import 'core/app_settings.dart';
import 'core/app_theme.dart';
import 'core/constants.dart';
import 'core/navigation.dart';
import 'data/prayer_data.dart';
import 'services/notification_service.dart';
import 'views/home_screen.dart';
import 'views/prayer_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppSettings.load();
    await ThemeController.load();
  } catch (e) {
    debugPrint('Settings load failed: $e');
  }
  try {
    await NotificationService.instance.init();
    await NotificationService.instance.rescheduleAll();
  } catch (e, st) {
    debugPrint('Notification setup failed: $e');
    debugPrintStack(stackTrace: st);
  }
  runApp(const HedayetApp());
}

class HedayetApp extends StatefulWidget {
  const HedayetApp({super.key});

  @override
  State<HedayetApp> createState() => _HedayetAppState();
}

class _HedayetAppState extends State<HedayetApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.onPrayerTap = _openPrayer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final payload = NotificationService.instance.launchPayload;
      if (payload != null) _openPrayer(payload);
    });
  }

  void _openPrayer(String key) {
    final prayer = prayerByKey(key);
    if (prayer == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => PrayerDetailScreen(prayer: prayer)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) => MaterialApp(
        title: AppConstants.appName,
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        builder: (context, child) {
          return ValueListenableBuilder<double>(
            valueListenable: AppSettings.textScale,
            builder: (context, scale, _) {
              final system = MediaQuery.of(context).textScaler.scale(1.0);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(system * scale)),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
