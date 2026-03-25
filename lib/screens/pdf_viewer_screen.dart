// lib/screens/pdf_viewer_screen.dart
//
// Cross-platform PDF viewer.
//
//  Platform       │ Strategy
//  ───────────────┼──────────────────────────────────────────────────────────
//  Web            │ <embed> platform view — browser built-in PDF renderer,
//                 │   no CORS issues, no blob-origin restriction
//  Android / iOS  │ Opens URL in Chrome Custom Tab / SFSafariViewController
//  Desktop        │ Opens URL in the default system browser

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Conditional import ─────────────────────────────────────────────────────────
// On web  → pdf_viewer_web.dart  (uses dart:html + dart:ui_web)
// On mobile/desktop → pdf_viewer_stub.dart (no platform libs, never called)
import 'pdf_viewer_stub.dart'
    if (dart.library.html) 'pdf_viewer_web.dart' as pdfWeb;
// ────────────────────────────────────────────────────────────────────────────

class PdfViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.fileUrl,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  static const Color _deepBlue = Color(0xFF0D47A1);
  static const Color _skyBlue  = Color(0xFF1E88E5);

  bool    _loading = true;
  String? _error;
  String? _viewId;
  late String _cleanUrl;

  @override
  void initState() {
    super.initState();
    _cleanUrl = widget.fileUrl.trim();

    if (kIsWeb) {
      _loadWeb();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openExternal());
    }
  }

  // ── Web: register <embed> platform view ─────────────────────────────────
  Future<void> _loadWeb() async {
    setState(() { _loading = true; _error = null; });
    try {
      final id = await pdfWeb.registerPdfViewer(_cleanUrl);
      if (mounted) setState(() { _viewId = id; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Mobile / Desktop: hand off to OS ────────────────────────────────────
  Future<void> _openExternal() async {
    final uri = Uri.parse(_cleanUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.of(context).pop();
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _loading = false;
        _error   = 'Could not open the document on this device.';
      });
    }
  }

  // ── Web helpers ──────────────────────────────────────────────────────────
  void _openTab()  => pdfWeb.openInNewTab(_cleanUrl);
  void _download() => pdfWeb.downloadFile(_cleanUrl, '${widget.title}.pdf');

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF525659),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_deepBlue, _skyBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (kIsWeb) ...[
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Open in new tab',
              onPressed: _openTab,
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download',
              onPressed: _download,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: 'Open in browser',
              onPressed: () async {
                final uri = Uri.parse(_cleanUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ── Loading ──────────────────────────────────────────────────────────
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44, height: 44,
              child: CircularProgressIndicator(
                  color: Color(0xFF1E88E5), strokeWidth: 3),
            ),
            SizedBox(height: 18),
            Text('Loading PDF…',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      );
    }

    // ── Error ────────────────────────────────────────────────────────────
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent, size: 52),
              const SizedBox(height: 16),
              const Text(
                'Could not load PDF',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (kIsWeb)
                    ElevatedButton.icon(
                      onPressed: _loadWeb,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  if (kIsWeb) const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(_cleanUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded,
                        size: 16, color: Color(0xFF1E88E5)),
                    label: const Text('Open in browser',
                        style: TextStyle(color: Color(0xFF1E88E5))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E88E5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // ── Web: render the <embed> platform view ────────────────────────────
    if (kIsWeb && _viewId != null) {
      return HtmlElementView(viewType: _viewId!);
    }

    return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E88E5)));
  }
}