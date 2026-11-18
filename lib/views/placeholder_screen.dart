import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// পরবর্তী ধাপে প্রতিটি অপশনের আসল স্ক্রিন দিয়ে এটি বদলানো হবে।
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: AppColors.accent),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('এই অংশটি শীঘ্রই যুক্ত হবে।', style: TextStyle(fontSize: 16, color: AppColors.subtle)),
            ],
          ),
        ),
      ),
    );
  }
}
