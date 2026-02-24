import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class PatientAppointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final DateTime date;
  final String slot;
  final String status;
  final DateTime bookedAt;

  PatientAppointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.slot,
    required this.status,
    required this.bookedAt,
  });

  factory PatientAppointment.fromMap(String id, Map<String, dynamic> map) =>
      PatientAppointment(
        id: id,
        doctorId: map['doctorId'] ?? '',
        doctorName: map['doctorName'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        slot: map['slot'] ?? '',
        status: map['status'] ?? 'Pending',
        bookedAt:
            (map['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class PatientReport {
  final String id;
  final String reportType;
  final String labName;
  final String notes;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String? fileUrl;

  PatientReport({
    required this.id,
    required this.reportType,
    required this.labName,
    required this.notes,
    required this.uploadedBy,
    required this.uploadedAt,
    this.fileUrl,
  });

  factory PatientReport.fromMap(String id, Map<String, dynamic> map) =>
      PatientReport(
        id: id,
        reportType: map['reportType'] ?? '',
        labName: map['labName'] ?? '',
        notes: map['notes'] ?? '',
        uploadedBy: map['uploadedBy'] ?? '',
        uploadedAt:
            (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        fileUrl: map['fileUrl'],
      );
}

class PatientPrescription {
  final String id;
  final String doctorName;
  final String? diagnosis;
  final List<Map<String, String>> medicines;
  final DateTime createdAt;

  PatientPrescription({
    required this.id,
    required this.doctorName,
    required this.medicines,
    required this.createdAt,
    this.diagnosis,
  });

  factory PatientPrescription.fromMap(String id, Map<String, dynamic> map) {
    final rawMeds = map['medicines'] as List<dynamic>? ?? [];
    final meds = rawMeds.map((m) {
      final entry = m as Map<String, dynamic>;
      return entry.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }).toList();
    return PatientPrescription(
      id: id,
      doctorName: map['doctorName'] ?? '',
      medicines: meds,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      diagnosis: map['diagnosis'],
    );
  }
}

class ForumPost {
  final String id;
  final String authorId;
  final String authorName;
  final String message;
  final DateTime createdAt;
  int likes;
  final List<String> likedBy;

  ForumPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
  });

  factory ForumPost.fromMap(String id, Map<String, dynamic> map) => ForumPost(
        id: id,
        authorId: map['authorId'] ?? '',
        authorName: map['authorName'] ?? 'Anonymous',
        message: map['message'] ?? '',
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        likes: map['likes'] ?? 0,
        likedBy: List<String>.from(map['likedBy'] ?? []),
      );
}

class DoctorInfo {
  final String id;
  final String name;
  final String specialty;

  const DoctorInfo({
    required this.id,
    required this.name,
    required this.specialty,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class PatientService {
  static final PatientService _instance = PatientService._();
  factory PatientService() => _instance;
  PatientService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _patientId => AppUserSession.currentUser?.userId ?? '';
  String get _patientName => AppUserSession.currentUser?.name ?? '';

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('medical_reports');
  CollectionReference<Map<String, dynamic>> get _prescriptions =>
      _db.collection('prescriptions');
  CollectionReference<Map<String, dynamic>> get _forum =>
      _db.collection('forum_posts');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── APPOINTMENTS ──────────────────────────────────────────────────────────

  Stream<List<PatientAppointment>> myAppointmentsStream() {
    return _appointments
        .where('patientId', isEqualTo: _patientId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => PatientAppointment.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Future<List<String>> bookedSlotsForDoctorOnDate(
      String doctorId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _appointments
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs
        .where((d) => (d.data()['status'] as String?) != 'Cancelled')
        .map((d) => d.data()['slot'] as String? ?? '')
        .toList();
  }

  Future<void> bookAppointment({
    required String doctorId,
    required String doctorName,
    required DateTime date,
    required String slot,
  }) async {
    // Check slot availability
    final booked = await bookedSlotsForDoctorOnDate(doctorId, date);
    if (booked.contains(slot)) {
      throw Exception('This slot is already booked. Please choose another.');
    }

    final apptRef = await _appointments.add({
      'patientId': _patientId,
      'patientName': _patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'date': Timestamp.fromDate(date),
      'slot': slot,
      'status': 'Pending',
      'bookedAt': FieldValue.serverTimestamp(),
    });

    // Notify doctor
    await _db.collection('notifications').add({
      'recipientId': doctorId,
      'type': 'new_appointment',
      'title': 'New Appointment Booked',
      'message':
          '$_patientName has booked an appointment on ${date.day}/${date.month}/${date.year} at $slot.',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notify patient
    await _db.collection('notifications').add({
      'recipientId': _patientId,
      'type': 'confirmation',
      'title': 'Appointment Confirmed',
      'message':
          'Your appointment with Dr. $doctorName on ${date.day}/${date.month}/${date.year} at $slot is confirmed.',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _appointments.doc(appointmentId).update({'status': 'Cancelled'});
  }

  // ── DOCTORS ───────────────────────────────────────────────────────────────

  Future<List<DoctorInfo>> fetchDoctors() async {
    final snap = await _users
        .where('role', isEqualTo: 'Doctor')
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return DoctorInfo(
        id: d.id,
        name: data['name'] ?? 'Unknown',
        specialty: data['specialty'] ?? 'Oncologist',
      );
    }).toList();
  }

  // ── REPORTS ───────────────────────────────────────────────────────────────

  Stream<List<PatientReport>> myReportsStream() {
    return _reports
        .where('patientId', isEqualTo: _patientId.toUpperCase())
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => PatientReport.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return list;
        });
  }

  // ── PRESCRIPTIONS ─────────────────────────────────────────────────────────

  Stream<List<PatientPrescription>> myPrescriptionsStream() {
    return _prescriptions
        .where('patientId', isEqualTo: _patientId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => PatientPrescription.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── COMMUNITY FORUM ───────────────────────────────────────────────────────

  Stream<List<ForumPost>> forumPostsStream() {
    return _forum
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ForumPost.fromMap(d.id, d.data())).toList());
  }

  Future<void> createPost(String message) async {
    await _forum.add({
      'authorId': _patientId,
      'authorName': _patientName,
      'message': message.trim(),
      'likes': 0,
      'likedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    await _forum.doc(postId).delete();
  }

  Future<void> toggleLike(ForumPost post) async {
    final hasLiked = post.likedBy.contains(_patientId);
    await _forum.doc(post.id).update({
      'likes': hasLiked ? FieldValue.increment(-1) : FieldValue.increment(1),
      'likedBy': hasLiked
          ? FieldValue.arrayRemove([_patientId])
          : FieldValue.arrayUnion([_patientId]),
    });
  }

  // ── PROFILE ───────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>?> myProfileStream() {
    return _users.doc(_patientId).snapshots().map((d) => d.data());
  }

  Future<void> updateProfile({String? phone, String? address}) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (phone != null) updates['phone'] = phone.trim();
    if (address != null) updates['address'] = address.trim();
    await _users.doc(_patientId).update(updates);
  }

  String get patientId => _patientId;
}