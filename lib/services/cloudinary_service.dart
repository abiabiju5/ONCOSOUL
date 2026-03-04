import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Uploads an image or file to Cloudinary and returns the secure URL.
/// Uses unsigned upload with a preset — no API secret needed on device.
class CloudinaryService {
  static const String _cloudName   = 'dlonb4ngr';
  static const String _uploadPreset = 'snjp7oew';

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload';

  /// Upload [bytes] to Cloudinary under [folder].
  /// [fileName] is used as the public_id prefix.
  /// [onProgress] is called with 0.0→1.0 as bytes are sent.
  /// Returns the secure HTTPS URL of the uploaded file.
  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse(_uploadUrl);

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder']        = folder
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));

    // Send with progress tracking via ByteStream
    final streamed = await request.send();

    // Track upload progress
    int received = 0;
    final total  = streamed.contentLength ?? bytes.length;
    final chunks  = <int>[];

    await for (final chunk in streamed.stream) {
      chunks.addAll(chunk);
      received += chunk.length;
      if (onProgress != null && total > 0) {
        onProgress((received / total).clamp(0.0, 1.0));
      }
    }

    final body = utf8.decode(chunks);

    if (streamed.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${streamed.statusCode}): $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url  = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary returned no URL. Response: $body');
    }
    return url;
  }
}