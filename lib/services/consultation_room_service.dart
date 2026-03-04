import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── ConsultationRoom ──────────────────────────────────────────────────────────
//
// Represents one active (or recently ended) video room stored in Firestore.
// Document ID == appointmentId for easy lookup.

class ConsultationRoom {
  final String appointmentId;
  final String roomId;       // unique Jitsi room name, e.g. "oncosoul-aB3xQz"
  final String doctorId;
  final String patientId;
  final bool   isActive;     // true = call in progress
  final DateTime startedAt;
  final DateTime? endedAt;

  const ConsultationRoom({
    required this.appointmentId,
    required this.roomId,
    required this.doctorId,
    required this.patientId,
    required this.isActive,
    required this.startedAt,
    this.endedAt,
  });

  factory ConsultationRoom.fromMap(Map<String, dynamic> map) =>
      ConsultationRoom(
        appointmentId: map['appointmentId'] ?? '',
        roomId:        map['roomId'] ?? '',
        doctorId:      map['doctorId'] ?? '',
        patientId:     map['patientId'] ?? '',
        isActive:      map['isActive'] ?? false,
        startedAt:     (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endedAt:       (map['endedAt'] as Timestamp?)?.toDate(),
      );

  /// Full Jitsi Meet URL for this room (no account / API key needed).
  String get joinUrl => 'https://meet.jit.si/$roomId';
}

// ── ConsultationRoomService ───────────────────────────────────────────────────

class ConsultationRoomService {
  static final ConsultationRoomService _instance =
      ConsultationRoomService._();
  factory ConsultationRoomService() => _instance;
  ConsultationRoomService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('consultation_rooms');

  // ── Generate a short unique room name ─────────────────────────────────────

  static String _generateRoomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    final suffix =
        List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'oncosoul-$suffix';
  }

  // ── Doctor: start a room ───────────────────────────────────────────────────

  /// Creates (or reactivates) a consultation room for [appointmentId].
  /// Returns the [ConsultationRoom] with the Jitsi join URL.
  Future<ConsultationRoom> startRoom({
    required String appointmentId,
    required String doctorId,
    required String patientId,
  }) async {
    final existing = await _rooms.doc(appointmentId).get();

    // Reuse the same roomId if the room was already created (reconnect case).
    final roomId = (existing.exists && (existing.data()?['roomId'] as String?)?.isNotEmpty == true)
        ? existing.data()!['roomId'] as String
        : _generateRoomId();

    final data = {
      'appointmentId': appointmentId,
      'roomId':        roomId,
      'doctorId':      doctorId,
      'patientId':     patientId,
      'isActive':      true,
      'startedAt':     FieldValue.serverTimestamp(),
      'endedAt':       null,
    };

    await _rooms.doc(appointmentId).set(data, SetOptions(merge: false));

    return ConsultationRoom(
      appointmentId: appointmentId,
      roomId:        roomId,
      doctorId:      doctorId,
      patientId:     patientId,
      isActive:      true,
      startedAt:     DateTime.now(),
    );
  }

  // ── Doctor: end a room ─────────────────────────────────────────────────────

  Future<void> endRoom(String appointmentId) async {
    await _rooms.doc(appointmentId).update({
      'isActive': false,
      'endedAt':  FieldValue.serverTimestamp(),
    });
  }

  // ── Shared: stream room status ─────────────────────────────────────────────

  /// Real-time stream of the room for [appointmentId].
  /// Emits null when no room document exists yet.
  Stream<ConsultationRoom?> roomStream(String appointmentId) {
    return _rooms.doc(appointmentId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ConsultationRoom.fromMap(doc.data()!);
    });
  }

  /// One-shot fetch — used by patient to get the current join URL.
  Future<ConsultationRoom?> fetchRoom(String appointmentId) async {
    final doc = await _rooms.doc(appointmentId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ConsultationRoom.fromMap(doc.data()!);
  }

  /// Live stream — returns the first active room where [patientId] is the patient.
  /// Emits null when no active call exists for this patient.
  Stream<ConsultationRoom?> activeRoomForPatientStream(String patientId) {
    return _rooms
        .where('patientId', isEqualTo: patientId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return ConsultationRoom.fromMap(snap.docs.first.data());
    });
  }
}