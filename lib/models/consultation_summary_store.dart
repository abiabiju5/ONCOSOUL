import 'package:cloud_firestore/cloud_firestore.dart';
import 'consultation_summary_model.dart';

/// Persistent store for offline consultation summaries, backed by Firestore.
///
/// Replaces the old static in-memory map — data now survives app restarts
/// and is shared across all devices in real time.
///
/// Firestore collection: `consultation_summaries`
/// Public API is unchanged so no other file needs to be edited.
class ConsultationSummaryStore {
  ConsultationSummaryStore._();

  static final _col = FirebaseFirestore.instance
      .collection('consultation_summaries');

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Returns all offline summaries for [patientId], newest first.
  /// One-time fetch — use [summariesStream] for live updates.
  static Future<List<ConsultationSummaryModel>> getSummaries(
      String patientId) async {
    final snap = await _col
        .where('patientId', isEqualTo: patientId.trim().toUpperCase())
        .orderBy('uploadedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => ConsultationSummaryModel.fromMap(d.id, d.data()))
        .toList();
  }

  /// Live stream of summaries for [patientId], newest first.
  static Stream<List<ConsultationSummaryModel>> summariesStream(
      String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId.trim().toUpperCase())
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ConsultationSummaryModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Returns all unique patient IDs that have at least one summary.
  static Future<List<String>> get allPatientIds async {
    final snap = await _col.get();
    final ids = snap.docs
        .map((d) => (d.data()['patientId'] as String? ?? '').toUpperCase())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    return ids;
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Saves a new offline consultation summary to Firestore.
  static Future<void> addSummary(ConsultationSummaryModel summary) async {
    await _col.add(summary.toFirestoreMap());
  }
}