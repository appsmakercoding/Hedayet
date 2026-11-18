import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/content_downloader.dart';

/// "ডেটা ডাউনলোড করুন" কার্ড: একবার ডাউনলোড করলে পরে অফলাইনে চলে।
class DownloadCard extends StatefulWidget {
  final String title;
  final String description;
  final Future<void> Function(ProgressCallback onProgress) action;
  final VoidCallback onDone;

  const DownloadCard({
    super.key,
    required this.title,
    required this.description,
    required this.action,
    required this.onDone,
  });

  @override
  State<DownloadCard> createState() => _DownloadCardState();
}

class _DownloadCardState extends State<DownloadCard> {
  bool _busy = false;
  String _message = '';
  String? _error;

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
      _message = 'শুরু হচ্ছে…';
    });
    try {
      await widget.action((msg) {
        if (mounted) setState(() => _message = msg);
      });
      if (!mounted) return;
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3A3318) : Colors.amber.shade50,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(widget.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            if (_busy) ...[
              const LinearProgressIndicator(color: AppColors.accent),
              const SizedBox(height: 8),
              Text(_message, style: const TextStyle(fontSize: 13, color: AppColors.subtle)),
            ] else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(fontSize: 13, color: Colors.red)),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: _start,
                icon: const Icon(Icons.download_rounded),
                label: Text(_error == null ? 'ডাউনলোড করুন' : 'আবার চেষ্টা করুন'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
