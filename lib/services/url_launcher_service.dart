import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/pdf_viewer_screen.dart';

/// Opens a file URL in the most appropriate viewer:
///
/// Flutter Web  → pushes [PdfViewerScreen] which renders an HTML <iframe>
///               inside the app. The browser's native PDF engine handles it —
///               no popups, no third-party viewers, no Content-Type issues.
///
/// Mobile/Desktop → opens via url_launcher (system PDF app / browser).
Future<void> openFileUrl(
  BuildContext context,
  String url, {
  String title = 'Report',
}) async {
  if (kIsWeb) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(fileUrl: url, title: title),
      ),
    );
  } else {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}