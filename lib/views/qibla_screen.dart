import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/qibla.dart';
import '../data/prayer_data.dart' show bn;
import '../services/location_service.dart';
import '../widgets/qibla_compass.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  @override
  void initState() {
    super.initState();
    // সংরক্ষিত GPS অবস্থান থাকলে সেটি নেওয়া হয় (নেই হলে ঢাকা ধরা থাকে)
    LocationService.loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('কিবলা কম্পাস', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ValueListenableBuilder<UserLocation>(
        valueListenable: LocationService.current,
        builder: (context, loc, _) {
          final q = Qibla.bearing(loc.lat, loc.lon);
          final km = Qibla.distanceKm(loc.lat, loc.lon).round();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Center(child: QiblaCompass(size: 280)),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'কিবলার দিক: ${bn(q.round())}° (${Qibla.directionName(q)})',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'কাবা শরীফ থেকে দূরত্ব: প্রায় ${bn(km)} কিলোমিটার',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            loc.fromGps ? Icons.location_on_rounded : Icons.location_off_rounded,
                            size: 18,
                            color: loc.fromGps ? AppColors.gold : Colors.orange.shade300,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              loc.fromGps
                                  ? 'আপনার GPS অবস্থান অনুযায়ী'
                                  : 'GPS অবস্থান পাওয়া যায়নি, ঢাকার হিসাবে দেখানো হচ্ছে। হোমপেজে লোকেশন চালু করুন।',
                              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'ফোনটি সমান করে ধরুন এবং ধাতব বস্তু ও চুম্বক থেকে দূরে রাখুন। দিক ঠিক না এলে ফোনটি ৮ (আট)-এর মতো করে কয়েকবার ঘোরান। কালো ঘনক কাবা শরীফ, সেটি ওপরের তীরের নিচে এলে আপনি কিবলার দিকে ফিরে আছেন। এটি আনুমানিক দিক-নির্দেশনা, নিশ্চিত হতে মসজিদের কিবলা দেখুন।',
                  style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
