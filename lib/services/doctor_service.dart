import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_session.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

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
  final String? inlineNotes;
  final String? cancelReason;

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
    this.inlineNotes,
    this.cancelReason,
  });

  factory DoctorAppointment.fromMap(String id, Map<String, dynamic> map) =>
      DoctorAppointment(
        id: id,
        patientId: map['patientId'] ?? '',
        patientName: map['patientName'] ?? '',
        doctorId: map['doctorId'] ?? '',
        doctorName: map['doctorName'] ?? '',
        date: (map['date'] as Timestamp).toDate(),
        slot: map['slot'] ?? '',
        status: map['status'] ?? 'Pending',
        bookedAt: (map['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        inlineNotes: map['notes'],
        cancelReason: map['cancelReason'],
      );

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'date': Timestamp.fromDate(date),
        'slot': slot,
        'status': status,
        'bookedAt': Timestamp.fromDate(bookedAt),
        if (inlineNotes != null) 'notes': inlineNotes,
        if (cancelReason != null) 'cancelReason': cancelReason,
      };

  DoctorAppointment copyWith({
    String? status,
    DateTime? date,
    String? slot,
    String? inlineNotes,
    String? cancelReason,
  }) =>
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
        inlineNotes: inlineNotes ?? this.inlineNotes,
        cancelReason: cancelReason ?? this.cancelReason,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class DoctorPatient {
  final String userId;
  final String name;
  final bool isActive;
  final String? phone;
  final String? email;
  final String? profileUrl;
  final String? bloodGroup;
  final String? gender;
  final int? age;
  final String? address;
  final int appointmentCount;

  DoctorPatient({
    required this.userId,
    required this.name,
    required this.isActive,
    this.phone,
    this.email,
    this.profileUrl,
    this.bloodGroup,
    this.gender,
    this.age,
    this.address,
    this.appointmentCount = 0,
  });

  factory DoctorPatient.fromMap(Map<String, dynamic> map,
          {int appointmentCount = 0}) =>
      DoctorPatient(
        userId: map['userId'] ?? '',
        name: map['name'] ?? '',
        isActive: map['isActive'] ?? true,
        phone: map['phone'],
        email: map['email'],
        profileUrl: map['profileUrl'],
        bloodGroup: map['bloodGroup'],
        gender: map['gender'],
        age: map['age'] is int ? map['age'] as int : null,
        address: map['address'],
        appointmentCount: appointmentCount,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class FirestoreReport {
  final String id;
  final String patientId;
  final String patientName;
  final String reportType;
  final String labName;
  final String notes;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String? fileUrl;

  FirestoreReport({
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

  factory FirestoreReport.fromMap(String id, Map<String, dynamic> map) =>
      FirestoreReport(
        id: id,
        patientId: map['patientId'] ?? '',
        patientName: map['patientName'] ?? '',
        reportType: map['reportType'] ?? '',
        labName: map['labName'] ?? '',
        notes: map['notes'] ?? '',
        uploadedBy: map['uploadedBy'] ?? '',
        uploadedAt:
            (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        fileUrl: map['fileUrl'],
      );
}

// ─────────────────────────────────────────────────────────────────────────────

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
  final String visitDate;
  final String visitTime;

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
    this.visitDate = '',
    this.visitTime = '',
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
        uploadedAt:
            (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        visitDate: map['visitDate'] ?? '',
        visitTime: map['visitTime'] ?? '',
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class DoctorPrescription {
  final String id;
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final List<Map<String, String>> medicines;
  final DateTime createdAt;
  final String? diagnosis;

  DoctorPrescription({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.medicines,
    required this.createdAt,
    this.diagnosis,
  });

  factory DoctorPrescription.fromMap(String id, Map<String, dynamic> map) {
    final rawMeds = map['medicines'] as List<dynamic>? ?? [];
    final meds = rawMeds.map((m) {
      final entry = m as Map<String, dynamic>;
      return entry.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }).toList();
    return DoctorPrescription(
      id: id,
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      medicines: meds,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      diagnosis: map['diagnosis'],
    );
  }

  Map<String, dynamic> toMap() => {
        'appointmentId': appointmentId,
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'medicines': medicines,
        'createdAt': Timestamp.fromDate(createdAt),
        if (diagnosis != null) 'diagnosis': diagnosis,
      };
}

// ─────────────────────────────────────────────────────────────────────────────

/// Firestore-backed notification model (for the doctor's inbox).
class DoctorFirestoreNotification {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String message;
  bool isRead;
  final DateTime createdAt;

  DoctorFirestoreNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory DoctorFirestoreNotification.fromMap(
          String id, Map<String, dynamic> map) =>
      DoctorFirestoreNotification(
        id: id,
        recipientId: map['recipientId'] ?? '',
        type: map['type'] ?? '',
        title: map['title'] ?? '',
        message: map['message'] ?? '',
        isRead: map['isRead'] ?? false,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// Rich stats object returned by [DoctorService.statsStream].
class DashboardStats {
  final int total;
  final int today;
  final int pending;
  final int completed;
  final int cancelled;
  final int patients;

  const DashboardStats({
    this.total = 0,
    this.today = 0,
    this.pending = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.patients = 0,
  });

  Map<String, int> toMap() => {
        'total': total,
        'today': today,
        'pending': pending,
        'completed': completed,
        'cancelled': cancelled,
        'patients': patients,
      };
}

// ─────────────────────────────────────────────────────────────────────────────

/// A single saved doctor note for an appointment.
class ConsultationNote {
  final String id;
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConsultationNote({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConsultationNote.fromMap(String id, Map<String, dynamic> map) =>
      ConsultationNote(
        id: id,
        appointmentId: map['appointmentId'] ?? '',
        patientId: map['patientId'] ?? '',
        patientName: map['patientName'] ?? '',
        doctorId: map['doctorId'] ?? '',
        doctorName: map['doctorName'] ?? '',
        notes: map['notes'] ?? '',
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// Doctor availability / schedule model.
class DoctorAvailability {
  final String doctorId;
  final Map<String, bool> workingDays;   // 'Monday' → true/false
  final String startTime;                 // e.g. '09:00 AM'
  final String endTime;                   // e.g. '05:00 PM'
  final int slotDurationMinutes;
  final List<String> blockedDates;        // 'yyyy-MM-dd' strings
  final List<String> blockedSlots;        // 'yyyy-MM-dd|slot' strings

  const DoctorAvailability({
    required this.doctorId,
    required this.workingDays,
    this.startTime = '09:00 AM',
    this.endTime = '05:00 PM',
    this.slotDurationMinutes = 30,
    this.blockedDates = const [],
    this.blockedSlots = const [],
  });

  factory DoctorAvailability.fromMap(Map<String, dynamic> map) {
    final wd = <String, bool>{};
    final raw = map['workingDays'] as Map<String, dynamic>? ?? {};
    raw.forEach((k, v) => wd[k] = v as bool? ?? false);
    return DoctorAvailability(
      doctorId: map['doctorId'] ?? '',
      workingDays: wd,
      startTime: map['startTime'] ?? '09:00 AM',
      endTime: map['endTime'] ?? '05:00 PM',
      slotDurationMinutes: map['slotDurationMinutes'] as int? ?? 30,
      blockedDates: List<String>.from(map['blockedDates'] ?? []),
      blockedSlots: List<String>.from(map['blockedSlots'] ?? []),
    );
  }

  static DoctorAvailability defaultAvailability(String doctorId) =>
      DoctorAvailability(
        doctorId: doctorId,
        workingDays: {
          'Monday': true,
          'Tuesday': true,
          'Wednesday': true,
          'Thursday': true,
          'Friday': true,
          'Saturday': false,
          'Sunday': false,
        },
      );

  Map<String, dynamic> toMap() => {
        'doctorId': doctorId,
        'workingDays': workingDays,
        'startTime': startTime,
        'endTime': endTime,
        'slotDurationMinutes': slotDurationMinutes,
        'blockedDates': blockedDates,
        'blockedSlots': blockedSlots,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────

/// Analytics data point for charts.
class AppointmentDataPoint {
  final String label;
  final int count;

  const AppointmentDataPoint({required this.label, required this.count});
}

// ═══════════════════════════════════════════════════════════════════════════════
// DoctorService — singleton backend layer for all doctor-facing screens
// ═══════════════════════════════════════════════════════════════════════════════

class DoctorService {
  static final DoctorService _instance = DoctorService._();
  factory DoctorService() => _instance;
  DoctorService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Identity ────────────────────────────────────────────────────────────
  String get _doctorId => AppUserSession.currentUser?.userId ?? '';
  String get _doctorName => AppUserSession.currentUser?.name ?? 'Doctor';

  // ── Collection refs ─────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('medical_reports');
  CollectionReference<Map<String, dynamic>> get _summaries =>
      _db.collection('consultation_summaries');
  CollectionReference<Map<String, dynamic>> get _notes =>
      _db.collection('doctor_notes');
  CollectionReference<Map<String, dynamic>> get _prescriptions =>
      _db.collection('prescriptions');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _availability =>
      _db.collection('doctor_availability');

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<void> _notify({
    required String recipientId,
    required String type,
    required String title,
    required String message,
  }) async {
    await _notifications.add({
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final out = <List<T>>[];
    for (int i = 0; i < list.length; i += size) {
      out.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return out;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _weekdayName(int weekday) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday - 1];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPOINTMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream — ALL appointments for this doctor, ascending by date.
  Stream<List<DoctorAppointment>> appointmentsStream() {
    return _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => DoctorAppointment.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => a.date.compareTo(b.date));
          return list;
        });
  }

  /// Live stream — today's PENDING appointments (consultation queue).
  Stream<List<DoctorAppointment>> todayPendingStream() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => DoctorAppointment.fromMap(d.id, d.data()))
              .where((a) => !a.date.isBefore(start) && a.date.isBefore(end))
              .toList();
          list.sort((a, b) => a.date.compareTo(b.date));
          return list;
        });
  }

  /// Live stream — appointments by status (Pending | Completed | Cancelled).
  Stream<List<DoctorAppointment>> appointmentsByStatusStream(String status) {
    return _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => DoctorAppointment.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  /// Live stream — upcoming (future + pending) appointments.
  Stream<List<DoctorAppointment>> upcomingAppointmentsStream() {
    final now = DateTime.now();
    return _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => DoctorAppointment.fromMap(d.id, d.data()))
              .where((a) => a.date.isAfter(now))
              .toList();
          list.sort((a, b) => a.date.compareTo(b.date));
          return list;
        });
  }

  /// Live stream — all appointments for a specific patient with this doctor.
  Stream<List<DoctorAppointment>> appointmentsForPatientStream(String patientId) {
    return _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => DoctorAppointment.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  /// Fetch a single appointment by Firestore document ID.
  Future<DoctorAppointment?> fetchAppointmentById(String appointmentId) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return null;
    return DoctorAppointment.fromMap(doc.id, doc.data()!);
  }

  /// Mark appointment as Completed and notify the patient.
  Future<void> markCompleted(String appointmentId) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return;
    final appt = DoctorAppointment.fromMap(doc.id, doc.data()!);

    await _appointments.doc(appointmentId).update({
      'status': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    await _notify(
      recipientId: appt.patientId,
      type: 'completed',
      title: 'Consultation Completed',
      message: 'Your consultation with Dr. $_doctorName on '
          '${appt.date.day}/${appt.date.month}/${appt.date.year} '
          'at ${appt.slot} has been marked completed.',
    );
  }

  /// Cancel an appointment and notify the patient.
  Future<void> cancelAppointment(
    String appointmentId,
    String patientId,
    String patientName,
    String date,
    String slot, {
    String? reason,
  }) async {
    await _appointments.doc(appointmentId).update({
      'status': 'Cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      if (reason != null) 'cancelReason': reason,
    });
    await _notify(
      recipientId: patientId,
      type: 'cancellation',
      title: 'Appointment Cancelled',
      message: 'Your appointment with Dr. $_doctorName on $date at $slot '
          'has been cancelled.${reason != null ? ' Reason: $reason' : ''}',
    );
  }

  /// Reschedule an appointment and notify the patient.
  Future<void> rescheduleAppointment(
    String appointmentId,
    DateTime newDate,
    String newSlot,
  ) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return;
    final appt = DoctorAppointment.fromMap(doc.id, doc.data()!);

    await _appointments.doc(appointmentId).update({
      'date': Timestamp.fromDate(newDate),
      'slot': newSlot,
      'status': 'Pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final dateStr = '${newDate.day}/${newDate.month}/${newDate.year}';
    await _notify(
      recipientId: appt.patientId,
      type: 'rescheduled',
      title: 'Appointment Rescheduled',
      message: 'Your appointment with Dr. $_doctorName has been rescheduled '
          'to $dateStr at $newSlot.',
    );
  }

  /// Batch-cancel all pending appointments for a specific patient.
  Future<void> cancelAllAppointmentsForPatient(
    String patientId, {
    String? reason,
  }) async {
    final snap = await _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('patientId', isEqualTo: patientId)
        .where('status', isEqualTo: 'Pending')
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'status': 'Cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        if (reason != null) 'cancelReason': reason,
      });
    }
    await batch.commit();

    if (snap.docs.isNotEmpty) {
      await _notify(
        recipientId: patientId,
        type: 'cancellation',
        title: 'Appointments Cancelled',
        message: 'All your pending appointments with Dr. $_doctorName have been cancelled.',
      );
    }
  }

  /// Add inline notes directly to an appointment document.
  Future<void> addAppointmentNote(String appointmentId, String notes) async {
    await _appointments.doc(appointmentId).update({
      'notes': notes.trim(),
      'notesUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Verify that an appointment belongs to this doctor.
  Future<bool> isOwnAppointment(String appointmentId) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return false;
    return doc.data()?['doctorId'] == _doctorId;
  }

  /// Book a new appointment (called by doctor or admin on behalf of patient).
  /// Returns the new appointment document ID.
  Future<String> bookAppointment({
    required String patientId,
    required String patientName,
    required DateTime date,
    required String slot,
  }) async {
    // Validate slot availability
    final booked = await bookedSlotsOnDate(date);
    if (booked.contains(slot)) {
      throw Exception('Slot $slot is already booked on ${_dateKey(date)}.');
    }

    final ref = await _appointments.add({
      'doctorId': _doctorId,
      'doctorName': _doctorName,
      'patientId': patientId,
      'patientName': patientName,
      'date': Timestamp.fromDate(date),
      'slot': slot,
      'status': 'Pending',
      'bookedAt': FieldValue.serverTimestamp(),
    });

    // Notify doctor
    await _notify(
      recipientId: _doctorId,
      type: 'new_appointment',
      title: 'New Appointment Booked',
      message: '$patientName has booked an appointment on '
          '${date.day}/${date.month}/${date.year} at $slot.',
    );

    // Notify patient
    await _notify(
      recipientId: patientId,
      type: 'confirmation',
      title: 'Appointment Confirmed',
      message: 'Your appointment with Dr. $_doctorName on '
          '${date.day}/${date.month}/${date.year} at $slot is confirmed.',
    );

    return ref.id;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream — unique patients who have had at least one appointment with
  /// this doctor. Includes full profile, appointment count, sorted by name.
  Stream<List<DoctorPatient>> patientsStream() {
    return _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .snapshots()
        .asyncMap((apptSnap) async {
      final countMap = <String, int>{};
      for (final d in apptSnap.docs) {
        final pid = d.data()['patientId'] as String? ?? '';
        if (pid.isNotEmpty) countMap[pid] = (countMap[pid] ?? 0) + 1;
      }
      if (countMap.isEmpty) return <DoctorPatient>[];

      final ids = countMap.keys.toList();
      final results = <DoctorPatient>[];

      for (final chunk in _chunk(ids, 30)) {
        final snap = await _users.where('userId', whereIn: chunk).get();
        for (final doc in snap.docs) {
          results.add(DoctorPatient.fromMap(
            doc.data(),
            appointmentCount: countMap[doc.data()['userId'] ?? ''] ?? 0,
          ));
        }
      }
      results.sort((a, b) => a.name.compareTo(b.name));
      return results;
    });
  }

  /// Fetch a single patient's full profile from Firestore.
  Future<DoctorPatient?> fetchPatientById(String patientId) async {
    final doc = await _users.doc(patientId).get();
    if (!doc.exists) return null;

    final apptSnap = await _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('patientId', isEqualTo: patientId)
        .get();

    return DoctorPatient.fromMap(
      doc.data()!,
      appointmentCount: apptSnap.docs.length,
    );
  }

  /// Live stream — patients filtered by a name/ID/email/phone substring.
  Stream<List<DoctorPatient>> searchPatientsStream(String query) {
    return patientsStream().map((patients) {
      if (query.isEmpty) return patients;
      final lower = query.toLowerCase();
      return patients
          .where((p) =>
              p.name.toLowerCase().contains(lower) ||
              p.userId.toLowerCase().contains(lower) ||
              (p.email?.toLowerCase().contains(lower) ?? false) ||
              (p.phone?.contains(lower) ?? false))
          .toList();
    });
  }

  /// Live stream of a patient's Firestore profile document.
  Stream<Map<String, dynamic>?> patientProfileStream(String patientId) {
    return _users.doc(patientId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }

  /// Check whether a userId exists in the users collection.
  Future<bool> patientExists(String patientId) async {
    final doc = await _users.doc(patientId).get();
    return doc.exists;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDICAL REPORTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream — a specific patient's reports, newest first.
  Stream<List<FirestoreReport>> reportsForPatient(String patientId) {
    return _reports
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => FirestoreReport.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return list;
        });
  }

  /// Live stream — ALL reports uploaded by/for this doctor's patients.
  Stream<List<FirestoreReport>> allReportsStream() {
    return _reports
        .orderBy('uploadedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => FirestoreReport.fromMap(d.id, d.data())).toList());
  }

  /// Upload a medical report to Firestore and notify the patient.
  Future<void> uploadMedicalReport({
    required String patientId,
    required String patientName,
    required String reportType,
    required String labName,
    required String uploadedBy,
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
      'uploadedBy': uploadedBy.trim(),
      'uploadedAt': Timestamp.fromDate(reportDate),
      'createdAt': FieldValue.serverTimestamp(),
      if (fileUrl != null) 'fileUrl': fileUrl,
    });

    await _notify(
      recipientId: normalizedId,
      type: 'new_report',
      title: 'New Medical Report Available',
      message: 'A $reportType report from $labName has been uploaded to your profile.',
    );
  }

  /// Update notes on an existing report.
  Future<void> updateReportNotes(String reportId, String notes) async {
    await _reports.doc(reportId).update({
      'notes': notes.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a medical report by its document ID.
  Future<void> deleteMedicalReport(String reportId) async {
    await _reports.doc(reportId).delete();
  }

  /// Fetch reports for a patient within a date range.
  Future<List<FirestoreReport>> fetchReportsInRange(
      String patientId, DateTime from, DateTime to) async {
    final snap = await _reports
        .where('patientId', isEqualTo: patientId)
        .where('uploadedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('uploadedAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();
    final list = snap.docs
        .map((d) => FirestoreReport.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return list;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSULTATION SUMMARIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream — a patient's offline visit summaries, newest first.
  Stream<List<FirestoreSummary>> summariesForPatient(String patientId) {
    return _summaries
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => FirestoreSummary.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return list;
        });
  }

  /// Live stream — ALL summaries by this doctor.
  Stream<List<FirestoreSummary>> allSummariesStream() {
    return _summaries
        .where('doctorName', isEqualTo: _doctorName)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => FirestoreSummary.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return list;
        });
  }

  /// Upload a consultation summary.
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
    required String uploadedBy,
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
      'uploadedBy': uploadedBy.trim(),
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    // Notify patient
    await _notify(
      recipientId: normalizedId,
      type: 'summary_uploaded',
      title: 'Visit Summary Available',
      message: 'A consultation summary for your visit on $visitDate has been added.',
    );
  }

  /// Update fields of an existing consultation summary.
  Future<void> updateConsultationSummary(
      String summaryId, Map<String, dynamic> updates) async {
    await _summaries.doc(summaryId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a consultation summary by its document ID.
  Future<void> deleteConsultationSummary(String summaryId) async {
    await _summaries.doc(summaryId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOCTOR NOTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream — notes for a specific appointment (real-time updates).
  Stream<ConsultationNote?> notesStream(String appointmentId) {
    return _notes
        .where('appointmentId', isEqualTo: appointmentId)
        .where('doctorId', isEqualTo: _doctorId)
        .limit(1)
        .snapshots()
        .map((s) {
      if (s.docs.isEmpty) return null;
      return ConsultationNote.fromMap(s.docs.first.id, s.docs.first.data());
    });
  }

  /// Save or update doctor notes for an appointment (upsert pattern).
  Future<void> saveConsultationNotes({
    required String appointmentId,
    required String patientId,
    required String patientName,
    required String notes,
  }) async {
    final existing = await _notes
        .where('appointmentId', isEqualTo: appointmentId)
        .where('doctorId', isEqualTo: _doctorId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await _notes.doc(existing.docs.first.id).update({
        'notes': notes.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _notes.add({
        'appointmentId': appointmentId,
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': _doctorId,
        'doctorName': _doctorName,
        'notes': notes.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Fetch saved notes text for an appointment (used to pre-fill the editor).
  Future<String> fetchConsultationNotes(String appointmentId) async {
    final snap = await _notes
        .where('appointmentId', isEqualTo: appointmentId)
        .where('doctorId', isEqualTo: _doctorId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return '';
    return (snap.docs.first.data()['notes'] as String?) ?? '';
  }

  /// Delete notes for a specific appointment.
  Future<void> deleteConsultationNotes(String appointmentId) async {
    final snap = await _notes
        .where('appointmentId', isEqualTo: appointmentId)
        .where('doctorId', isEqualTo: _doctorId)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  /// Live stream — all notes written by this doctor, newest first.
  Stream<List<ConsultationNote>> allNotesStream() {
    return _notes
        .where('doctorId', isEqualTo: _doctorId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => ConsultationNote.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Live stream — all notes for a specific patient from this doctor.
  Stream<List<ConsultationNote>> notesForPatientStream(String patientId) {
    return _notes
        .where('doctorId', isEqualTo: _doctorId)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => ConsultationNote.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRESCRIPTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save a prescription to Firestore and notify the patient.
  Future<void> savePrescription({
    required String appointmentId,
    required String patientId,
    required String patientName,
    required List<Map<String, String>> medicines,
    String? diagnosis,
  }) async {
    await _prescriptions.add({
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': _doctorId,
      'doctorName': _doctorName,
      'medicines': medicines,
      if (diagnosis != null) 'diagnosis': diagnosis,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _notify(
      recipientId: patientId,
      type: 'prescription',
      title: 'Prescription Issued',
      message: 'Dr. $_doctorName has issued a prescription for your recent consultation.',
    );
  }

  /// Live stream — all prescriptions issued by this doctor, newest first.
  Stream<List<DoctorPrescription>> prescriptionsStream() {
    return _prescriptions
        .where('doctorId', isEqualTo: _doctorId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => DoctorPrescription.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Live stream — prescriptions for a specific patient by this doctor.
  Stream<List<DoctorPrescription>> prescriptionsForPatientStream(
      String patientId) {
    return _prescriptions
        .where('doctorId', isEqualTo: _doctorId)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => DoctorPrescription.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Fetch the most recent prescription for a specific appointment.
  Future<DoctorPrescription?> fetchPrescriptionForAppointment(
      String appointmentId) async {
    final snap = await _prescriptions
        .where('appointmentId', isEqualTo: appointmentId)
        .where('doctorId', isEqualTo: _doctorId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return DoctorPrescription.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  /// Delete a prescription by Firestore document ID.
  Future<void> deletePrescription(String prescriptionId) async {
    await _prescriptions.doc(prescriptionId).delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD STATS
  // ═══════════════════════════════════════════════════════════════════════════

  /// One-shot fetch of dashboard stats (compatible with existing Map<String,int> callers).
  Future<Map<String, int>> fetchDashboardStats() async {
    final snap =
        await _appointments.where('doctorId', isEqualTo: _doctorId).get();
    final today = DateTime.now();
    int todayCount = 0, pendingCount = 0, completedCount = 0, cancelledCount = 0;
    final patientIds = <String>{};

    for (final d in snap.docs) {
      final data = d.data();
      final date = (data['date'] as Timestamp).toDate();
      final status = data['status'] as String? ?? '';
      final pid = data['patientId'] as String? ?? '';

      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        todayCount++;
      }
      if (status == 'Pending') pendingCount++;
      if (status == 'Completed') completedCount++;
      if (status == 'Cancelled') cancelledCount++;
      if (pid.isNotEmpty) patientIds.add(pid);
    }

    return {
      'total': snap.docs.length,
      'today': todayCount,
      'pending': pendingCount,
      'completed': completedCount,
      'cancelled': cancelledCount,
      'patients': patientIds.length,
    };
  }

  /// Live stream of dashboard stats — updates automatically as data changes.
  Stream<DashboardStats> statsStream() {
    return _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .snapshots()
        .map((snap) {
      final today = DateTime.now();
      int todayCount = 0, pendingCount = 0, completedCount = 0, cancelledCount = 0;
      final patientIds = <String>{};

      for (final d in snap.docs) {
        final data = d.data();
        final date = (data['date'] as Timestamp).toDate();
        final status = data['status'] as String? ?? '';
        final pid = data['patientId'] as String? ?? '';

        if (date.year == today.year &&
            date.month == today.month &&
            date.day == today.day) {
          todayCount++;
        }
        if (status == 'Pending') pendingCount++;
        if (status == 'Completed') completedCount++;
        if (status == 'Cancelled') cancelledCount++;
        if (pid.isNotEmpty) patientIds.add(pid);
      }

      return DashboardStats(
        total: snap.docs.length,
        today: todayCount,
        pending: pendingCount,
        completed: completedCount,
        cancelled: cancelledCount,
        patients: patientIds.length,
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOCTOR PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch the doctor's own Firestore profile document.
  Future<Map<String, dynamic>?> fetchDoctorProfile() async {
    final doc = await _users.doc(_doctorId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Live stream of the doctor's own profile document.
  Stream<Map<String, dynamic>?> profileStream() {
    return _users
        .doc(_doctorId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// Update editable profile fields and refresh the local session.
  Future<void> updateDoctorProfile({
    String? phone,
    String? specialty,
    String? profileUrl,
    String? bio,
    String? clinicName,
    String? clinicAddress,
  }) async {
    if (_doctorId.isEmpty) throw Exception('Not logged in');

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (phone != null) updates['phone'] = phone.trim();
    if (specialty != null) updates['specialty'] = specialty.trim();
    if (profileUrl != null) updates['profileUrl'] = profileUrl;
    if (bio != null) updates['bio'] = bio.trim();
    if (clinicName != null) updates['clinicName'] = clinicName.trim();
    if (clinicAddress != null) updates['clinicAddress'] = clinicAddress.trim();

    await _users.doc(_doctorId).update(updates);

    // Refresh in-memory session so UI reflects changes immediately
    final refreshed = await _users.doc(_doctorId).get();
    if (refreshed.exists) AppUserSession.fromDoc(refreshed);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIRESTORE NOTIFICATIONS (doctor's personal inbox)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Live stream — notifications addressed to this doctor, newest first.
  Stream<List<DoctorFirestoreNotification>> notificationsStream() {
    return _notifications
        .where('recipientId', isEqualTo: _doctorId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => DoctorFirestoreNotification.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list.take(50).toList();
        });
  }

  /// Live stream — unread notification count (for badge).
  Stream<int> unreadNotificationCountStream() {
    return _notifications
        .where('recipientId', isEqualTo: _doctorId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Mark a single notification as read.
  Future<void> markNotificationRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  /// Mark ALL unread notifications for this doctor as read (batch).
  Future<void> markAllNotificationsRead() async {
    final snap = await _notifications
        .where('recipientId', isEqualTo: _doctorId)
        .where('isRead', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a notification permanently.
  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }

  /// Clear all notifications for this doctor.
  Future<void> clearAllNotifications() async {
    final snap = await _notifications
        .where('recipientId', isEqualTo: _doctorId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Send a custom notification to a patient (e.g. follow-up reminder).
  Future<void> sendNotificationToPatient({
    required String patientId,
    required String title,
    required String message,
    String type = 'doctor_message',
  }) async {
    await _notify(
      recipientId: patientId,
      type: type,
      title: title,
      message: message,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AVAILABILITY & SLOT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns already-booked (Pending) slot strings for this doctor on [date].
  Future<List<String>> bookedSlotsOnDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs
        .where((d) => (d.data()['status'] as String?) == 'Pending')
        .map((d) => d.data()['slot'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Fetch the doctor's availability settings.
  Future<DoctorAvailability> fetchAvailability() async {
    final doc = await _availability.doc(_doctorId).get();
    if (!doc.exists || doc.data() == null) {
      return DoctorAvailability.defaultAvailability(_doctorId);
    }
    return DoctorAvailability.fromMap(doc.data()!);
  }

  /// Live stream of the doctor's availability settings.
  Stream<DoctorAvailability> availabilityStream() {
    return _availability.doc(_doctorId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return DoctorAvailability.defaultAvailability(_doctorId);
      }
      return DoctorAvailability.fromMap(doc.data()!);
    });
  }

  /// Save or update the doctor's availability settings.
  Future<void> saveAvailability(DoctorAvailability availability) async {
    await _availability.doc(_doctorId).set(
          availability.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Block a full date (e.g., holiday, sick leave).
  Future<void> blockDate(DateTime date) async {
    final key = _dateKey(date);
    await _availability.doc(_doctorId).set(
      {
        'blockedDates': FieldValue.arrayUnion([key]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Unblock a previously blocked date.
  Future<void> unblockDate(DateTime date) async {
    final key = _dateKey(date);
    await _availability.doc(_doctorId).set(
      {
        'blockedDates': FieldValue.arrayRemove([key]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Block a specific time slot on a specific date.
  Future<void> blockSlot(DateTime date, String slot) async {
    final key = '${_dateKey(date)}|$slot';
    await _availability.doc(_doctorId).set(
      {
        'blockedSlots': FieldValue.arrayUnion([key]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Unblock a specific time slot on a specific date.
  Future<void> unblockSlot(DateTime date, String slot) async {
    final key = '${_dateKey(date)}|$slot';
    await _availability.doc(_doctorId).set(
      {
        'blockedSlots': FieldValue.arrayRemove([key]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Generate available time slots for a given date, excluding booked/blocked.
  Future<List<String>> availableSlotsForDate(DateTime date) async {
    final avail = await fetchAvailability();
    final weekdayName = _weekdayName(date.weekday);

    if (avail.workingDays[weekdayName] != true) return [];

    final dateKey = _dateKey(date);
    if (avail.blockedDates.contains(dateKey)) return [];

    final allSlots = _generateSlots(
      avail.startTime,
      avail.endTime,
      avail.slotDurationMinutes,
    );

    final blockedForDate = avail.blockedSlots
        .where((s) => s.startsWith('$dateKey|'))
        .map((s) => s.split('|').last)
        .toSet();

    final booked = (await bookedSlotsOnDate(date)).toSet();

    return allSlots
        .where((s) => !blockedForDate.contains(s) && !booked.contains(s))
        .toList();
  }

  List<String> _generateSlots(String start, String end, int durationMinutes) {
    final slots = <String>[];
    try {
      DateTime current = _parseTimeString(start);
      final endDt = _parseTimeString(end);
      while (current.isBefore(endDt)) {
        slots.add(_formatTime(current));
        current = current.add(Duration(minutes: durationMinutes));
      }
    } catch (_) {}
    return slots;
  }

  DateTime _parseTimeString(String timeStr) {
    final parts = timeStr.trim().split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${h.toString().padLeft(2, '0')}:$minute ${isPm ? 'PM' : 'AM'}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns appointment counts per status for the past [days] days.
  Future<Map<String, int>> appointmentTrendForDays(int days) async {
    final from = Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: days)));
    final snap = await _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('date', isGreaterThanOrEqualTo: from)
        .get();

    final result = <String, int>{
      'Pending': 0,
      'Completed': 0,
      'Cancelled': 0,
    };
    for (final d in snap.docs) {
      final status = d.data()['status'] as String? ?? '';
      if (result.containsKey(status)) result[status] = result[status]! + 1;
    }
    return result;
  }

  /// Returns appointment counts grouped by day for the past [days] days.
  /// Each entry: { 'date': 'yyyy-MM-dd', 'count': n }
  Future<List<Map<String, dynamic>>> appointmentsPerDay(int days) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final snap = await _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .get();

    final dayMap = <String, int>{};
    for (int i = 0; i < days; i++) {
      dayMap[_dateKey(from.add(Duration(days: i)))] = 0;
    }
    for (final doc in snap.docs) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      final key = _dateKey(date);
      if (dayMap.containsKey(key)) dayMap[key] = dayMap[key]! + 1;
    }

    return dayMap.entries
        .map((e) => {'date': e.key, 'count': e.value})
        .toList();
  }

  /// Returns appointment data points grouped by day — ready for chart widgets.
  Future<List<AppointmentDataPoint>> appointmentsPerDayPoints(int days) async {
    final raw = await appointmentsPerDay(days);
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return raw.map((e) {
      final parts = (e['date'] as String).split('-');
      final dt = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return AppointmentDataPoint(
        label: days <= 7 ? weekdays[dt.weekday - 1] : '${dt.day}/${dt.month}',
        count: e['count'] as int,
      );
    }).toList();
  }

  /// Returns weekly appointment counts for the past [weeks] weeks.
  Future<List<AppointmentDataPoint>> appointmentsPerWeek(int weeks) async {
    final now = DateTime.now();
    final result = <AppointmentDataPoint>[];

    for (int w = weeks - 1; w >= 0; w--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + w * 7));
      final weekStartNorm =
          DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEnd = weekStartNorm.add(const Duration(days: 7));

      final snap = await _appointments
          .where('doctorId', isEqualTo: _doctorId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartNorm))
          .where('date', isLessThan: Timestamp.fromDate(weekEnd))
          .get();

      result.add(AppointmentDataPoint(
        label: 'W${weeks - w}',
        count: snap.docs.length,
      ));
    }
    return result;
  }

  /// Returns patient visit frequency (patient name → visit count).
  Future<Map<String, int>> patientVisitFrequency() async {
    final snap = await _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('status', isEqualTo: 'Completed')
        .get();

    final freq = <String, int>{};
    for (final d in snap.docs) {
      final name = d.data()['patientName'] as String? ?? 'Unknown';
      freq[name] = (freq[name] ?? 0) + 1;
    }
    return freq;
  }

  /// Returns appointment completion rate as a percentage (0–100).
  Future<double> completionRate() async {
    final snap =
        await _appointments.where('doctorId', isEqualTo: _doctorId).get();
    if (snap.docs.isEmpty) return 0.0;
    final completed =
        snap.docs.where((d) => d.data()['status'] == 'Completed').length;
    return (completed / snap.docs.length) * 100;
  }

  /// Returns top [limit] most frequently seen patients.
  Future<List<MapEntry<String, int>>> topPatients(int limit) async {
    final freq = await patientVisitFrequency();
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Returns count of new patients (first-time visitors) per calendar month.
  /// Returns map: 'yyyy-MM' → count.
  Future<Map<String, int>> newPatientsPerMonth() async {
    final snap = await _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .get();

    final firstVisit = <String, DateTime>{};
    for (final d in snap.docs) {
      final pid = d.data()['patientId'] as String? ?? '';
      final date = (d.data()['date'] as Timestamp).toDate();
      if (!firstVisit.containsKey(pid)) {
        firstVisit[pid] = date;
      }
    }

    final monthMap = <String, int>{};
    for (final dt in firstVisit.values) {
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      monthMap[key] = (monthMap[key] ?? 0) + 1;
    }
    return monthMap;
  }

  /// Fetch a breakdown of appointments by status for a custom date range.
  Future<Map<String, int>> appointmentsInRange(
      DateTime from, DateTime to) async {
    final snap = await _appointments
        .where('doctorId', isEqualTo: _doctorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();

    final result = <String, int>{
      'total': snap.docs.length,
      'Pending': 0,
      'Completed': 0,
      'Cancelled': 0,
    };
    for (final d in snap.docs) {
      final status = d.data()['status'] as String? ?? '';
      if (result.containsKey(status)) result[status] = result[status]! + 1;
    }
    return result;
  }
}