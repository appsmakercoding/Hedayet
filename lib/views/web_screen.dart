import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/app_colors.dart';

/// অ্যাপের ভেতরে ওয়েবপেজ (ইউটিউব, PDF ইত্যাদি) দেখানোর স্ক্রিন।
class WebScreen extends StatefulWidget {
  final String title;
  final String url;

  /// খালি হলে সব ঠিকানায় যাওয়া যাবে; না হলে শুধু এই ডোমেইনগুলোতে (ও তাদের সাবডোমেইনে)।
  final List<String> allowedHosts;

  const WebScreen({
    super.key,
    required this.title,
    required this.url,
    this.allowedHosts = const [],
  });

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _failed = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            if (mounted) setState(() => _failed = true);
          },
          onNavigationRequest: (request) {
            if (!request.isMainFrame) return NavigationDecision.navigate;
            if (_isPdfLink(request.url)) {
              // WebView সরাসরি PDF দেখাতে পারে না, তাই Google-এর ভিউয়ারে দেখানো হয়
              _openInPdfViewer(request.url);
              return NavigationDecision.prevent;
            }
            if (_isAllowed(request.url)) return NavigationDecision.navigate;
            _snack('এই লিংকটি অ্যাপের ভেতরে খোলা যাবে না।');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  bool _isPdfLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.path.toLowerCase().endsWith('.pdf');
  }

  void _openInPdfViewer(String url) {
    final viewer = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(url)}';
    Future.microtask(() => _controller.loadRequest(Uri.parse(viewer)));
  }

  bool _isAllowed(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    const okSchemes = ['http', 'https', 'about', 'data', 'blob'];
    if (!okSchemes.contains(uri.scheme)) return false;
    if (widget.allowedHosts.isEmpty) return true;
    final host = uri.host;
    if (host.isEmpty) return true;
    for (final h in widget.allowedHosts) {
      if (host == h || host.endsWith('.$h')) return true;
    }
    return false;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _reload() {
    setState(() => _failed = false);
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: 'আবার লোড করুন',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reload,
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_progress < 100 && !_failed)
              LinearProgressIndicator(
                value: _progress == 0 ? null : _progress / 100,
                minHeight: 3,
                color: AppColors.accent,
                backgroundColor: Colors.transparent,
              ),
            if (_failed)
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.subtle),
                    const SizedBox(height: 12),
                    const Text(
                      'পেজ লোড হয়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('আবার চেষ্টা করুন'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
