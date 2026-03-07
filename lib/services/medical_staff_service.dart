// lib/services/medical_staff_service.dart
//
// Complete backend service for all Medical Staff screens.
// Medical staff can: view all appointments, upload consultation summaries,
// upload medical reports, manage patient records, and receive notifications.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_session.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

/// An appointment record as seen by medical staff.
class StaffAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final DateTime date;
  final String slot;
  final String status;
  final DateTime bookedAt;
  final String? inlineNotes;

  const StaffAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.slot,
    required this.status,
    required this.bookedAt,
    this.inlineNotes,
  });

  factory StaffAppointment.fromMap(String id, Map<String, dynamic> map) =>
      StaffAppointment(
        id: id,
        patientId: map['patientId'] ?? '',
        patientName: map['patientName'] ?? '',
        doctorId: map['doctorId'] ?? '',
        doctorName: map['doctorName'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        slot: map['slot'] ?? '',
        status: map['status'] ?? 'Pending',
        bookedAt: (map['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        inlineNotes: map['notes'],
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// A patient summary as seen by medical staff.
class StaffPatient {
  final String userId;
  final String name;
  final bool isActive;
  final String? phone;
  final String? email;
  final String? bloodGroup;
  final String? gender;
  final int? age;
  final String? address;
  final String? profileUrl;

  const StaffPatient({
    required this.userId,
    required this.name,
    required this.isActive,
    this.phone,
    this.email,
    this.bloodGroup,
    this.gender,
    this.age,
    this.address,
    this.profileUrl,
  });

  factory StaffPatient.fromMap(Map<String, dynamic> map) => StaffPatient(
        userId: map['userId'] ?? '',
        name: map['name'] ?? '',
        isActive: map['isActive'] ?? true,
        phone: map['phone'],
        email: map['email'],
        bloodGroup: map['bloodGroup'],
        gender: map['gender'],
        age: map['age'] is int ? map['age'] as int : null,
        address: map['address'],
        profileUrl: map['profileUrl'],
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// A medical report as seen by medical staff.
class StaffMedicalReport {
  final String id;
  final String patientId;
  final String patientName;
  final String reportType;
  final String labName;
  final String notes;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String? fileUrl;

  const StaffMedicalReport({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.reportType,
    required this.labName,
    required this.notes,
    required this.uploadedBy,
    required this.uploadedAt,
    this.fileUrl,
  });

  factory StaffMedicalReport.fromMap(String id, Map<String, dynamic> map) =>
      StaffMedicalReport(
        id: id,
        patientId: map['patientId'] ?? '',
        patientName: map['patientName'] ?? '',
        reportType: map['reportType'] ?? '',
        labName: map['labName'] ?? '',
        notes: map['notes'] ?? '',
        uploadedBy: map['uploadedBy'] ?? '',
        uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        fileUrl: map['fileUrl'],
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// A consultation summary as seen by medical staff.
class StaffConsultationSummary {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorName;
  final String chiefComplaint;
  final String clinicalFindings;
  final String diagnosis;
  final String treatmentGiven;
  final String nurseNotes;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String visitDate;
  final String visitTime;

  const StaffConsultationSummary({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.chiefComplaint,
    required this.clinicalFindings,
    required this.diagnosis,
    required this.treatmentGiven,
    required this.nurseNotes,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.visitDate,
    required this.visitTime,
  });

  factory StaffConsultationSummary.fromMap(
          String id, Map<String, dynamic> map) =>
      StaffConsultationSummary(
        id: id,
        patientId: map['patientId'] ?? '',
        patientName: map['patientName'] ?? '',
        doctorName: map['doctorName'] ?? '',
        chiefComplaint: map['chiefComplaint'] ?? '',
        clinicalFindings: map['clinicalFindings'] ?? '',
        diagnosis: map['diagnosis'] ?? '',
        treatmentGiven: map['treatmentGiven'] ?? '',
        nurseNotes: map['nurseNotes'] ?? '',
        uploadedBy: map['uploadedBy'] ?? '',
        uploadedAt:
            (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        visitDate: map['visitDate'] ?? '',
        visitTime: map['visitTime'] ?? '',
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MedicalStaffService — singleton backend layer for all medical staff screens
// ═══════════════════════════════════════════════════════════════════════════════

class MedicalStaffService {
  static final MedicalStaffService _instance = MedicalStaffService._();
  factory MedicalStaffService() => _instance;
  MedicalStaffService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Identity ────────────────────────────────────────────────────────────
  String get _staffId => AppUserSession.currentUser?.userId ?? '';
  String get _staffName => AppUserSession.currentUser?.name ?? 'Staff';

  // ── Collection refs ─────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('medical_reports');
  CollectionReference<Map<String, dynamic>> get _summaries =>
      _db.collection('consultation_summaries');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<void> _notify({
    required String recipientId,
    required String type,
    required String title,
    required String message,
  }) async {
    try {
      await _notifications.add({
        'recipientId': recipientId,
        'type': type,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPOINTMENTS (read-only for staff + status updates)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of ALL appointments, sorted by date ascending (for ward use).
  Stream<List<StaffAppointment>> allAppointmentsStream() {
    return _appointments.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => StaffAppointment.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  /// Live stream filtered by status.
  Stream<List<StaffAppointment>> appointmentsByStatusStream(String status) {
    if (status == 'All') return allAppointmentsStream();
    return _appointments
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => StaffAppointment.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  /// Live stream — today's appointments.
  Stream<List<StaffAppointment>> todayAppointmentsStream() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _appointments
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => StaffAppointment.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  /// Fetch a single appointment by ID.
  Future<StaffAppointment?> fetchAppointmentById(String appointmentId) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return null;
    return StaffAppointment.fromMap(doc.id, doc.data()!);
  }

  /// Mark an appointment as Completed (staff can do this after in-person visit).
  Future<void> markAppointmentCompleted(String appointmentId) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return;
    final data = doc.data()!;

    await _appointments.doc(appointmentId).update({
      'status': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
      'completedBy': _staffId,
    });

    final patientId = data['patientId'] as String? ?? '';
    if (patientId.isNotEmpty) {
      await _notify(
        recipientId: patientId,
        type: 'completed',
        title: 'Visit Completed',
        message: 'Your appointment has been marked as completed by our staff.',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of all patients (role = Patient), sorted by name.
  Stream<List<StaffPatient>> allPatientsStream() {
    return _users.where('role', isEqualTo: 'Patient').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => StaffPatient.fromMap(d.data()))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// One-shot fetch of a patient's profile.
  Future<StaffPatient?> fetchPatientById(String patientId) async {
    final doc = await _users.doc(patientId).get();
    if (!doc.exists) return null;
    return StaffPatient.fromMap(doc.data()!);
  }

  /// Check whether a patient ID exists.
  Future<bool> patientExists(String patientId) async {
    final doc = await _users.doc(patientId.trim().toUpperCase()).get();
    return doc.exists && (doc.data()?['role'] == 'Patient');
  }

  /// Lookup patient name by ID.
  Future<String?> fetchPatientName(String patientId) async {
    final doc =
        await _users.doc(patientId.trim().toUpperCase()).get();
    return doc.exists ? doc.data()!['name'] as String? : null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDICAL REPORTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of all medical reports uploaded by this staff member.
  Stream<List<StaffMedicalReport>> myUploadsStream() {
    return _reports
        .where('uploadedBy', isEqualTo: _staffName)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => StaffMedicalReport.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  /// Live stream of all reports for a specific patient.
  Stream<List<StaffMedicalReport>> reportsForPatient(String patientId) {
    return _reports
        .where('patientId', isEqualTo: patientId.trim().toUpperCase())
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => StaffMedicalReport.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  /// Upload a new medical report for a patient.
  Future<void> uploadMedicalReport({
    required String patientId,
    required String patientName,
    required String reportType,
    required String labName,
    required DateTime reportDate,
    String notes = '',
    String? fileUrl,
  }) async {
    final normalizedId = patientId.trim().toUpperCase();

    await _reports.add({
      'patientId': normalizedId,
      'patientName': patientName.trim(),
      'reportType': reportType,
      'labName': labName.trim(),
      'notes': notes.trim(),
      'uploadedBy': _staffName,
      'uploadedAt': Timestamp.fromDate(reportDate),
      'createdAt': FieldValue.serverTimestamp(),
      if (fileUrl != null) 'fileUrl': fileUrl,
    });

    await _notify(
      recipientId: normalizedId,
      type: 'new_report',
      title: 'New Medical Report Available',
      message:
          'A $reportType report from $labName has been uploaded to your profile.',
    );
  }

  /// Delete a medical report (only reports uploaded by this staff member).
  Future<void> deleteMedicalReport(String reportId) async {
    await _reports.doc(reportId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSULTATION SUMMARIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of all summaries uploaded by this staff member.
  Stream<List<StaffConsultationSummary>> mySummariesStream() {
    return _summaries
        .where('uploadedBy', isEqualTo: _staffName)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => StaffConsultationSummary.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  /// Live stream of all summaries for a specific patient.
  Stream<List<StaffConsultationSummary>> summariesForPatient(
      String patientId) {
    return _summaries
        .where('patientId', isEqualTo: patientId.trim().toUpperCase())
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => StaffConsultationSummary.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  /// Upload a new consultation summary.
  Future<void> uploadConsultationSummary({
    required String patientId,
    required String patientName,
    required String doctorName,
    required String visitDate,
    required String visitTime,
    required String chiefComplaint,
    required String clinicalFindings,
    required String diagnosis,
    required String treatmentGiven,
    required String nurseNotes,
  }) async {
    final normalizedId = patientId.trim().toUpperCase();

    await _summaries.add({
      'patientId': normalizedId,
      'patientName': patientName.trim(),
      'doctorName': doctorName.trim(),
      'visitDate': visitDate,
      'visitTime': visitTime,
      'chiefComplaint': chiefComplaint.trim(),
      'clinicalFindings': clinicalFindings.trim(),
      'diagnosis': diagnosis.trim(),
      'treatmentGiven': treatmentGiven.trim(),
      'nurseNotes': nurseNotes.trim(),
      'uploadedBy': _staffName,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    await _notify(
      recipientId: normalizedId,
      type: 'summary_uploaded',
      title: 'Visit Summary Available',
      message:
          'A consultation summary for your visit on $visitDate has been added.',
    );

    // Also notify doctors who have appointments with this patient
    final apptSnap = await _appointments
        .where('patientId', isEqualTo: normalizedId)
        .where('status', isEqualTo: 'Pending')
        .get();

    final notifiedDoctors = <String>{};
    for (final doc in apptSnap.docs) {
      final doctorId = doc.data()['doctorId'] as String? ?? '';
      if (doctorId.isNotEmpty && !notifiedDoctors.contains(doctorId)) {
        notifiedDoctors.add(doctorId);
        await _notify(
          recipientId: doctorId,
          type: 'summary_uploaded',
          title: 'Patient Summary Updated',
          message:
              'A consultation summary for patient $patientName has been uploaded by $_staffName.',
        );
      }
    }
  }

  /// Update a consultation summary.
  Future<void> updateConsultationSummary(
      String summaryId, Map<String, dynamic> updates) async {
    await _summaries.doc(summaryId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _staffName,
    });
  }

  /// Delete a consultation summary.
  Future<void> deleteConsultationSummary(String summaryId) async {
    await _summaries.doc(summaryId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS (medical staff inbox)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream of this staff member's notifications, newest first.
  Stream<List<Map<String, dynamic>>> notificationsStream() {
    return _notifications
        .where('recipientId', isEqualTo: _staffId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
      list.sort((a, b) {
        final ta = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final tb = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return tb.compareTo(ta);
      });
      return list.take(50).toList();
    });
  }

  /// Count of unread notifications.
  Stream<int> unreadCountStream() {
    return _notifications
        .where('recipientId', isEqualTo: _staffId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Mark a single notification as read.
  Future<void> markNotificationRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read (batch).
  Future<void> markAllNotificationsRead() async {
    final snap = await _notifications
        .where('recipientId', isEqualTo: _staffId)
        .where('isRead', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD STATS (for medical staff home)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch today's appointment count and total summaries uploaded.
  Future<Map<String, int>> fetchStaffDashboardStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final results = await Future.wait([
      _appointments
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .get(),
      _appointments.where('status', isEqualTo: 'Pending').get(),
      _summaries.where('uploadedBy', isEqualTo: _staffName).get(),
      _reports.where('uploadedBy', isEqualTo: _staffName).get(),
    ]);

    return {
      'todayAppointments': results[0].docs.length,
      'pendingAppointments': results[1].docs.length,
      'summariesUploaded': results[2].docs.length,
      'reportsUploaded': results[3].docs.length,
    };
  }
}