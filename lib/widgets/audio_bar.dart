import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../core/app_colors.dart';
import '../data/prayer_data.dart' show bn;
import '../services/audio_store.dart';

/// সূরার অডিও: অনলাইনে স্ট্রিম হয়, চাইলে ফোনে ডাউনলোড করে রাখা যায় (তখন অফলাইনে চলে)।
class AudioBar extends StatefulWidget {
  final String url;
  final String title;
  final int surah;
  const AudioBar({super.key, required this.url, required this.title, required this.surah});

  @override
  State<AudioBar> createState() => _AudioBarState();
}

class _AudioBarState extends State<AudioBar> {
  final AudioPlayer _player = AudioPlayer();
  bool _loading = false;
  bool _loaded = false;
  bool _local = false;
  double? _dl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLocal();
  }

  Future<void> _checkLocal() async {
    final ok = await AudioStore.exists(widget.surah);
    if (mounted) setState(() => _local = ok);
  }

  Future<void> _download() async {
    setState(() {
      _dl = 0;
      _error = null;
    });
    try {
      await AudioStore.download(widget.surah, widget.url, (p) {
        if (mounted) setState(() => _dl = p);
      });
      if (mounted) setState(() => _local = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'ডাউনলোড করা যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _dl = null);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ডাউনলোড করা অডিও মুছবেন?'),
        content: const Text('মুছলে এই সূরা আবার অনলাইনে শুনতে হবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('মুছুন')),
        ],
      ),
    );
    if (ok != true) return;
    await _player.stop();
    await AudioStore.delete(widget.surah);
    if (mounted) {
      setState(() {
        _local = false;
        _loaded = false;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (!_loaded) {
        setState(() {
          _loading = true;
          _error = null;
        });
        if (_local) {
          await _player.setFilePath(await AudioStore.path(widget.surah));
        } else {
          await _player.setUrl(widget.url);
        }
        _loaded = true;
        if (mounted) setState(() => _loading = false);
        _player.play();
        return;
      }
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
        _player.play();
      } else if (_player.playing) {
        await _player.pause();
      } else {
        _player.play();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loaded = false;
        _error = 'অডিও চালানো যায়নি। ইন্টারনেট সংযোগ দেখুন।';
      });
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${bn(m)}:${s < 10 ? '০' : ''}${bn(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              Row(
                children: [
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      final busy = _loading ||
                          state?.processingState == ProcessingState.loading ||
                          state?.processingState == ProcessingState.buffering;
                      final playing = (state?.playing ?? false) && state?.processingState != ProcessingState.completed;
                      if (busy) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                        );
                      }
                      return IconButton(
                        iconSize: 40,
                        color: AppColors.accent,
                        icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill),
                        onPressed: _toggle,
                      );
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.title} (${_local ? 'অফলাইন' : 'অনলাইন'})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        StreamBuilder<Duration>(
                          stream: _player.positionStream,
                          builder: (context, snapshot) {
                            final pos = snapshot.data ?? Duration.zero;
                            final dur = _player.duration ?? Duration.zero;
                            final maxMs = dur.inMilliseconds <= 0 ? 1 : dur.inMilliseconds;
                            final value = pos.inMilliseconds.clamp(0, maxMs).toDouble();
                            return Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: value,
                                    max: maxMs.toDouble(),
                                    activeColor: AppColors.primaryGreen,
                                    onChanged: _loaded ? (v) => _player.seek(Duration(milliseconds: v.round())) : null,
                                  ),
                                ),
                                Text(_fmt(pos), style: const TextStyle(fontSize: 12)),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_dl != null)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3, value: _dl == 0 ? null : _dl),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: _local ? 'ডাউনলোড করা আছে (মুছতে চাপুন)' : 'অফলাইনের জন্য ডাউনলোড',
                      icon: Icon(_local ? Icons.download_done_rounded : Icons.download_rounded),
                      color: _local ? AppColors.accent : AppColors.subtle,
                      onPressed: _local ? _confirmDelete : _download,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
