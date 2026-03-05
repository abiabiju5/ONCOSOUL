import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Replaces CloudinaryService entirely.
/// Uses Firebase Storage — already in your project, no CORS issues,
/// files are publicly readable by default via download URLs.
class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads [bytes] to Firebase Storage and returns a public download URL.
  /// [folder]   e.g. "medical_reports/P2026"
  /// [fileName] e.g. "1234567890_report.pdf"
  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child('$folder/$fileName');

    final metadata = SettableMetadata(
      contentType: fileName.toLowerCase().endsWith('.pdf')
          ? 'application/pdf'
          : 'application/octet-stream',
    );

    final uploadTask = ref.putData(bytes, metadata);

    // Report progress
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
    }

    // Wait for completion
    await uploadTask;

    // Get a permanent public download URL
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }

  /// Returns the URL as-is — Firebase download URLs are always public
  /// and work directly in any browser or http.get() call.
  static String prepareViewUrl(String url) => url;

  /// Returns the URL as-is for the PDF viewer.
  static String pdfViewerUrl(String url) => url;
}