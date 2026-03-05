import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Free file storage using Supabase Storage.
///
/// SETUP (one time, 5 minutes):
/// 1. Go to https://supabase.com → Sign up free (no credit card)
/// 2. Create a new project (choose any region)
/// 3. Go to Storage → Create a new bucket named: medical-reports
/// 4. Click the bucket → Policies → Add policy → Allow public read
/// 5. Go to Settings → API → copy your Project URL and anon key
/// 6. Replace _supabaseUrl and _anonKey below with your values
///
/// Free tier: 1GB storage, 2GB bandwidth/month — plenty for medical PDFs
class SupabaseStorageService {
  // ── REPLACE THESE WITH YOUR SUPABASE VALUES ────────────────────────────────
  static const String _supabaseUrl = 'https://pcdipqhvtpxfyanbgdtt.supabase.co';
  static const String _anonKey     = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjZGlwcWh2dHB4ZnlhbmJnZHR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3MjkzOTksImV4cCI6MjA4ODMwNTM5OX0.0XUjv_pAa-zz5va4cYDpZsQLQeogZXQHZjA7TLM4Of0';
  // ──────────────────────────────────────────────────────────────────────────

  static const String _bucket = 'medical _report';

  /// Uploads [bytes] to Supabase Storage and returns a public URL.
  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final path        = '$folder/$fileName';
    final contentType = fileName.toLowerCase().endsWith('.pdf')
        ? 'application/pdf'
        : 'application/octet-stream';

    final uri = Uri.parse(
        '$_supabaseUrl/storage/v1/object/$_bucket/$path');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': contentType,
        'x-upsert': 'true',
      },
      body: bytes,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Supabase upload failed (${response.statusCode}): ${response.body}');
    }

    // Return the public URL
    final publicUrl =
        '$_supabaseUrl/storage/v1/object/public/$_bucket/$path';
    return publicUrl;
  }

  /// Supabase public URLs work directly — no processing needed.
  static String prepareViewUrl(String url) => url;
  static String pdfViewerUrl(String url)   => url;
}