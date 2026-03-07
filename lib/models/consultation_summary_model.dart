import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationSummaryModel {
  final String id;
  final String patientId;
  final String patientName;
  final String date;      // display string e.g. "Jan 10, 2026"
  final String time;      // display string e.g. "10:00 AM"
  final String doctorName;
  final String chiefComplaint;
  final String clinicalFindings;
  final String diagnosis;
  final String treatmentGiven;
  final String nurseNotes;
  final String uploadedBy;
  final DateTime uploadedAt;

  ConsultationSummaryModel({
    this.id = '',
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.time,
    required this.doctorName,
    required this.chiefComplaint,
    required this.clinicalFindings,
    required this.diagnosis,
    required this.treatmentGiven,
    required this.nurseNotes,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  // ── Firestore → model ─────────────────────────────────────────────────────

  factory ConsultationSummaryModel.fromMap(
      String id, Map<String, dynamic> map) {
    return ConsultationSummaryModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      date: map['visitDate'] ?? map['date'] ?? '',
      time: map['visitTime'] ?? map['time'] ?? '',
      doctorName: map['doctorName'] ?? '',
      chiefComplaint: map['chiefComplaint'] ?? '',
      clinicalFindings: map['clinicalFindings'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      treatmentGiven: map['treatmentGiven'] ?? '',
      nurseNotes: map['nurseNotes'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt:
          (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── model → Firestore ─────────────────────────────────────────────────────

  Map<String, dynamic> toFirestoreMap() {
    return {
      'patientId': patientId.trim().toUpperCase(),
      'patientName': patientName.trim(),
      'visitDate': date,
      'visitTime': time,
      'doctorName': doctorName.trim(),
      'chiefComplaint': chiefComplaint.trim(),
      'clinicalFindings': clinicalFindings.trim(),
      'diagnosis': diagnosis.trim(),
      'treatmentGiven': treatmentGiven.trim(),
      'nurseNotes': nurseNotes.trim(),
      'uploadedBy': uploadedBy.trim(),
      'uploadedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── Legacy display map (kept for any existing UI that uses it) ────────────

  Map<String, String> toSummaryMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'date': date,
      'time': time,
      'doctorName': doctorName,
      'chiefComplaint': chiefComplaint,
      'clinicalFindings': clinicalFindings,
      'diagnosis': diagnosis,
      'treatmentGiven': treatmentGiven,
      'nurseNotes': nurseNotes,
      'uploadedBy': uploadedBy,
    };
  }
}