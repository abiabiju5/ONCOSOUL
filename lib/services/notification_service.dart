import 'package:flutter/foundation.dart';

// ── AppNotification ───────────────────────────────────────────────────────────

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
}

// ── NotificationService ───────────────────────────────────────────────────────
//
// Extends ChangeNotifier → supports addListener / removeListener / ListenableBuilder.
//
// Two buckets:
//   • _doctorNotifications  — doctor dashboard
//   • _patientNotifications — patient side
//
// Factories cover every call site found in the codebase:
//   Doctor-side : addDoctorNotification, addNewAppointmentForDoctor
//   Patient-side: addAppointmentCancellationForPatient,
//                 addAppointmentConfirmation, addAppointmentReminder,
//                 addPatientNotification

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // ── Storage ───────────────────────────────────────────────────────────────────

  final List<AppNotification> _doctorNotifications = [];
  final List<AppNotification> _patientNotifications = [];

  // ── Public getters ────────────────────────────────────────────────────────────

  List<AppNotification> get doctorNotifications =>
      List.unmodifiable(_doctorNotifications.reversed.toList());

  List<AppNotification> get patientNotifications =>
      List.unmodifiable(_patientNotifications.reversed.toList());

  int get doctorUnreadCount =>
      _doctorNotifications.where((n) => !n.isRead).length;

  int get patientUnreadCount =>
      _patientNotifications.where((n) => !n.isRead).length;

  // ── Internal helpers ──────────────────────────────────────────────────────────

  String _newId() => DateTime.now().millisecondsSinceEpoch.toString();

  void _addDoctor(AppNotification n) {
    _doctorNotifications.add(n);
    notifyListeners();
  }

  void _addPatient(AppNotification n) {
    _patientNotifications.add(n);
    notifyListeners();
  }

  // ── Doctor-side factories ─────────────────────────────────────────────────────

  /// Generic doctor notification.
  void addDoctorNotification({
    required String type,
    required String title,
    required String message,
  }) {
    _addDoctor(AppNotification(
      id: _newId(),
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
    ));
  }

  /// Called when a patient books a new appointment — shows on doctor dashboard.
  void addNewAppointmentForDoctor({
    required String patientName,
    required String date,
    required String slot,
  }) {
    _addDoctor(AppNotification(
      id: _newId(),
      type: 'new_appointment',
      title: 'New Appointment Booked',
      message: '$patientName has booked an appointment on $date at $slot.',
      createdAt: DateTime.now(),
    ));
  }

  // ── Patient-side factories ────────────────────────────────────────────────────

  /// Called when the doctor cancels an appointment.
  void addAppointmentCancellationForPatient({
    required String doctor,
    required String date,
    required String slot,
  }) {
    _addPatient(AppNotification(
      id: _newId(),
      type: 'cancellation',
      title: 'Appointment Cancelled',
      message:
          'Your appointment with $doctor on $date at $slot has been cancelled.',
      createdAt: DateTime.now(),
    ));
  }

  /// Called right after a patient successfully books an appointment.
  void addAppointmentConfirmation({
    required String doctor,
    required String date,
    required String slot,
  }) {
    _addPatient(AppNotification(
      id: _newId(),
      type: 'confirmation',
      title: 'Appointment Confirmed',
      message:
          'Your appointment with $doctor on $date at $slot has been confirmed.',
      createdAt: DateTime.now(),
    ));
  }

  /// Called to remind the patient about an upcoming appointment.
  void addAppointmentReminder({
    required String doctor,
    required String date,
    required String slot,
  }) {
    _addPatient(AppNotification(
      id: _newId(),
      type: 'reminder',
      title: 'Appointment Reminder',
      message:
          'Reminder: You have an appointment with $doctor on $date at $slot.',
      createdAt: DateTime.now(),
    ));
  }

  /// Generic patient notification.
  void addPatientNotification({
    required String type,
    required String title,
    required String message,
  }) {
    _addPatient(AppNotification(
      id: _newId(),
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
    ));
  }

  // ── Read / clear ──────────────────────────────────────────────────────────────

  void markAllDoctorRead() {
    for (final n in _doctorNotifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markAllPatientRead() {
    for (final n in _patientNotifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markDoctorRead(String id) {
    final idx = _doctorNotifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _doctorNotifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markPatientRead(String id) {
    final idx = _patientNotifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _patientNotifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void clearAll() {
    _doctorNotifications.clear();
    _patientNotifications.clear();
    notifyListeners();
  }
}