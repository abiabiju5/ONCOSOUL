// lib/screens/pdf_viewer_stub.dart
//
// Non-web stub — compiled on Android, iOS, and Desktop.
// These functions should never be called on those platforms because
// pdf_viewer_screen.dart gates all calls behind `kIsWeb`.
// They exist only so the conditional import compiles cleanly.

Future<String> registerPdfViewer(String url) async {
  throw UnsupportedError('registerPdfViewer is only supported on web.');
}

void openInNewTab(String url) {
  throw UnsupportedError('openInNewTab is only supported on web.');
}

void downloadFile(String url, String fileName) {
  throw UnsupportedError('downloadFile is only supported on web.');
}