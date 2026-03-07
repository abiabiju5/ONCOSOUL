import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_session.dart';

// ── AppNotification ───────────────────────────────────────────────────────────
//
// Mirrors the Firestore document shape written by DoctorService / PatientService.

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) =>
      AppNotification(
        id: id,
        type: map['type'] ?? '',
        title: map['title'] ?? '',
        message: map['message'] ?? '',
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRead: map['isRead'] ?? false,
      );
}

// ── NotificationService ───────────────────────────────────────────────────────
//
// Firestore-backed replacement for the old in-memory ChangeNotifier.
//
// Public API is identical to the previous version so NO call-sites need changes:
//   - doctorNotifications / patientNotifications   — live lists
//   - doctorUnreadCount  / patientUnreadCount      — badge counts
//   - markAllDoctorRead  / markAllPatientRead
//   - markDoctorRead(id) / markPatientRead(id)
//   - clearAll()
//   - addDoctorNotification(...)
//   - addNewAppointmentForDoctor(...)
//   - addAppointmentCancellationForPatient(...)
//   - addAppointmentConfirmation(...)
//   - addAppointmentReminder(...)
//   - addPatientNotification(...)
//
// Call init() once after login, reset() on logout.
// Notifications written by DoctorService / PatientService into Firestore are
// automatically picked up by the live stream — no duplication.

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── In-memory cache (populated by Firestore stream) ───────────────────────

  List<AppNotification> _doctorNotifications = [];
  List<AppNotification> _patientNotifications = [];

  StreamSubscription<QuerySnapshot>? _doctorSub;
  StreamSubscription<QuerySnapshot>? _patientSub;

  // ── Initialise / teardown ─────────────────────────────────────────────────

  /// Call once after login to start streaming the logged-in user's notifications.
  void init() {
    _cancelSubscriptions();

    final uid = AppUserSession.userId;
    if (uid.isEmpty) return;

    final role = AppUserSession.userRole;
    final isDoctor = role == 'Doctor' ||
        role == 'Admin' ||
        role == 'Super Admin' ||
        role == 'Medical Staff';

    final stream = _db
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    if (isDoctor) {
      _doctorSub = stream.listen((snap) {
        _doctorNotifications = snap.docs
            .map((d) => AppNotification.fromMap(
                d.id, d.data()))
            .toList();
        notifyListeners();
      }, onError: (_) {});
    } else {
      _patientSub = stream.listen((snap) {
        _patientNotifications = snap.docs
            .map((d) => AppNotification.fromMap(
                d.id, d.data()))
            .toList();
        notifyListeners();
      }, onError: (_) {});
    }
  }

  /// Call on logout to cancel subscriptions and wipe the local cache.
  void reset() {
    _cancelSubscriptions();
    _doctorNotifications = [];
    _patientNotifications = [];
    notifyListeners();
  }

  void _cancelSubscriptions() {
    _doctorSub?.cancel();
    _patientSub?.cancel();
    _doctorSub = null;
    _patientSub = null;
  }

  // ── Public getters ────────────────────────────────────────────────────────

  List<AppNotification> get doctorNotifications =>
      List.unmodifiable(_doctorNotifications);

  List<AppNotification> get patientNotifications =>
      List.unmodifiable(_patientNotifications);

  int get doctorUnreadCount =>
      _doctorNotifications.where((n) => !n.isRead).length;

  int get patientUnreadCount =>
      _patientNotifications.where((n) => !n.isRead).length;

  // ── Internal write helper ─────────────────────────────────────────────────

  Future<void> _write({
    required String recipientId,
    required String type,
    required String title,
    required String message,
  }) async {
    try {
      await _db.collection('notifications').add({
        'recipientId': recipientId,
        'type': type,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-fatal — a notification failure must not crash the app.
    }
  }

  String get _uid => AppUserSession.userId;

  // ── Doctor-side factories (identical signatures to the old version) ────────

  void addDoctorNotification({
    required String type,
    required String title,
    required String message,
  }) =>
      _write(recipientId: _uid, type: type, title: title, message: message);

  void addNewAppointmentForDoctor({
    required String patientName,
    required String date,
    required String slot,
  }) =>
      _write(
        recipientId: _uid,
        type: 'new_appointment',
        title: 'New Appointment Booked',
        message:
            '$patientName has booked an appointment on $date at $slot.',
      );

  // ── Patient-side factories (identical signatures to the old version) ───────

  void addAppointmentCancellationForPatient({
    required String doctor,
    required String date,
    required String slot,
  }) =>
      _write(
        recipientId: _uid,
        type: 'cancellation',
        title: 'Appointment Cancelled',
        message:
            'Your appointment with $doctor on $date at $slot has been cancelled.',
      );

  void addAppointmentConfirmation({
    required String doctor,
    required String date,
    required String slot,
  }) =>
      _write(
        recipientId: _uid,
        type: 'confirmation',
        title: 'Appointment Confirmed',
        message:
            'Your appointment with $doctor on $date at $slot has been confirmed.',
      );

  void addAppointmentReminder({
    required String doctor,
    required String date,
    required String slot,
  }) =>
      _write(
        recipientId: _uid,
        type: 'reminder',
        title: 'Appointment Reminder',
        message:
            'Reminder: You have an appointment with $doctor on $date at $slot.',
      );

  void addPatientNotification({
    required String type,
    required String title,
    required String message,
  }) =>
      _write(recipientId: _uid, type: type, title: title, message: message);

  // ── Mark read ─────────────────────────────────────────────────────────────

  Future<void> markAllDoctorRead() => _markAllRead(_doctorNotifications);

  Future<void> markAllPatientRead() => _markAllRead(_patientNotifications);

  Future<void> _markAllRead(List<AppNotification> list) async {
    final unread = list.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    final batch = _db.batch();
    for (final n in unread) {
      batch.update(
          _db.collection('notifications').doc(n.id), {'isRead': true});
    }
    try {
      await batch.commit();
      // Stream will refresh the cache automatically.
    } catch (_) {}
  }

  Future<void> markDoctorRead(String id) => _markOneRead(id);
  Future<void> markPatientRead(String id) => _markOneRead(id);

  Future<void> _markOneRead(String id) async {
    try {
      await _db
          .collection('notifications')
          .doc(id)
          .update({'isRead': true});
    } catch (_) {}
  }

  // ── Clear all ─────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final uid = _uid;
    if (uid.isEmpty) return;
    try {
      final snap = await _db
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }
}