// lib/services/url_launcher_service.dart
//
// Cross-platform helper to open a file/PDF URL.
//
//  Web          → pushes PdfViewerScreen (inline PDF.js iframe viewer)
//  Mobile       → opens in system browser via url_launcher
//  Desktop      → opens in system browser via url_launcher
//
// No dart:html imports here — all platform-specific code lives inside
// pdf_viewer_screen.dart and its conditional imports.

import 'package:flutter/material.dart';
import '../screens/pdf_viewer_screen.dart';

/// Opens [url] in the appropriate viewer for the current platform.
Future<void> openFileUrl(
  BuildContext context,
  String url, {
  String title = 'Report',
}) async {
  if (url.isEmpty) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PdfViewerScreen(fileUrl: url, title: title),
    ),
  );
}