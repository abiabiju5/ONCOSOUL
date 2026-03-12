import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'upload_consultation_summary_screen.dart';
import '../services/patient_service.dart';

class MedicalStaffViewAppointmentsScreen extends StatefulWidget {
  const MedicalStaffViewAppointmentsScreen({super.key});

  @override
  State<MedicalStaffViewAppointmentsScreen> createState() =>
      _MedicalStaffViewAppointmentsScreenState();
}

class _MedicalStaffViewAppointmentsScreenState
    extends State<MedicalStaffViewAppointmentsScreen> {
  static const Color _deepBlue = Color(0xFF0D47A1);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  String _selectedStatus = 'All';
  final _statuses = ['All', 'Pending', 'Completed', 'Cancelled'];

  Stream<QuerySnapshot> get _stream {
    return FirebaseFirestore.instance
        .collection('appointments')
        .orderBy('date', descending: false)
        .snapshots();
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '—';
    final dt = (ts as Timestamp).toDate();
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Completed': return Icons.check_circle_rounded;
      case 'Cancelled': return Icons.cancel_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  // ── Cancel appointment ────────────────────────────────────────────────────
  Future<void> _cancelAppointment(String docId, String patientId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: const Icon(Icons.cancel_rounded, size: 28, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text('Cancel Appointment?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0D1B3E))),
            const SizedBox(height: 8),
            const Text(
              'This will cancel the appointment and notify the patient.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _deepBlue,
                    side: const BorderSide(color: _deepBlue),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Keep', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Cancel It', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
        'status': 'Cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'Medical Staff',
      });

      if (patientId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'recipientId': patientId,
          'type': 'cancelled',
          'title': 'Appointment Cancelled',
          'message': 'Your appointment has been cancelled by our medical staff. Please rebook at your convenience.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) _snack('Appointment cancelled and patient notified.', isError: false);
    } catch (e) {
      if (mounted) _snack('Failed to cancel: $e', isError: true);
    }
  }

  // ── Reschedule appointment ────────────────────────────────────────────────
  Future<void> _rescheduleAppointment(
      String docId, String patientId, DateTime currentDate, String currentSlot,
      String doctorId, String doctorName) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => _RescheduleDialog(
        appointmentId: docId,
        doctorId: doctorId,
        doctorName: doctorName,
        initialDate: currentDate,
        initialSlot: currentSlot,
        onConfirm: (newDate, newSlot) async {
          Navigator.of(ctx).pop();
          try {
            await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
              'date': Timestamp.fromDate(newDate),
              'slot': newSlot,
              'status': 'Pending',
              'rescheduledAt': FieldValue.serverTimestamp(),
              'rescheduledBy': 'Medical Staff',
            });
            if (patientId.isNotEmpty) {
              const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
              final dateStr = '${newDate.day} ${months[newDate.month - 1]} ${newDate.year}';
              await FirebaseFirestore.instance.collection('notifications').add({
                'recipientId': patientId,
                'type': 'rescheduled',
                'title': 'Appointment Rescheduled',
                'message': 'Your appointment has been rescheduled to $dateStr at $newSlot.',
                'isRead': false,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
            if (mounted) _snack('Appointment rescheduled successfully.', isError: false);
          } catch (e) {
            if (mounted) _snack('Failed to reschedule: $e', isError: true);
          }
        },
      ),
    );
  }

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_rounded : Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: isError ? Colors.red.shade600 : _deepBlue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('All Appointments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((s) {
                  final sel = _selectedStatus == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedStatus = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? Colors.white : Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? _deepBlue : Colors.white)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _deepBlue));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          var docs = snap.data?.docs ?? [];
          if (_selectedStatus != 'All') {
            docs = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return (data['status'] ?? 'Pending') == _selectedStatus;
            }).toList();
          }

          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.event_busy_outlined, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No $_selectedStatus appointments',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
              ]),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final status = data['status'] ?? 'Pending';
              final patientName = data['patientName'] ?? '—';
              final patientId = data['patientId'] ?? '';
              final doctorName = data['doctorName'] ?? '—';
              final doctorId   = data['doctorId']   ?? '';
              final slot = data['slot'] ?? '—';
              final rawDate = data['date'];
              final date = _formatDate(rawDate);
              final dateTime = rawDate != null ? (rawDate as Timestamp).toDate() : DateTime.now();
              final statusColor = _statusColor(status);
              final isPending = status == 'Pending';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _lightBlue,
                        child: Text(
                          patientName.isNotEmpty ? patientName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: _deepBlue, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(patientName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D1B3E)))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_statusIcon(status), size: 11, color: statusColor),
                          const SizedBox(width: 4),
                          Text(status,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                        ]),
                      ),
                    ]),
                  ),
                  // Info rows
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Column(children: [
                      _infoRow(Icons.badge_outlined, 'Patient ID', patientId.isNotEmpty ? patientId : '—'),
                      _infoRow(Icons.person_pin_rounded, 'Doctor', doctorName),
                      _infoRow(Icons.calendar_today_rounded, 'Date', date),
                      _infoRow(Icons.access_time_rounded, 'Time', slot),
                    ]),
                  ),
                  // Action buttons
                  if (isPending) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 20, color: Color(0xFFEEEEEE)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file_rounded, size: 15),
                            label: const Text('Upload Summary',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _deepBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => UploadConsultationSummaryScreen(
                                prefilledPatientId: patientId,
                                prefilledPatientName: patientName,
                              ),
                            )),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                              label: const Text('Reschedule',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _deepBlue,
                                side: const BorderSide(color: _deepBlue, width: 1.3),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                              ),
                              onPressed: () => _rescheduleAppointment(docId, patientId, dateTime, slot, doctorId, doctorName),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined, size: 15),
                              label: const Text('Cancel',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade600,
                                side: BorderSide(color: Colors.red.shade400, width: 1.3),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                              ),
                              onPressed: () => _cancelAppointment(docId, patientId),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ] else
                    const SizedBox(height: 16),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

