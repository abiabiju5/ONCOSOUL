import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName    = 'dlonb4ngr';
  static const String _uploadPreset = 'snjp7oew';
  static const String _baseUrl      = 'https://api.cloudinary.com/v1_1/$_cloudName';

  static String prepareViewUrl(String url) {
    String fixed = url;

    if (fixed.contains('docs.google.com/viewer')) {
      final uri   = Uri.tryParse(fixed);
      final inner = uri?.queryParameters['url'];
      if (inner != null && inner.isNotEmpty) fixed = inner;
    }

    if (fixed.contains('res.cloudinary.com') &&
        fixed.contains('/image/upload/') &&
        _isPdfUrl(fixed)) {
      fixed = fixed.replaceFirst('/image/upload/', '/raw/upload/');
    }

    fixed = fixed
        .replaceAll('/fl_inline/', '/')
        .replaceAll('/fl_inline,', '/')
        .replaceAll(',fl_inline/', '/');

    return fixed;
  }

  static bool _isPdfUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.contains('.pdf?') ||
        lower.contains('medical_reports') ||
        lower.contains('consultation_summar');
  }

  static String pdfViewerUrl(String rawStoredUrl) => prepareViewUrl(rawStoredUrl);

  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final ext      = fileName.split('.').last.toLowerCase();
    final isPdf    = ext == 'pdf';
    final endpoint = isPdf ? 'raw/upload' : 'image/upload';
    final uri      = Uri.parse('$_baseUrl/$endpoint');

    // ONLY these params are allowed for unsigned uploads:
    // upload_preset, folder, public_id, tags, context, metadata,
    // filename_override, manifest_transformation, manifest_json,
    // template, template_vars, regions, public_id_prefix
    // DO NOT add access_mode, type, resource_type etc.
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder']        = folder
      ..files.add(http.MultipartFile.fromBytes(
          'file', bytes, filename: fileName));

    final streamed = await request.send();
    int received   = 0;
    final total    = streamed.contentLength ?? bytes.length;
    final chunks   = <int>[];

    await for (final chunk in streamed.stream) {
      chunks.addAll(chunk);
      received += chunk.length;
      if (onProgress != null && total > 0) {
        onProgress((received / total).clamp(0.0, 1.0));
      }
    }

    final body = utf8.decode(chunks);
    if (streamed.statusCode != 200) {
      throw Exception(
          'Cloudinary upload failed (${streamed.statusCode}): $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url  = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary returned no URL. Response: $body');
    }
    return url;
  }
}