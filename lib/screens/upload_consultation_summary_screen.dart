import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import '../models/app_user_session.dart';

/// Screen used by medical staff / nurses to upload the summary of
/// an offline (in-person) consultation so doctors can review it
/// during the next online consultation.
class UploadConsultationSummaryScreen extends StatefulWidget {
  const UploadConsultationSummaryScreen({super.key});

  @override
  State<UploadConsultationSummaryScreen> createState() =>
      _UploadConsultationSummaryScreenState();
}

class _UploadConsultationSummaryScreenState
    extends State<UploadConsultationSummaryScreen> {
  final _service = DoctorService();

  static const Color _deepBlue = Color(0xFF0D47A1);
  static const Color _accentBlue = Color(0xFF2E7DFF);
  static const Color _lightBlue = Color(0xFFE8F0FE);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF6B7280);

  final _formKey = GlobalKey<FormState>();

  final _patientIdCtrl = TextEditingController();
  final _patientNameCtrl = TextEditingController();
  final _doctorNameCtrl = TextEditingController();
  final _uploadedByCtrl = TextEditingController();
  final _chiefComplaintCtrl = TextEditingController();
  final _clinicalFindingsCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _nurseNotesCtrl = TextEditingController();

  DateTime _visitDate = DateTime.now();
  TimeOfDay _visitTime = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill "Uploaded By" from the logged-in staff member's name
    final currentName = AppUserSession.currentUser?.name ?? '';
    _uploadedByCtrl.text = currentName;
  }

  @override
  void dispose() {
    for (final c in [
      _patientIdCtrl,
      _patientNameCtrl,
      _doctorNameCtrl,
      _uploadedByCtrl,
      _chiefComplaintCtrl,
      _clinicalFindingsCtrl,
      _diagnosisCtrl,
      _treatmentCtrl,
      _nurseNotesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Date / Time helpers ───────────────────────────────────────────────────

  String _formatDate(DateTime d) =>
      '${_month(d.month)} ${d.day}, ${d.year}';

  String _month(int m) => const [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$min $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _deepBlue)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _visitTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _deepBlue)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _visitTime = picked);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _service.uploadConsultationSummary(
        patientId: _patientIdCtrl.text.trim(),
        patientName: _patientNameCtrl.text.trim(),
        doctorName: _doctorNameCtrl.text.trim(),
        visitDate: _formatDate(_visitDate),
        visitTime: _formatTime(_visitTime),
        chiefComplaint: _chiefComplaintCtrl.text.trim(),
        clinicalFindings: _clinicalFindingsCtrl.text.trim(),
        diagnosis: _diagnosisCtrl.text.trim(),
        treatmentGiven: _treatmentCtrl.text.trim(),
        nurseNotes: _nurseNotesCtrl.text.trim(),
        uploadedBy: _uploadedByCtrl.text.trim(),
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to upload summary: $e'),
        backgroundColor: Colors.red.shade600,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Summary Uploaded!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            Text(
              'The offline consultation summary for '
              '${_patientNameCtrl.text.trim()} has been saved to Firestore. '
              'The doctor will be able to review it during the next '
              'online consultation.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: _textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done',
                style: TextStyle(color: _deepBlue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _deepBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: const Text('Add Another',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    for (final c in [
      _patientIdCtrl,
      _patientNameCtrl,
      _doctorNameCtrl,
      _chiefComplaintCtrl,
      _clinicalFindingsCtrl,
      _diagnosisCtrl,
      _treatmentCtrl,
      _nurseNotesCtrl,
    ]) {
      c.clear();
    }
    // Re-populate uploaded-by from session
    _uploadedByCtrl.text = AppUserSession.currentUser?.name ?? '';
    setState(() {
      _visitDate = DateTime.now();
      _visitTime = TimeOfDay.now();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Upload Consultation Summary',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Info banner ────────────────────────────────────────────────
            _infoBanner(),
            const SizedBox(height: 20),

            // ── Patient Information ────────────────────────────────────────
            _sectionCard(
              title: 'Patient Information',
              icon: Icons.person_outline_rounded,
              children: [
                _field(
                  ctrl: _patientIdCtrl,
                  label: 'Patient ID',
                  icon: Icons.badge_outlined,
                  hint: 'e.g. P0001',
                  validator: _required,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                _field(
                  ctrl: _patientNameCtrl,
                  label: 'Patient Full Name',
                  icon: Icons.person_rounded,
                  hint: 'e.g. Ananya R.',
                  validator: _required,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Visit Details ──────────────────────────────────────────────
            _sectionCard(
              title: 'Visit Details',
              icon: Icons.event_note_rounded,
              children: [
                _field(
                  ctrl: _doctorNameCtrl,
                  label: 'Consulting Doctor',
                  icon: Icons.medical_services_outlined,
                  hint: 'e.g. Dr. Anita Sharma',
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: _dateTile(
                      label: 'Visit Date',
                      value: _formatDate(_visitDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateTile(
                      label: 'Visit Time',
                      value: _formatTime(_visitTime),
                      icon: Icons.access_time_rounded,
                      onTap: _pickTime,
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 16),

            // ── Clinical Summary ───────────────────────────────────────────
            _sectionCard(
              title: 'Clinical Summary',
              icon: Icons.summarize_rounded,
              children: [
                _field(
                  ctrl: _chiefComplaintCtrl,
                  label: 'Chief Complaint',
                  icon: Icons.report_problem_outlined,
                  hint: 'Main reason for visit…',
                  maxLines: 2,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                _field(
                  ctrl: _clinicalFindingsCtrl,
                  label: 'Clinical Findings',
                  icon: Icons.biotech_outlined,
                  hint: 'Vitals, examination findings…',
                  maxLines: 3,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                _field(
                  ctrl: _diagnosisCtrl,
                  label: 'Diagnosis / Impression',
                  icon: Icons.health_and_safety_outlined,
                  hint: 'Doctor\'s diagnosis…',
                  maxLines: 2,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                _field(
                  ctrl: _treatmentCtrl,
                  label: 'Treatment / Procedures Given',
                  icon: Icons.medication_outlined,
                  hint: 'Medications administered, procedures done…',
                  maxLines: 3,
                  validator: _required,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Nurse Notes ────────────────────────────────────────────────
            _sectionCard(
              title: 'Nurse / Staff Notes',
              icon: Icons.edit_note_rounded,
              children: [
                _field(
                  ctrl: _nurseNotesCtrl,
                  label: 'Additional Observations',
                  icon: Icons.notes_rounded,
                  hint: 'Patient behaviour, vitals trend, anything to flag…',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _field(
                  ctrl: _uploadedByCtrl,
                  label: 'Uploaded By (Your Name)',
                  icon: Icons.badge_rounded,
                  hint: 'e.g. Nurse Priya',
                  validator: _required,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Submit ─────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload_rounded, size: 20),
                label: Text(
                  _isSaving
                      ? 'Uploading to Firestore…'
                      : 'Upload Consultation Summary',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _deepBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isSaving ? null : _submit,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Widget helpers ─────────────────────────────────────────────────────────

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentBlue.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _accentBlue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Fill in the details of the patient\'s offline visit. '
              'This summary will be saved to Firestore and will be '
              'visible to the assigned doctor during the next online '
              'consultation under "Previous Consultations".',
              style: TextStyle(
                  fontSize: 12.5, color: _textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _lightBlue,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: _deepBlue),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _deepBlue)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: maxLines == 1
            ? Icon(icon, size: 20, color: _textSecondary)
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: _deepBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(fontSize: 13),
        hintStyle:
            TextStyle(fontSize: 12, color: Colors.grey.shade400),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _dateTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: _textSecondary)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(icon, size: 15, color: _deepBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;
}