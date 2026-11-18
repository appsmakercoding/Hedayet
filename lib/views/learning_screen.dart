import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/learning_data.dart';
import 'web_screen.dart';

/// ইউটিউব ও গুগলের ডোমেইন: ইউটিউব দেখার সময় শুধু এগুলোতেই যাওয়া যাবে।
const List<String> _youtubeHosts = [
  'youtube.com',
  'youtu.be',
  'youtube-nocookie.com',
  'google.com',
  'gstatic.com',
  'googlevideo.com',
  'ytimg.com',
  'ggpht.com',
  'googleusercontent.com',
];

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  void _openYoutube(BuildContext context, String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebScreen(title: title, url: url, allowedHosts: _youtubeHosts),
      ),
    );
  }

  void _openPdf(BuildContext context, LearningPdf pdf) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WebScreen(title: pdf.title, url: pdf.openUrl)),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
      );

  Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.14),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ভিডিওর অংশগুলো (গ্রুপ) তালিকার ক্রম অনুযায়ী
    final groups = <String>[];
    for (final v in kVideos) {
      if (!groups.contains(v.group)) groups.add(v.group);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('নামাজ শিক্ষা', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            icon: Icons.smart_display_rounded,
            color: Colors.red.shade700,
            title: 'ইউটিউব',
            subtitle: 'অ্যাপের ভেতরেই m.youtube.com খুলুন',
            onTap: () => _openYoutube(context, 'ইউটিউব', kYoutubeHome),
          ),
          for (final g in groups) ...[
            _sectionTitle(g.isEmpty ? 'শিক্ষামূলক ভিডিও' : g),
            for (final v in kVideos)
              if (v.group == g)
                _tile(
                  icon: Icons.play_circle_fill_rounded,
                  color: Colors.red.shade600,
                  title: v.title,
                  subtitle: v.subtitle,
                  onTap: () => _openYoutube(context, v.title, v.url),
                ),
          ],
          _sectionTitle('PDF বই ও লেখা'),
          if (kPdfs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'এখনো কোনো PDF যোগ করা হয়নি। শীঘ্রই যোগ হবে, ইনশাআল্লাহ।',
                  style: TextStyle(fontSize: 14, color: AppColors.subtle),
                ),
              ),
            ),
          for (final p in kPdfs)
            _tile(
              icon: Icons.picture_as_pdf_rounded,
              color: Colors.blue.shade800,
              title: p.title,
              subtitle: p.subtitle,
              onTap: () => _openPdf(context, p),
            ),
          const SizedBox(height: 12),
          const Text(
            'ভিডিওর ফলাফল ইউটিউব থেকে আসে। শিক্ষামূলক কনটেন্ট বিশ্বস্ত আলেম বা প্রতিষ্ঠানের কিনা যাচাই করে দেখুন।',
            style: TextStyle(fontSize: 11.5, color: AppColors.subtle),
          ),
        ],
      ),
    );
  }
}
