// lib/services/supabase_storage_service.dart
//
// Supabase Storage helper — upload files with progress and prepare public URLs.
//
// SETUP (one time):
//  1. Go to https://supabase.com → create a free project
//  2. Storage → create bucket named: medical-reports
//  3. Set bucket to Public (Policies → Allow public read)
//  4. Settings → API → copy Project URL and anon key
//  5. Paste them into _supabaseUrl and _anonKey below

import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class SupabaseStorageService {
  // ── REPLACE THESE WITH YOUR SUPABASE VALUES ──────────────────────────────
  static const String _supabaseUrl =
      'https://pcdipqhvtpxfyanbgdtt.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjZGlwcWh2dHB4ZnlhbmJnZHR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3MjkzOTksImV4cCI6MjA4ODMwNTM5OX0.0XUjv_pAa-zz5va4cYDpZsQLQeogZXQHZjA7TLM4Of0';
  // ─────────────────────────────────────────────────────────────────────────

  static const String _bucket = 'medical-reports';

  /// Uploads [bytes] to Supabase Storage and returns the public URL.
  ///
  /// [onProgress] is called with values from 0.0 to 1.0 as upload progresses.
  /// Progress is simulated in chunks since the http package does not expose
  /// real streaming upload progress — this gives the UI smooth feedback.
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

    // ── Simulate chunked progress before the actual upload ────────────────
    // The http package sends the full body in one go, so we emit fake
    // progress ticks (0 → 0.9) while the upload is in flight, then 1.0
    // once the server responds.
    Timer? progressTimer;
    double simulatedProgress = 0.0;

    if (onProgress != null) {
      onProgress(0.0);
      progressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        // Approach 0.9 asymptotically — never quite reaches it until done.
        simulatedProgress += (0.9 - simulatedProgress) * 0.15;
        onProgress(simulatedProgress.clamp(0.0, 0.9));
      });
    }

    try {
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $_anonKey',
          'Content-Type': contentType,
          'x-upsert': 'true',
        },
        body: bytes,
      );

      progressTimer?.cancel();

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Upload failed (${response.statusCode}): ${response.body}');
      }

      onProgress?.call(1.0);

      return '$_supabaseUrl/storage/v1/object/public/$_bucket/$path';
    } catch (e) {
      progressTimer?.cancel();
      rethrow;
    }
  }

  /// Supabase public URLs work directly — returns the URL unchanged.
  static String prepareViewUrl(String url) => url;
}