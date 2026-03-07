// lib/screens/pdf_viewer_stub.dart
//
// Mobile / Desktop stub — compiled when dart:html is NOT available.
// Exports the same function signatures as pdf_viewer_web.dart so that
// pdf_viewer_screen.dart compiles on every platform without errors.
// These functions are never actually called on non-web platforms because
// pdf_viewer_screen.dart short-circuits with url_launcher instead.

import 'package:flutter/material.dart';

/// Not called on mobile/desktop — url_launcher is used instead.
Future<String> registerPdfViewer(String url) async {
  throw UnsupportedError('registerPdfViewer is only available on web.');
}

/// Not called on mobile/desktop.
void openInNewTab(String url) {}

/// Not called on mobile/desktop.
void downloadFile(String url, String fileName) {}