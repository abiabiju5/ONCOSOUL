import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import '../services/prescription_pdf_service.dart';
import '../models/app_user_session.dart';

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

  final _remarksCtrl = TextEditingController();
  final _medicineCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  final List<Map<String, String>> _prescriptions = [];
  bool _isSavingPdf = false;

  bool _videoExpanded = true;
  bool _reportsExpanded = true;
  bool _summariesExpanded = true;
  bool _notesExpanded = true;
  bool _prescriptionExpanded = true;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const Color _green = Color(0xFF1B8A5A);
  static const Color _lightGreen = Color(0xFFE8F5EE);
  static const Color _bg = Color(0xFFFAFAFA);
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
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _remarksCtrl.dispose();
    _medicineCtrl.dispose();
    _dosageCtrl.dispose();
    _durationCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  void _addMedicine() {
    if (_medicineCtrl.text.trim().isEmpty ||
        _dosageCtrl.text.trim().isEmpty ||
        _durationCtrl.text.trim().isEmpty) {
      _snack('Please fill in all medicine fields.', isError: true);
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

  Future<void> _savePrescription() async {
    if (_prescriptions.isEmpty) {
      _snack('No prescriptions to save.', isError: true);
      return;
    }
    setState(() => _isSavingPdf = true);
    try {
      final doctorName = AppUserSession.currentUser?.name ?? 'Doctor';
      final file = await PrescriptionPdfService.generatePrescriptionPdf(
        patientName: widget.patientName,
        doctorName: 'Dr. $doctorName',
        medicines: _prescriptions,
      );
      await PrescriptionPdfService.printPdf(file);
      _snack('Prescription PDF generated successfully!');
    } catch (_) {
      _snack('Failed to generate PDF.', isError: true);
    } finally {
      setState(() => _isSavingPdf = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_rounded : Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: isError ? Colors.red.shade600 : _green,
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
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Video section
            _section(
              title: 'Video Consultation',
              icon: Icons.videocam_rounded,
              color: _green,
              isExpanded: _videoExpanded,
              onToggle: () => setState(() => _videoExpanded = !_videoExpanded),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green, width: 2),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_rounded, size: 60, color: Colors.white70),
                      SizedBox(height: 10),
                      Text('Video call in progress',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Medical Reports
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

            // Offline Summaries
            _section(
              title: 'Previous Consultations',
              icon: Icons.history_rounded,
              color: _deepBlue,
              isExpanded: _summariesExpanded,
              onToggle: () =>
                  setState(() => _summariesExpanded = !_summariesExpanded),
              child: StreamBuilder<List<FirestoreSummary>>(
                stream: _service.summariesForPatient(widget.patientId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final summaries = snap.data ?? [];
                  if (summaries.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No offline visit summaries found.',
                          style: TextStyle(color: _textSecondary)),
                    );
                  }
                  return Column(
                      children: summaries.map(_summaryCard).toList());
                },
              ),
            ),

            const SizedBox(height: 16),

            // Doctor Notes
            _section(
              title: 'Doctor Notes',
              icon: Icons.edit_note_rounded,
              color: _green,
              isExpanded: _notesExpanded,
              onToggle: () => setState(() => _notesExpanded = !_notesExpanded),
              child: Column(
                children: [
                  TextField(
                    controller: _remarksCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter consultation notes…',
                      filled: true,
                      fillColor: _lightGreen,
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
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Save Notes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_remarksCtrl.text.trim().isEmpty) {
                          _snack('Please enter some notes.', isError: true);
                        } else {
                          _snack('Notes saved!');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Prescription
            _section(
              title: 'Prescription',
              icon: Icons.medication_rounded,
              color: const Color(0xFF7B1FA2),
              isExpanded: _prescriptionExpanded,
              onToggle: () => setState(
                  () => _prescriptionExpanded = !_prescriptionExpanded),
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
                              '${p['dosage']}  •  ${p['duration']}${p['instructions']!.isNotEmpty ? '\n${p['instructions']}' : ''}'),
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
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add'),
                        onPressed: _addMedicine,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isSavingPdf
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.print_rounded, size: 16),
                        label: Text(_isSavingPdf ? 'Generating…' : 'Print PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B1FA2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSavingPdf ? null : _savePrescription,
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _deepBlue.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_rounded,
              color: _deepBlue, size: 20),
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
                  'Uploaded: ${r.uploadedAt.day}/${r.uploadedAt.month}/${r.uploadedAt.year}  •  ${r.uploadedBy}',
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
                if (r.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(r.notes,
                      style:
                          const TextStyle(fontSize: 12, color: _textPrimary)),
                ],
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                _sRow(Icons.medical_services_outlined, 'Doctor', s.doctorName),
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
                                      fontSize: 12, color: _textPrimary)),
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
                  style: const TextStyle(fontSize: 13, color: _textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}