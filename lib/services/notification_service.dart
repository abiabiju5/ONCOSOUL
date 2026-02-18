import 'package:flutter/foundation.dart';

enum NotificationType { confirmation, cancellation, reminder, newAppointment }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });
}

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final List<AppNotification> _patientNotifications = [];
  final List<AppNotification> _doctorNotifications = [];

  List<AppNotification> get patientNotifications =>
      List.unmodifiable(_patientNotifications);
  List<AppNotification> get doctorNotifications =>
      List.unmodifiable(_doctorNotifications);

  int get patientUnreadCount =>
      _patientNotifications.where((n) => !n.isRead).length;
  int get doctorUnreadCount =>
      _doctorNotifications.where((n) => !n.isRead).length;

  void addAppointmentConfirmation({
    required String doctor,
    required String date,
    required String slot,
  }) {
    _patientNotifications.insert(
      0,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Appointment Confirmed',
        message: 'Your appointment with $doctor on $date at $slot has been confirmed.',
        type: NotificationType.confirmation,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addAppointmentCancellationForPatient({
    required String doctor,
    required String date,
    required String slot,
  }) {
    _patientNotifications.insert(
      0,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Appointment Cancelled',
        message: 'Your appointment with $doctor on $date at $slot has been cancelled by the doctor.',
        type: NotificationType.cancellation,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addAppointmentReminder({
    required String doctor,
    required String slot,
  }) {
    _patientNotifications.insert(
      0,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Appointment Reminder',
        message: 'Reminder: You have an appointment with $doctor today at $slot.',
        type: NotificationType.reminder,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addNewAppointmentForDoctor({
    required String patientName,
    required String date,
    required String slot,
  }) {
    _doctorNotifications.insert(
      0,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Appointment',
        message: '$patientName has booked an appointment on $date at $slot.',
        type: NotificationType.newAppointment,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAllPatientRead() {
    for (final n in _patientNotifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markAllDoctorRead() {
    for (final n in _doctorNotifications) {
      n.isRead = true;
    }
    notifyListeners();
  }
}
