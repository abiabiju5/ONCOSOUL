import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/patient_service.dart';
import 'upload_consultation_summary_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class MedicalStaffAppointmentsScreen extends StatefulWidget {
  const MedicalStaffAppointmentsScreen({super.key});
  @override
  State<MedicalStaffAppointmentsScreen> createState() =>
      _MedicalStaffAppointmentsScreenState();
}

class _MedicalStaffAppointmentsScreenState
    extends State<MedicalStaffAppointmentsScreen> {
  static const Color _deepBlue = Color(0xFF0D47A1);
  String _selectedStatus = 'All';
  final _statuses = ['All', 'Pending', 'Completed', 'Cancelled'];

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('appointments')
      .orderBy('date', descending: false)
      .snapshots();

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
      default:          return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Appointments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _statuses.map((s) {
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
                      child: Text(s, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: sel ? _deepBlue : Colors.white)),
                    ),
                  ),
                );
              }).toList()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final allDocs = snap.data?.docs ?? [];
          final docs = _selectedStatus == 'All'
              ? allDocs
              : allDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['status'] ?? 'Pending') == _selectedStatus;
                }).toList();

          if (docs.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.event_busy_outlined, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No $_selectedStatus appointments',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            ]));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data        = docs[i].data() as Map<String, dynamic>;
              final status      = data['status']      ?? 'Pending';
              final patientName = data['patientName'] ?? '—';
              final patientId   = data['patientId']   ?? '—';
              final doctorName  = data['doctorName']  ?? '—';
              final slot        = data['slot']        ?? '—';
              final date        = _formatDate(data['date']);
              final statusColor = _statusColor(status);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _deepBlue.withValues(alpha: 0.12)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.person_outline_rounded, size: 18, color: _deepBlue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(patientName,
                          style: const TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w700, color: _deepBlue))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(status, style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700, color: statusColor)),
                      ),
                    ]),
                  ),
                  // Info rows
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _infoRow(Icons.badge_outlined, 'Patient ID', patientId),
                      _infoRow(Icons.medical_services_outlined, 'Doctor', doctorName),
                      _infoRow(Icons.calendar_today_outlined, 'Date', date),
                      _infoRow(Icons.access_time_rounded, 'Slot', slot),
                    ]),
                  ),
                  // Actions (Pending only)
                  if (status == 'Pending')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('appointments')
                                    .doc(docs[i].id)
                                    .update({'status': 'Completed'});
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Marked as Completed'),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating));
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Complete', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) =>
                                      UploadConsultationSummaryScreen(
                                        prefilledPatientId: patientId,
                                        prefilledPatientName: patientName,
                                      ))),
                              icon: const Icon(Icons.upload_file_rounded, size: 16),
                              label: const Text('Upload Summary',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _deepBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => _RescheduleDialog(
                                appointmentId: docs[i].id,
                                current: data,
                              ),
                            ),
                            icon: const Icon(Icons.event_repeat_rounded, size: 16),
                            label: const Text('Reschedule',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _deepBlue,
                              side: const BorderSide(color: _deepBlue),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ]),
                    ),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 15, color: Colors.grey.shade500),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(fontSize: 12,
          color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Reschedule dialog — full StatefulWidget, leave-aware doctor selection
// ─────────────────────────────────────────────────────────────────────────────

class _RescheduleDialog extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> current;
  const _RescheduleDialog({required this.appointmentId, required this.current});

  @override
  State<_RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<_RescheduleDialog> {
  static const Color _deepBlue  = Color(0xFF0D47A1);
  static const Color _leaveRed  = Color(0xFFD32F2F);
  static const Color _warnAmber = Color(0xFFF57C00);

  // Data
  List<DoctorInfo> _doctors = [];
  // doctorId → DoctorAvailability (blockedDates, workingDays)
  Map<String, Map<String, dynamic>> _availability = {};
  Map<String, dynamic> _rules = {};

  // Selections
  DoctorInfo? _selectedDoctor;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  List<String> _availableSlots = [];
  Set<String> _bookedSlots = {};

  // State flags
  bool _loadingInit  = true;
  bool _loadingSlots = false;
  bool _saving       = false;

  // Days of week index → name (DateTime.weekday: Mon=1..Sun=7)
  static const _dayNames = {
    1: 'Monday', 2: 'Tuesday', 3: 'Wednesday',
    4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final db = FirebaseFirestore.instance;

    // Fetch doctors + admin rules in parallel
    final results = await Future.wait([
      PatientService().fetchDoctors(),
      _fetchAdminRules(),
    ]);
    final doctors = results[0] as List<DoctorInfo>;
    final rules   = results[1] as Map<String, dynamic>;

    // Fetch each doctor's availability doc in parallel
    final availFutures = doctors.map((d) async {
      try {
        final snap = await db
            .collection('doctor_availability').doc(d.id).get();
        return MapEntry(d.id, snap.exists ? snap.data()! : <String, dynamic>{});
      } catch (_) {
        return MapEntry(d.id, <String, dynamic>{});
      }
    });
    final availEntries = await Future.wait(availFutures);
    final availability = Map<String, Map<String, dynamic>>.fromEntries(
        availEntries);

    final initialDate = (widget.current['date'] as Timestamp?)?.toDate()
        ?? DateTime.now();

    DoctorInfo? matched;
    try {
      matched = doctors.firstWhere((d) => d.id == widget.current['doctorId']);
    } catch (_) {
      matched = doctors.isNotEmpty ? doctors.first : null;
    }

    if (!mounted) return;
    setState(() {
      _doctors      = doctors;
      _availability = availability;
      _rules        = rules;
      _selectedDoctor = matched;
      _selectedDate   = initialDate;
      _loadingInit    = false;
    });

    if (matched != null) _refreshSlots(matched, initialDate);
  }

  // ── Leave / availability helpers ──────────────────────────────────────────

  /// Returns the leave status for a doctor on the currently selected date.
  /// 'leave'      → full day blocked
  /// 'nonworking' → not a working day for this doctor
  /// 'available'  → working and not blocked
  String _doctorStatus(DoctorInfo doc, DateTime date) {
    final avail = _availability[doc.id] ?? {};
    final dateKey = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
    final blocked  = List<String>.from(avail['blockedDates'] ?? []);
    if (blocked.contains(dateKey)) return 'leave';

    final rawWd = avail['workingDays'] as Map<String, dynamic>? ?? {};
    // If no workingDays set, treat all days as working
    if (rawWd.isEmpty) return 'available';
    final dayName = _dayNames[date.weekday] ?? '';
    final isWorking = rawWd[dayName] as bool? ?? false;
    if (!isWorking) return 'nonworking';
    return 'available';
  }

  Future<Map<String, dynamic>> _fetchAdminRules() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings').doc('appointment_rules').get();
      if (doc.exists) return doc.data()!;
    } catch (_) {}
    return {'startTime': '09:00', 'endTime': '17:00',
            'slotDurationMinutes': 30, 'hasBreak': false,
            'breakStart': '13:00', 'breakEnd': '14:00'};
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

    final start    = parseT(_rules['startTime'] ?? '09:00');
    final end      = parseT(_rules['endTime']   ?? '17:00');
    final duration = _rules['slotDurationMinutes'] as int? ?? 30;
    final hasBreak = _rules['hasBreak'] as bool? ?? false;
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

  Future<void> _refreshSlots(DoctorInfo doctor, DateTime date) async {
    if (!mounted) return;
    setState(() { _loadingSlots = true; _selectedSlot = null; });

    final start = DateTime(date.year, date.month, date.day);
    final end   = start.add(const Duration(days: 1));

    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctor.id)
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
      _availableSlots = all;
      _bookedSlots    = booked;
      _loadingSlots   = false;
    });
  }

  Future<void> _save() async {
    final doc = _selectedDoctor;
    final slot = _selectedSlot;
    if (doc == null || slot == null) return;
    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final apptRef = db.collection('appointments').doc(widget.appointmentId);

      // Update the appointment with new doctor / date / slot
      batch.update(apptRef, {
        'doctorId':       doc.id,
        'doctorName':     doc.name,
        'date':           Timestamp.fromDate(DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day)),
        'slot':           slot,
        'status':         'Pending',
        'previousDoctor': widget.current['doctorName'] ?? '',
        'previousSlot':   widget.current['slot'] ?? '',
        'previousDate':   widget.current['date'],
        'rescheduledAt':  FieldValue.serverTimestamp(),
      });

      // If the doctor changed, create a ghost 'Rescheduled' record for the
      // OLD doctor + old slot so it doesn't count as booked for other patients.
      // If same doctor, the query in _refreshSlots already excludes this appt by id.
      final oldDoctorId = widget.current['doctorId'] as String? ?? '';
      if (oldDoctorId.isNotEmpty && oldDoctorId != doc.id) {
        final ghostRef = db.collection('appointments').doc();
        batch.set(ghostRef, {
          'doctorId':   oldDoctorId,
          'doctorName': widget.current['doctorName'] ?? '',
          'date':       widget.current['date'],
          'slot':       widget.current['slot'] ?? '',
          'status':     'Rescheduled',
          'isGhost':    true,
          'originalAppointmentId': widget.appointmentId,
          'createdAt':  FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Appointment rescheduled ✓'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: _loadingInit
          ? const SizedBox(height: 180,
              child: Center(child: CircularProgressIndicator()))
          : Column(mainAxisSize: MainAxisSize.min, children: [
              // ── Title bar ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(children: [
                  Container(width: 4, height: 20,
                      decoration: BoxDecoration(color: _deepBlue,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Reschedule Appointment',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w700, color: _deepBlue)),
                  ),
                  GestureDetector(
                    onTap: _saving ? null : () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded,
                        color: Colors.grey.shade500, size: 22),
                  ),
                ]),
              ),

              // ── Scrollable body ──────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Doctor list ────────────────────────────────
                      _sectionLabel('Select Doctor'),
                      const SizedBox(height: 4),
                      // Hint: available doctors shown first
                      Text(
                        'Doctors on leave or not working on the selected date are shown with a warning',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 260),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: () {
                                // Sort: available first, non-working second, on leave last
                                final sorted = [..._doctors];
                                sorted.sort((a, b) {
                                  const order = {'available': 0, 'nonworking': 1, 'leave': 2};
                                  return (order[_doctorStatus(a, _selectedDate)] ?? 0)
                                      .compareTo(order[_doctorStatus(b, _selectedDate)] ?? 0);
                                });
                                return sorted.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final doc = entry.value;
                                  final isSelected  = _selectedDoctor?.id == doc.id;
                                  final status = _doctorStatus(doc, _selectedDate);
                                  final isOnLeave     = status == 'leave';
                                  final isNonWorking  = status == 'nonworking';
                                  final isUnavailable = isOnLeave || isNonWorking;

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (idx > 0) Divider(height: 1, color: Colors.grey.shade100),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _saving ? null : () {
                                            setState(() => _selectedDoctor = doc);
                                            _refreshSlots(doc, _selectedDate);
                                          },
                                          child: Container(
                                            color: isSelected
                                                ? const Color(0xFFE3F2FD)
                                                : isUnavailable
                                                    ? Colors.grey.shade50
                                                    : Colors.transparent,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 10),
                                            child: Row(children: [
                                              // Avatar
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: isSelected
                                                    ? _deepBlue
                                                    : isUnavailable
                                                        ? Colors.grey.shade200
                                                        : const Color(0xFFE3F2FD),
                                                child: Icon(Icons.person_rounded,
                                                    size: 18,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : isUnavailable
                                                            ? Colors.grey.shade400
                                                            : _deepBlue),
                                              ),
                                              const SizedBox(width: 12),
                                              // Name + specialty + badge
                                              Expanded(child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(children: [
                                                    Flexible(
                                                      child: Text('Dr. ${doc.name}',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w600,
                                                              color: isSelected
                                                                  ? _deepBlue
                                                                  : isUnavailable
                                                                      ? Colors.grey.shade500
                                                                      : const Color(0xFF0D1B3E))),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    if (isOnLeave)
                                                      _badge('On Leave', _leaveRed)
                                                    else if (isNonWorking)
                                                      _badge('Day Off', _warnAmber),
                                                  ]),
                                                  if (doc.specialty.isNotEmpty)
                                                    Text(doc.specialty,
                                                        style: TextStyle(fontSize: 11,
                                                            color: Colors.grey.shade500)),
                                                  if (isUnavailable)
                                                    Text(
                                                      isOnLeave
                                                          ? 'Not available — you can still reassign'
                                                          : 'Not scheduled to work — you can still reassign',
                                                      style: TextStyle(fontSize: 10,
                                                          color: isOnLeave
                                                              ? _leaveRed.withValues(alpha: 0.8)
                                                              : _warnAmber.withValues(alpha: 0.8)),
                                                    ),
                                                ],
                                              )),
                                              if (isSelected)
                                                const Icon(Icons.check_circle_rounded,
                                                    color: _deepBlue, size: 18),
                                            ]),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList();
                              }(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Date ──────────────────────────────────────
                      _sectionLabel('Select Date'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _saving ? null : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                                const Duration(days: 60)),
                            builder: (_, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                    primary: _deepBlue),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null &&
                              _selectedDoctor != null) {
                            setState(() => _selectedDate = picked);
                            _refreshSlots(_selectedDoctor!, picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFFBBDEFB),
                                width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: _deepBlue, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '${_selectedDate.day} '
                              '${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][_selectedDate.month - 1]} '
                              '${_selectedDate.year}',
                              style: const TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0D1B3E)),
                            ),
                            const Spacer(),
                            Icon(Icons.edit_calendar_rounded,
                                color: Colors.grey.shade400, size: 18),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Slots ──────────────────────────────────────
                      _sectionLabel('Select Time Slot'),
                      const SizedBox(height: 8),
                      if (_loadingSlots)
                        const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ))
                      else if (_availableSlots.isEmpty)
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
                            Wrap(spacing: 8, runSpacing: 8,
                          children: _availableSlots.map((slot) {
                            final isSel    = _selectedSlot == slot;
                            final isBooked = _bookedSlots.contains(slot);
                            return GestureDetector(
                              onTap: (_saving || isBooked)
                                  ? null
                                  : () => setState(
                                      () => _selectedSlot = slot),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 130),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isBooked
                                      ? Colors.grey.shade100
                                      : isSel ? _deepBlue : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isBooked
                                        ? Colors.grey.shade300
                                        : isSel
                                            ? _deepBlue
                                            : const Color(0xFFBBDEFB),
                                    width: 1.5,
                                  ),
                                  boxShadow: isSel ? [BoxShadow(
                                      color: _deepBlue.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))] : [],
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min,
                                    children: [
                                  if (isBooked) ...[ 
                                    Icon(Icons.block_rounded,
                                        size: 11, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                  ] else if (isSel) ...[
                                    const Icon(Icons.check_circle_rounded,
                                        size: 11, color: Colors.white),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(slot, style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isBooked
                                          ? Colors.grey.shade400
                                          : isSel
                                              ? Colors.white
                                              : const Color(0xFF0D1B3E))),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          // available swatch
                          Container(width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
                                borderRadius: BorderRadius.circular(3),
                              )),
                          const SizedBox(width: 4),
                          Text('Available', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          const SizedBox(width: 12),
                          // booked swatch
                          Container(width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                borderRadius: BorderRadius.circular(3),
                              )),
                          const SizedBox(width: 4),
                          Text('Booked', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ]),
                      ],
                        ),
                      const SizedBox(height: 24),

                      // ── Actions ────────────────────────────────────
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_saving ||
                                _selectedSlot == null ||
                                _selectedDoctor == null)
                                ? null : _save,
                            icon: _saving
                                ? const SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(
                                    Icons.event_repeat_rounded, size: 16),
                            label: Text(_saving ? 'Saving…' : 'Confirm',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _deepBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ]),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: Color(0xFF0D1B3E)));

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(label, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}