// ── Reschedule Dialog ─────────────────────────────────────────────────────────
class _RescheduleDialog extends StatefulWidget {
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final DateTime initialDate;
  final String initialSlot;
  final void Function(DateTime date, String slot) onConfirm;

  const _RescheduleDialog({
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.initialDate,
    required this.initialSlot,
    required this.onConfirm,
  });

  @override
  State<_RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<_RescheduleDialog> {
  static const Color _deepBlue = Color(0xFF0D47A1);

  late DateTime _selectedDate;
  String? _selectedSlot;

  List<String> _allSlots    = [];
  Set<String>  _bookedSlots = {};
  Map<String, dynamic> _rules = {};

  bool _loadingInit  = true;
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedSlot = widget.initialSlot;
    _init();
  }

  Future<void> _init() async {
    // Fetch admin appointment rules
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('appointment_rules')
          .get();
      if (doc.exists) _rules = doc.data()!;
    } catch (_) {}

    if (_rules.isEmpty) {
      _rules = {
        'startTime': '09:00',
        'endTime': '17:00',
        'slotDurationMinutes': 30,
        'hasBreak': false,
        'breakStart': '13:00',
        'breakEnd': '14:00',
      };
    }

    if (!mounted) return;
    setState(() => _loadingInit = false);
    await _refreshSlots(_selectedDate);
  }

  List<String> _generateSlots(DateTime date) {
    DateTime parseT(String t) {
      t = t.trim();
      final upper = t.toUpperCase();
      if (upper.contains('AM') || upper.contains('PM')) {
        final parts = t.split(' ');
        final hm = parts[0].split(':');
        int h = int.parse(hm[0]);
        final min = int.parse(hm[1]);
        final isPm = parts[1].toUpperCase() == 'PM';
        if (isPm && h != 12) h += 12;
        if (!isPm && h == 12) h = 0;
        return DateTime(date.year, date.month, date.day, h, min);
      } else {
        final hm = t.split(':');
        return DateTime(date.year, date.month, date.day,
            int.parse(hm[0]), int.parse(hm[1]));
      }
    }

    final start    = parseT(_rules['startTime']    ?? '09:00');
    final end      = parseT(_rules['endTime']      ?? '17:00');
    final duration = _rules['slotDurationMinutes'] as int? ?? 30;
    final hasBreak = _rules['hasBreak']            as bool? ?? false;
    final bStart   = hasBreak ? parseT(_rules['breakStart'] ?? '13:00') : null;
    final bEnd     = hasBreak ? parseT(_rules['breakEnd']   ?? '14:00') : null;

    final slots = <String>[];
    DateTime cur = start;
    while (cur.isBefore(end)) {
      final inBreak = bStart != null && bEnd != null &&
          !cur.isBefore(bStart) && cur.isBefore(bEnd);
      if (!inBreak) {
        final tod = TimeOfDay.fromDateTime(cur);
        final h   = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
        final min = tod.minute.toString().padLeft(2, '0');
        final per = tod.period == DayPeriod.am ? 'AM' : 'PM';
        slots.add('$h:$min $per');
      }
      cur = cur.add(Duration(minutes: duration));
    }
    return slots;
  }

  Future<void> _refreshSlots(DateTime date) async {
    if (!mounted) return;
    setState(() { _loadingSlots = true; _selectedSlot = null; });

    final start = DateTime(date.year, date.month, date.day);
    final end   = start.add(const Duration(days: 1));

    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    final booked = snap.docs
        .where((d) {
          final s = (d.data()['status'] ?? '') as String;
          return d.id != widget.appointmentId &&
              s != 'Cancelled' && s != 'Rescheduled';
        })
        .map((d) => (d.data()['slot'] ?? '') as String)
        .where((s) => s.isNotEmpty)
        .toSet();

    final all = _generateSlots(date);
    if (!mounted) return;
    setState(() {
      _allSlots    = all;
      _bookedSlots = booked;
      _loadingSlots = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? _selectedDate : now,
      firstDate: now,
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _deepBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _refreshSlots(picked);
    }
  }

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: _loadingInit
          ? const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(color: _deepBlue)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──────────────────────────────────────────
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                        child: const Icon(Icons.edit_calendar_rounded,
                            size: 20, color: _deepBlue),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Reschedule Appointment',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D1B3E))),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Text('Dr. ${widget.doctorName}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ),
                    const SizedBox(height: 20),

                    // ── Date picker ────────────────────────────────────
                    const Text('New Date',
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600, color: Colors.black54)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _deepBlue.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 16, color: _deepBlue),
                          const SizedBox(width: 10),
                          Text(_formatDate(_selectedDate),
                              style: const TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _deepBlue)),
                          const Spacer(),
                          Icon(Icons.edit_rounded,
                              size: 14,
                              color: _deepBlue.withValues(alpha: 0.5)),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Slot grid ──────────────────────────────────────
                    const Text('New Time Slot',
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600, color: Colors.black54)),
                    const SizedBox(height: 8),
                    if (_loadingSlots)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(color: _deepBlue),
                        ),
                      )
                    else if (_allSlots.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.event_busy_outlined,
                              color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 8),
                          Text('No slots configured for this date',
                              style: TextStyle(fontSize: 12,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allSlots.map((slot) {
                              final isSelected = _selectedSlot == slot;
                              final isBooked   = _bookedSlots.contains(slot);
                              return GestureDetector(
                                onTap: isBooked
                                    ? null
                                    : () => setState(() => _selectedSlot = slot),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 130),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isBooked
                                        ? Colors.grey.shade100
                                        : isSelected
                                            ? _deepBlue
                                            : const Color(0xFFF0F4FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isBooked
                                          ? Colors.grey.shade300
                                          : isSelected
                                              ? _deepBlue
                                              : _deepBlue.withValues(alpha: 0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min,
                                      children: [
                                    if (isBooked) ...[
                                      Icon(Icons.block_rounded,
                                          size: 11,
                                          color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                    ] else if (isSelected) ...[
                                      const Icon(Icons.check_circle_rounded,
                                          size: 11, color: Colors.white),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(slot,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isBooked
                                                ? Colors.grey.shade400
                                                : isSelected
                                                    ? Colors.white
                                                    : _deepBlue)),
                                  ]),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          // Legend
                          Row(children: [
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FF),
                                border: Border.all(
                                    color: _deepBlue.withValues(alpha: 0.15),
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('Available',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade600)),
                            const SizedBox(width: 12),
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 1.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('Booked',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade600)),
                          ]),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // ── Actions ────────────────────────────────────────
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _deepBlue,
                            side: const BorderSide(color: _deepBlue),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _deepBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: _selectedSlot == null
                              ? null
                              : () => widget.onConfirm(
                                  _selectedDate, _selectedSlot!),
                          child: const Text('Confirm',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
    );
  }
}