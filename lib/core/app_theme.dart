import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        secondary: AppColors.gold,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
    );
  }

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: Brightness.dark,
    );
    final scheme = base.copyWith(
      primary: const Color(0xFF3FBF7F),
      secondary: AppColors.gold,
      surface: AppColors.darkSurface,
      onSurface: const Color(0xFFE8F1EB),
      surfaceContainerLowest: AppColors.darkBg,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: AppColors.darkSurfaceHigh,
      surfaceContainerHighest: AppColors.darkSurfaceHigh,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      dividerColor: Colors.white12,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}

/// থিম (ডার্ক / লাইট / ফোনের সেটিং) মনে রাখে।
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString('theme_mode')) {
      case 'light':
        mode.value = ThemeMode.light;
        break;
      case 'system':
        mode.value = ThemeMode.system;
        break;
      case 'dark':
        mode.value = ThemeMode.dark;
        break;
      default:
        mode.value = ThemeMode.light;
    }
  }

  static Future<void> set(ThemeMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    final String value;
    if (m == ThemeMode.light) {
      value = 'light';
    } else if (m == ThemeMode.system) {
      value = 'system';
    } else {
      value = 'dark';
    }
    await prefs.setString('theme_mode', value);
  }
}

/// বর্তমান থিম ডার্ক কিনা।
bool isDarkTheme(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
