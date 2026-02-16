import 'package:flutter/material.dart';

class Appointment {
  final String doctor;
  final String date;
  final String slot;
  String status; // Pending / Completed / Cancelled

  Appointment({
    required this.doctor,
    required this.date,
    required this.slot,
    this.status = "Pending",
  });
}

class AppointmentRules {
  static TimeOfDay startTime =
      const TimeOfDay(hour: 9, minute: 0);

  static TimeOfDay endTime =
      const TimeOfDay(hour: 16, minute: 0);

  static TimeOfDay breakStart =
      const TimeOfDay(hour: 13, minute: 0);

  static TimeOfDay breakEnd =
      const TimeOfDay(hour: 14, minute: 0);

  static int slotDuration = 20;
  static int maxPatientsPerDay = 25;

  // 🔐 Per-doctor booking slots
  static Map<String, Map<String, List<String>>> bookedSlots = {};

  // 📋 Store all appointment objects
  static List<Appointment> appointments = [];
}