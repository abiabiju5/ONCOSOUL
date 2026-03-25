// lib/screens/pdf_viewer_web.dart
//
// Web-only PDF viewer.
// Uses a direct <embed> platform view — the browser's built-in PDF renderer
// fetches the URL natively, avoiding the null-origin CORS block that occurs
// when PDF.js runs inside a blob:// iframe.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;

/// Registers an <embed> element pointing at [url] as a Flutter platform view.
/// Returns the [viewId] for use with HtmlElementView, or throws.
Future<String> registerPdfViewer(String url) async {
  final viewId = 'pdf-embed-${DateTime.now().millisecondsSinceEpoch}';

  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewId, (_) {
    final embed = html.EmbedElement()
      ..src    = url
      ..type   = 'application/pdf'
      ..style.width   = '100%'
      ..style.height  = '100%'
      ..style.border  = 'none';
    return embed;
  });

  return viewId;
}

/// Opens [url] in a new browser tab.
void openInNewTab(String url) => html.window.open(url, '_blank');

/// Triggers a browser download for [url] with the given [fileName].
void downloadFile(String url, String fileName) {
  final a = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..setAttribute('target', '_blank');
  html.document.body?.append(a);
  a.click();
  a.remove();
}