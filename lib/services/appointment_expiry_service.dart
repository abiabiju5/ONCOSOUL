import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentExpiryService {
  AppointmentExpiryService._();
  static final AppointmentExpiryService instance = AppointmentExpiryService._();

  static const Duration _checkInterval = Duration(minutes: 5);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _timer;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    debugPrint('[ExpiryService] Started');
    _runCheck();
    _timer = Timer.periodic(_checkInterval, (_) => _runCheck());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  void runCheckNow() {
    debugPrint('[ExpiryService] Manual check triggered');
    _runCheck();
  }

  Future<void> _runCheck() async {
    debugPrint('[ExpiryService] Running check at ${DateTime.now()}');
    try {
      final int slotDurationMinutes = await _fetchSlotDuration();
      debugPrint('[ExpiryService] Slot duration: $slotDurationMinutes min');

      final now = DateTime.now();
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snap = await _db
          .collection('appointments')
          .where('status', isEqualTo: 'Pending')
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
          .get();

      debugPrint('[ExpiryService] Pending appointments found: ${snap.docs.length}');

      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      final List<Map<String, dynamic>> toNotify = [];
      int changeCount = 0;

      for (final doc in snap.docs) {
        final data    = doc.data();
        final rawDate = data['date'] as Timestamp?;
        final slot    = (data['slot'] ?? '') as String;
        final patient = data['patientName'] ?? doc.id;

        debugPrint('[ExpiryService] Checking: $patient | slot: "$slot" | date: $rawDate');

        if (rawDate == null || slot.isEmpty) {
          debugPrint('[ExpiryService]   SKIP — null date or empty slot');
          continue;
        }

        final apptDate = rawDate.toDate();
        final slotEnd  = _slotEndTime(apptDate, slot, slotDurationMinutes);

        debugPrint('[ExpiryService]   slotEnd: $slotEnd | now: $now');

        if (slotEnd == null) {
          debugPrint('[ExpiryService]   SKIP — could not parse slot');
          continue;
        }

        if (!slotEnd.isBefore(now)) {
          debugPrint('[ExpiryService]   SKIP — slot not ended yet');
          continue;
        }

        debugPrint('[ExpiryService]   CANCELLING $patient');

        batch.update(doc.reference, {
          'status':       'Cancelled',
          'cancelledAt':  FieldValue.serverTimestamp(),
          'cancelledBy':  'System',
          'cancelReason': 'Appointment time passed without completion',
        });

        changeCount++;

        final patientId = (data['patientId'] ?? '') as String;
        if (patientId.isNotEmpty) {
          toNotify.add({
            'patientId':  patientId,
            'doctorName': (data['doctorName'] ?? 'your doctor') as String,
            'slot':       slot,
            'date':       apptDate,
          });
        }
      }

      debugPrint('[ExpiryService] Total to cancel: $changeCount');
      if (changeCount == 0) return;

      await batch.commit();
      debugPrint('[ExpiryService] Done — $changeCount cancelled');

      for (final n in toNotify) {
        await _notify(n);
      }
    } catch (e, stack) {
      debugPrint('[ExpiryService] ERROR: $e');
      debugPrint('[ExpiryService] STACK: $stack');
    }
  }

  DateTime? _slotEndTime(DateTime apptDate, String slot, int durationMinutes) {
    try {
      final trimmed = slot.trim();
      int hour, minute;

      if (trimmed.toUpperCase().contains('AM') ||
          trimmed.toUpperCase().contains('PM')) {
        final normalised = trimmed.replaceAll(RegExp(r'\s+'), ' ');
        final parts = normalised.split(' ');
        final hm    = parts[0].split(':');
        hour   = int.parse(hm[0]);
        minute = int.parse(hm[1]);
        final isPm = parts.last.toUpperCase() == 'PM';
        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
      } else {
        final hm = trimmed.split(':');
        hour   = int.parse(hm[0]);
        minute = int.parse(hm[1]);
      }

      final slotStart = DateTime(
          apptDate.year, apptDate.month, apptDate.day, hour, minute);
      return slotStart.add(Duration(minutes: durationMinutes));
    } catch (e) {
      debugPrint('[ExpiryService] _slotEndTime parse error for "$slot": $e');
      return null;
    }
  }

  Future<int> _fetchSlotDuration() async {
    try {
      final doc = await _db
          .collection('settings')
          .doc('appointment_rules')
          .get();
      if (doc.exists) {
        return (doc.data()?['slotDurationMinutes'] as int?) ?? 30;
      }
    } catch (e) {
      debugPrint('[ExpiryService] _fetchSlotDuration error: $e');
    }
    return 30;
  }

  Future<void> _notify(Map<String, dynamic> n) async {
    try {
      final date = n['date'] as DateTime;
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';
      await _db.collection('notifications').add({
        'recipientId': n['patientId'],
        'type':        'auto_cancelled',
        'title':       'Appointment Cancelled',
        'message':
            'Your appointment with ${n['doctorName']} on $dateStr '
            'at ${n['slot']} was automatically cancelled because '
            'the appointment time has passed.',
        'isRead':    false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[ExpiryService] _notify error: $e');
    }
  }
}