import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_session.dart';

// ── Appointment model (Firestore-backed) ─────────────────────────────────────

class DoctorAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final DateTime date;
  final String slot;
  String status; // Pending | Completed | Cancelled
  final DateTime bookedAt;

  DoctorAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.slot,
    required this.status,
    required this.bookedAt,
  });

  factory DoctorAppointment.fromMap(String id, Map<String, dynamic> map) {
    return DoctorAppointment(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      slot: map['slot'] ?? '',
      status: map['status'] ?? 'Pending',
      bookedAt: (map['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'date': Timestamp.fromDate(date),
        'slot': slot,
        'status': status,
        'bookedAt': Timestamp.fromDate(bookedAt),
      };

  DoctorAppointment copyWith({String? status, DateTime? date, String? slot}) =>
      DoctorAppointment(
        id: id,
        patientId: patientId,
        patientName: patientName,
        doctorId: doctorId,
        doctorName: doctorName,
        date: date ?? this.date,
        slot: slot ?? this.slot,
        status: status ?? this.status,
        bookedAt: bookedAt,
      );
}

// ── Patient (for doctor's view) ───────────────────────────────────────────────

class DoctorPatient {
  final String userId;
  final String name;
  final bool isActive;

  DoctorPatient({
    required this.userId,
    required this.name,
    required this.isActive,
  });

  factory DoctorPatient.fromMap(Map<String, dynamic> map) => DoctorPatient(
        userId: map['userId'] ?? '',
        name: map['name'] ?? '',
        isActive: map['isActive'] ?? true,
      );
}

// ── Medical Report (Firestore) ────────────────────────────────────────────────

class FirestoreReport {
  final String id;
  final String patientId;
  final String patientName;
  final String reportType;
  final String notes;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String? fileUrl;

  FirestoreReport({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.reportType,
    required this.notes,
    required this.uploadedBy,
    required this.uploadedAt,
    this.fileUrl,
  });

  factory FirestoreReport.fromMap(String id, Map<String, dynamic> map) =>
      FirestoreReport(
        id: id,
        patientId: map['patientId'] ?? '',
        patientName: map['patientName'] ?? '',
        reportType: map['reportType'] ?? '',
        notes: map['notes'] ?? '',
        uploadedBy: map['uploadedBy'] ?? '',
        uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        fileUrl: map['fileUrl'],
      );
}

// ── ConsultationSummary (Firestore) ──────────────────────────────────────────

class FirestoreSummary {
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

  FirestoreSummary({
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
  });

  factory FirestoreSummary.fromMap(String id, Map<String, dynamic> map) =>
      FirestoreSummary(
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
        uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

// ── DoctorService ─────────────────────────────────────────────────────────────

class DoctorService {
  static final DoctorService _instance = DoctorService._();
  factory DoctorService() => _instance;
  DoctorService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _doctorId => AppUserSession.currentUser?.userId ?? '';
  String get _doctorName => AppUserSession.currentUser?.name ?? 'Doctor';

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('medical_reports');
  CollectionReference<Map<String, dynamic>> get _summaries =>
      _db.collection('consultation_summaries');

  // ── APPOINTMENTS ─────────────────────────────────────────────────────────

  Stream<List<DoctorAppointment>> appointmentsStream() {
    return _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DoctorAppointment.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> markCompleted(String appointmentId) async {
    await _appointments.doc(appointmentId).update({'status': 'Completed'});
  }

  Future<void> cancelAppointment(String appointmentId, String patientId,
      String patientName, String date, String slot) async {
    await _appointments.doc(appointmentId).update({'status': 'Cancelled'});
    await _db.collection('notifications').add({
      'recipientId': patientId,
      'type': 'cancellation',
      'title': 'Appointment Cancelled',
      'message':
          'Your appointment with $_doctorName on $date at $slot has been cancelled.',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rescheduleAppointment(
      String appointmentId, DateTime newDate, String newSlot) async {
    await _appointments.doc(appointmentId).update({
      'date': Timestamp.fromDate(newDate),
      'slot': newSlot,
      'status': 'Pending',
    });
  }

  // ── PATIENTS ─────────────────────────────────────────────────────────────

  Stream<List<DoctorPatient>> patientsStream() {
    return _users
        .where('role', isEqualTo: 'Patient')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DoctorPatient.fromMap(d.data())).toList());
  }

  Stream<List<String>> bookedPatientIdsStream() {
    return _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => d.data()['patientId'] as String)
            .toSet()
            .toList());
  }

  // ── MEDICAL REPORTS ───────────────────────────────────────────────────────

  Stream<List<FirestoreReport>> reportsForPatient(String patientId) {
    return _reports
        .where('patientId', isEqualTo: patientId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FirestoreReport.fromMap(d.id, d.data()))
            .toList());
  }

  // ── CONSULTATION SUMMARIES ────────────────────────────────────────────────

  Stream<List<FirestoreSummary>> summariesForPatient(String patientId) {
    return _summaries
        .where('patientId', isEqualTo: patientId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FirestoreSummary.fromMap(d.id, d.data()))
            .toList());
  }

  // ── DASHBOARD STATS ───────────────────────────────────────────────────────

  Future<Map<String, int>> fetchDashboardStats() async {
    final snap =
        await _appointments.where('doctorId', isEqualTo: _doctorId).get();
    final docs = snap.docs.map((d) => d.data()).toList();
    final today = DateTime.now();

    int todayCount = 0, pendingCount = 0, completedCount = 0;
    for (final d in docs) {
      final date = (d['date'] as Timestamp).toDate();
      final status = d['status'] as String;
      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) todayCount++;
      if (status == 'Pending') pendingCount++;
      if (status == 'Completed') completedCount++;
    }
    return {
      'total': docs.length,
      'today': todayCount,
      'pending': pendingCount,
      'completed': completedCount,
    };
  }

  // ── TODAY'S CONSULTATION QUEUE ────────────────────────────────────────────

  Stream<List<DoctorAppointment>> todayPendingStream() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('status', isEqualTo: 'Pending')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DoctorAppointment.fromMap(d.id, d.data()))
            .toList());
  }

  // ── DOCTOR PROFILE ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchDoctorProfile() async {
    final doc = await _users.doc(_doctorId).get();
    return doc.exists ? doc.data() : null;
  }
}