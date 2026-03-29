import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/doctor_service.dart';

import '../services/consultation_room_service.dart';
import '../models/app_user_session.dart';
import '../screens/pdf_viewer_screen.dart';

class ConsultationRoomPage extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  final String patientId;

  const ConsultationRoomPage({
    super.key,
    required this.appointmentId,
    required this.patientName,
    required this.patientId,
  });

  @override
  State<ConsultationRoomPage> createState() => _ConsultationRoomPageState();
}

class _ConsultationRoomPageState extends State<ConsultationRoomPage>
    with TickerProviderStateMixin {
  final _service = DoctorService();
  final _roomService = ConsultationRoomService();

  ConsultationRoom? _room;
  bool _isStartingCall = false;
  bool _isEndingCall   = false;

  final _remarksCtrl = TextEditingController();
  final _medicineCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();

  final List<Map<String, String>> _prescriptions = [];

  bool _isSavingNotes = false;
  bool _isIssuingPrescription = false;
  bool _notesLoading = true;

  bool _videoExpanded = true;
  bool _reportsExpanded = true;
  bool _summariesExpanded = true;
  bool _notesExpanded = true;
  bool _prescriptionExpanded = true;
  bool _newPrescriptionExpanded = true;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const Color _deepBlue2 = Color(0xFF0D47A1); // primary
  static const Color _lightBlue2 = Color(0xFFE3F2FD);
  static const Color _bg = Color(0xFFF0F4FF);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _deepBlue = Color(0xFF0D47A1);
  static const Color _divider = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadExistingNotes();
  }

  /// Pre-fill the notes field with any previously saved notes for this appointment.
  Future<void> _loadExistingNotes() async {
    try {
      final saved =
          await _service.fetchConsultationNotes(widget.appointmentId);
      if (mounted) {
        _remarksCtrl.text = saved;
      }
    } catch (_) {
      // Non-fatal — field stays empty
    } finally {
      if (mounted) setState(() => _notesLoading = false);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _remarksCtrl.dispose();
    _medicineCtrl.dispose();
    _dosageCtrl.dispose();
    _durationCtrl.dispose();
    _instructionsCtrl.dispose();
    _diagnosisCtrl.dispose();
    super.dispose();
  }

  void _addMedicine() {
    if (_medicineCtrl.text.trim().isEmpty ||
        _dosageCtrl.text.trim().isEmpty ||
        _durationCtrl.text.trim().isEmpty) {
      _snack('Please fill in medicine name, dosage and duration.', isError: true);
      return;
    }
    setState(() {
      _prescriptions.add({
        'medicine': _medicineCtrl.text.trim(),
        'dosage': _dosageCtrl.text.trim(),
        'duration': _durationCtrl.text.trim(),
        'instructions': _instructionsCtrl.text.trim(),
      });
      _medicineCtrl.clear();
      _dosageCtrl.clear();
      _durationCtrl.clear();
      _instructionsCtrl.clear();
    });
    _snack('Medicine added to prescription.');
  }

  /// Save notes to Firestore (upsert — one doc per appointment per doctor).
  Future<void> _saveNotes() async {
    final text = _remarksCtrl.text.trim();
    if (text.isEmpty) {
      _snack('Please enter some notes before saving.', isError: true);
      return;
    }
    setState(() => _isSavingNotes = true);
    try {
      await _service.saveConsultationNotes(
        appointmentId: widget.appointmentId,
        patientId: widget.patientId,
        patientName: widget.patientName,
        notes: text,
      );
      _snack('Notes saved successfully!');
    } catch (e) {
      _snack('Failed to save notes: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingNotes = false);
    }
  }

  Future<void> _issuePrescription() async {
    if (_prescriptions.isEmpty) {
      _snack('Please add at least one medicine before issuing.', isError: true);
      return;
    }
    setState(() => _isIssuingPrescription = true);
    try {
      await _service.savePrescription(
        appointmentId: widget.appointmentId,
        patientId: widget.patientId,
        patientName: widget.patientName,
        medicines: _prescriptions,
        diagnosis: _diagnosisCtrl.text.trim().isEmpty
            ? null
            : _diagnosisCtrl.text.trim(),
      );
      setState(() {
        _prescriptions.clear();
        _diagnosisCtrl.clear();
      });
      _snack('Prescription issued successfully!');
    } catch (e) {
      _snack('Failed to issue prescription: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isIssuingPrescription = false);
    }
  }

  Future<void> _startCall() async {
    setState(() => _isStartingCall = true);
    try {
      final doctorId = AppUserSession.userId;
      final room = await _roomService.startRoom(
        appointmentId: widget.appointmentId,
        doctorId: doctorId,
        patientId: widget.patientId,
      );
      setState(() => _room = room);
      await _launchRoom(room.joinUrl);
    } catch (e) {
      _snack('Failed to start call: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isStartingCall = false);
    }
  }

  Future<void> _endCall() async {
    setState(() => _isEndingCall = true);
    try {
      await _roomService.endRoom(widget.appointmentId);
      setState(() => _room = null);
      _snack('Call ended.');
    } catch (e) {
      _snack('Failed to end call: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isEndingCall = false);
    }
  }

  Future<void> _launchRoom(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('Could not open video call. Please check your browser.', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_rounded : Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: isError ? Colors.red.shade600 : _deepBlue2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Consulting ${widget.patientName}'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Video ──────────────────────────────────────────────────────
            _section(
              title: 'Video Consultation',
              icon: Icons.videocam_rounded,
              color: _deepBlue2,
              isExpanded: _videoExpanded,
              onToggle: () => setState(() => _videoExpanded = !_videoExpanded),
              child: StreamBuilder<ConsultationRoom?>(
                stream: _roomService.roomStream(widget.appointmentId),
                builder: (context, snap) {
                  final room = snap.data;
                  final isActive = room?.isActive == true;

                  return Column(
                    children: [
                      // ── Room status card ──────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? Colors.green.shade300
                                : _deepBlue2.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.shade100
                                    : _lightBlue2,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isActive
                                    ? Icons.videocam_rounded
                                    : Icons.videocam_off_rounded,
                                color: isActive
                                    ? Colors.green.shade700
                                    : _deepBlue2,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isActive
                                        ? 'Call in Progress'
                                        : 'No Active Call',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isActive
                                          ? Colors.green.shade800
                                          : _deepBlue2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isActive
                                        ? 'Patient can join using the notification link.'
                                        : 'Start the call to let the patient join.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isActive
                                          ? Colors.green.shade700
                                          : _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Action buttons ────────────────────────────────
                      if (!isActive)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isStartingCall
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.videocam_rounded, size: 18),
                            label: Text(_isStartingCall
                                ? 'Starting…'
                                : 'Start Video Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _deepBlue2,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11)),
                            ),
                            onPressed: _isStartingCall ? null : _startCall,
                          ),
                        )
                      else
                        Row(
                          children: [
                            // Rejoin button
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.open_in_new_rounded,
                                    size: 15),
                                label: const Text('Rejoin'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _deepBlue2,
                                  side: BorderSide(
                                      color: _deepBlue2.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 11),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11)),
                                ),
                                onPressed: () =>
                                    _launchRoom(room!.joinUrl),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // End call button
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: _isEndingCall
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.call_end_rounded,
                                        size: 16),
                                label: Text(_isEndingCall
                                    ? 'Ending…'
                                    : 'End Call'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 11),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11)),
                                ),
                                onPressed: _isEndingCall ? null : _endCall,
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Medical Reports (live Firestore stream) ────────────────────
            _section(
              title: 'Medical Reports',
              icon: Icons.description_rounded,
              color: _deepBlue,
              isExpanded: _reportsExpanded,
              onToggle: () =>
                  setState(() => _reportsExpanded = !_reportsExpanded),
              child: StreamBuilder<List<FirestoreReport>>(
                stream: _service.reportsForPatient(widget.patientId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final reports = snap.data ?? [];
                  if (reports.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No reports uploaded yet.',
                          style: TextStyle(color: _textSecondary)),
                    );
                  }
                  return Column(
                      children: reports.map(_reportTile).toList());
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Previous Consultations (summaries + doctor notes) ──────────
            _section(
              title: 'Previous Consultations',
              icon: Icons.history_rounded,
              color: _deepBlue,
              isExpanded: _summariesExpanded,
              onToggle: () =>
                  setState(() => _summariesExpanded = !_summariesExpanded),
              child: StreamBuilder<List<FirestoreSummary>>(
                stream: _service.summariesForPatient(widget.patientId),
                builder: (context, summarySnap) {
                  return StreamBuilder<List<ConsultationNote>>(
                    stream: _service.notesForPatientStream(widget.patientId),
                    builder: (context, notesSnap) {
                      if (summarySnap.connectionState == ConnectionState.waiting ||
                          notesSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final summaries = summarySnap.data ?? [];
                      final notes     = notesSnap.data ?? [];
                      if (summaries.isEmpty && notes.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No previous consultations found.',
                              style: TextStyle(color: _textSecondary)),
                        );
                      }
                      return Column(children: [
                        // Doctor notes (from online consultations)
                        if (notes.isNotEmpty) ...notes.map(_noteCard),
                        // Offline visit summaries
                        if (summaries.isNotEmpty) ...summaries.map(_summaryCard),
                      ]);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Doctor Notes (saves to Firestore) ─────────────────────────
            _section(
              title: 'Doctor Notes',
              icon: Icons.edit_note_rounded,
              color: _deepBlue2,
              isExpanded: _notesExpanded,
              onToggle: () =>
                  setState(() => _notesExpanded = !_notesExpanded),
              child: _notesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        TextField(
                          controller: _remarksCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enter consultation notes…',
                            filled: true,
                            fillColor: _lightBlue2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isSavingNotes
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save_rounded, size: 16),
                            label: Text(
                                _isSavingNotes ? 'Saving…' : 'Save Notes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _deepBlue2,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isSavingNotes ? null : _saveNotes,
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // ── Patient Medicine List (all prescriptions + offline) ────────
            _section(
              title: 'Patient Medicine List',
              icon: Icons.medication_liquid_rounded,
              color: const Color(0xFF00796B),
              isExpanded: _prescriptionExpanded,
              onToggle: () => setState(
                  () => _prescriptionExpanded = !_prescriptionExpanded),
              child: StreamBuilder<List<DoctorPrescription>>(
                stream: _service.allPrescriptionsForPatientStream(widget.patientId),
                builder: (context, prescSnap) {
                  return StreamBuilder<List<FirestoreSummary>>(
                    stream: _service.summariesForPatient(widget.patientId),
                    builder: (context, summSnap) {
                      final onlineRx = prescSnap.data ?? [];
                      final summaries = summSnap.data ?? [];
                      // Build offline medicine entries from summaries that have treatmentGiven
                      final offlineTreatments = summaries
                          .where((s) => s.treatmentGiven.trim().isNotEmpty)
                          .toList();

                      if (onlineRx.isEmpty && offlineTreatments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            const Text('No previous medicines on record.',
                                style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ]),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Online prescriptions
                          if (onlineRx.isNotEmpty) ...[
                            const Text('Online Prescriptions',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF00796B))),
                            const SizedBox(height: 8),
                            ...onlineRx.map((rx) {
                              final dateStr =
                                  '${rx.createdAt.day}/${rx.createdAt.month}/${rx.createdAt.year}';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFF80CBC4)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00796B),
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(10)),
                                      ),
                                      child: Row(children: [
                                        const Icon(Icons.person_rounded,
                                            size: 13,
                                            color: Colors.white70),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Dr. ${rx.doctorName}  ·  $dateStr',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w600),
                                          ),
                                        ),
                                        if (rx.diagnosis != null &&
                                            rx.diagnosis!.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(rx.diagnosis!,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white)),
                                          ),
                                      ]),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        children: rx.medicines.map((m) {
                                          final name = m['medicine'] ??
                                              m['name'] ??
                                              '';
                                          final dosage = m['dosage'] ?? '';
                                          final duration =
                                              m['duration'] ?? '';
                                          final instructions =
                                              m['instructions'] ?? '';
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 6),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin:
                                                      const EdgeInsets.only(
                                                          top: 5, right: 8),
                                                  width: 7,
                                                  height: 7,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color:
                                                        Color(0xFF00796B),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(name,
                                                          style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Color(
                                                                  0xFF004D40))),
                                                      if (dosage.isNotEmpty ||
                                                          duration.isNotEmpty)
                                                        Text(
                                                          [
                                                            if (dosage
                                                                .isNotEmpty)
                                                              dosage,
                                                            if (duration
                                                                .isNotEmpty)
                                                              duration,
                                                          ].join('  ·  '),
                                                          style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .grey
                                                                  .shade600),
                                                        ),
                                                      if (instructions
                                                          .isNotEmpty)
                                                        Text(instructions,
                                                            style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey
                                                                    .shade500,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],

                          // Offline treatments from consultation summaries
                          if (offlineTreatments.isNotEmpty) ...[
                            if (onlineRx.isNotEmpty)
                              const SizedBox(height: 12),
                            const Text('Offline Visit Treatments',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5D4037))),
                            const SizedBox(height: 8),
                            ...offlineTreatments.map((s) {
                              final dateStr =
                                  '${s.uploadedAt.day}/${s.uploadedAt.month}/${s.uploadedAt.year}';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFFFCC80)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF795548),
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(10)),
                                      ),
                                      child: Row(children: [
                                        const Icon(
                                            Icons.local_hospital_rounded,
                                            size: 13,
                                            color: Colors.white70),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${s.doctorName}  ·  $dateStr',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w600),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text('Offline',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white)),
                                        ),
                                      ]),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (s.diagnosis.isNotEmpty) ...[
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                    Icons.biotech_outlined,
                                                    size: 13,
                                                    color: Color(0xFF795548)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    s.diagnosis,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey.shade700),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                  Icons.medication_outlined,
                                                  size: 13,
                                                  color: Color(0xFF795548)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  s.treatmentGiven,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(
                                                          0xFF3E2723)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Prescription (saves PDF + Firestore) ───────────────────────
            _section(
              title: 'Add New Prescription',
              icon: Icons.medication_rounded,
              color: const Color(0xFF7B1FA2),
              isExpanded: _newPrescriptionExpanded,
              onToggle: () => setState(
                  () => _newPrescriptionExpanded = !_newPrescriptionExpanded),
              child: Column(
                children: [
                  if (_prescriptions.isNotEmpty) ...[
                    ..._prescriptions.asMap().entries.map((e) {
                      final i = e.key;
                      final p = e.value;
                      return Card(
                        color: const Color(0xFFF3E5F5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(p['medicine']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${p['dosage']}  •  ${p['duration']}'
                              '${p['instructions']!.isNotEmpty ? '\n${p['instructions']}' : ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_rounded,
                                color: Colors.red),
                            onPressed: () =>
                                setState(() => _prescriptions.removeAt(i)),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                  _field(_medicineCtrl, 'Medicine Name',
                      Icons.medication_rounded),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _field(
                            _dosageCtrl, 'Dosage', Icons.science_rounded)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field(
                            _durationCtrl, 'Duration', Icons.timer_rounded)),
                  ]),
                  const SizedBox(height: 8),
                  _field(_instructionsCtrl, 'Instructions (optional)',
                      Icons.notes_rounded),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Medicine'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7B1FA2),
                        side: const BorderSide(color: Color(0xFF7B1FA2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _addMedicine,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _field(_diagnosisCtrl, 'Diagnosis (optional)',
                      Icons.local_hospital_outlined),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isIssuingPrescription
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 16),
                      label: Text(_isIssuingPrescription
                          ? 'Issuing…'
                          : 'Issue Prescription'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B1FA2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed:
                          _isIssuingPrescription ? null : _issuePrescription,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────────

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: _textPrimary)),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: _divider),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ],
      ),
    );
  }

  Widget _reportTile(FirestoreReport r) {
    final hasFile = r.fileUrl != null && r.fileUrl!.isNotEmpty;

    return GestureDetector(
      onTap: hasFile
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    fileUrl: r.fileUrl!,
                    title: r.reportType,
                  ),
                ),
              )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFile
                ? _deepBlue.withValues(alpha: 0.35)
                : _deepBlue.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFile
                  ? Icons.picture_as_pdf_rounded
                  : Icons.insert_drive_file_rounded,
              color: hasFile ? Colors.red.shade400 : _deepBlue,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.reportType,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    '${r.labName.isNotEmpty ? '${r.labName}  •  ' : ''}'
                    '${r.uploadedAt.day}/${r.uploadedAt.month}/${r.uploadedAt.year}'
                    '  •  ${r.uploadedBy}',
                    style: const TextStyle(
                        fontSize: 11, color: _textSecondary),
                  ),
                  if (r.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(r.notes,
                        style: const TextStyle(
                            fontSize: 12, color: _textPrimary)),
                  ],
                ],
              ),
            ),
            if (hasFile) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _deepBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_rounded,
                        color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('Open',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No file',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _noteCard(ConsultationNote n) {
    final updatedAt = n.updatedAt ?? n.createdAt;
    final dateLabel = '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
    final timeLabel = TimeOfDay.fromDateTime(updatedAt).format(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _deepBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _deepBlue.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              const Icon(Icons.edit_note_rounded, size: 16, color: _deepBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(dateLabel,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _deepBlue)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _deepBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Doctor Notes',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: _deepBlue)),
              ),
            ]),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sRow(Icons.medical_services_outlined, 'Doctor', 'Dr. ${n.doctorName}'),
                const Divider(height: 16),
                _sRow(Icons.notes_rounded, 'Consultation Notes', n.notes),
                const SizedBox(height: 8),
                Text('Saved on $dateLabel at $timeLabel',
                    style: const TextStyle(fontSize: 11, color: _textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(FirestoreSummary s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _deepBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _deepBlue.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_rounded,
                    size: 16, color: _deepBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.uploadedAt.day}/${s.uploadedAt.month}/${s.uploadedAt.year}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _deepBlue),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _deepBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Offline Visit',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _deepBlue)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sRow(Icons.medical_services_outlined, 'Doctor',
                    s.doctorName),
                const Divider(height: 16),
                _sRow(Icons.report_problem_outlined, 'Chief Complaint',
                    s.chiefComplaint),
                const SizedBox(height: 8),
                _sRow(Icons.biotech_outlined, 'Clinical Findings',
                    s.clinicalFindings),
                const SizedBox(height: 8),
                _sRow(Icons.health_and_safety_outlined, 'Diagnosis',
                    s.diagnosis),
                const SizedBox(height: 8),
                _sRow(Icons.medication_outlined, 'Treatment Given',
                    s.treatmentGiven),
                if (s.nurseNotes.isNotEmpty) ...[
                  const Divider(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _deepBlue.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined,
                            size: 16, color: _deepBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nurse Notes',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _deepBlue)),
                              const SizedBox(height: 4),
                              Text(s.nurseNotes,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text('Uploaded by ${s.uploadedBy}',
                    style: const TextStyle(
                        fontSize: 11, color: _textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, color: _textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}