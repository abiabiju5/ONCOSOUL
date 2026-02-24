import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import '../models/app_user_session.dart';

class UploadMedicalReportScreen extends StatefulWidget {
  const UploadMedicalReportScreen({super.key});

  @override
  State<UploadMedicalReportScreen> createState() =>
      _UploadMedicalReportScreenState();
}

class _UploadMedicalReportScreenState
    extends State<UploadMedicalReportScreen> {
  final _service = DoctorService();
  final _formKey = GlobalKey<FormState>();

  final _patientIdCtrl = TextEditingController();
  final _patientNameCtrl = TextEditingController();
  final _labNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedReportType = 'Blood Test';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  static const Color _deepBlue = Color(0xFF0D47A1);
  static const Color _lightBlue = Color(0xFFE8F0FE);
  static const Color _textSecondary = Color(0xFF6B7280);

  static const List<String> _reportTypes = [
    'Blood Test',
    'CT Scan',
    'MRI Scan',
    'Biopsy',
    'X-Ray',
    'Ultrasound',
    'PET Scan',
    'Pathology Report',
    'Endoscopy',
    'Other',
  ];

  @override
  void dispose() {
    _patientIdCtrl.dispose();
    _patientNameCtrl.dispose();
    _labNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _deepBlue)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final uploadedBy = AppUserSession.currentUser?.name ?? 'Medical Staff';

      await _service.uploadMedicalReport(
        patientId: _patientIdCtrl.text.trim(),
        patientName: _patientNameCtrl.text.trim(),
        reportType: _selectedReportType,
        labName: _labNameCtrl.text.trim(),
        uploadedBy: uploadedBy,
        reportDate: _selectedDate,
        notes: _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to upload report: $e'),
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
            const Text('Report Uploaded!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            const Text(
              'The medical report has been saved to the patient\'s profile '
              'and the patient has been notified.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _textSecondary),
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
            child: const Text('Upload Another',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _patientIdCtrl.clear();
    _patientNameCtrl.clear();
    _labNameCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _selectedReportType = 'Blood Test';
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Upload Medical Report',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Info banner ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _deepBlue.withValues(alpha: 0.25)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: _deepBlue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Upload lab or diagnostic reports for a patient. '
                      'Reports will be instantly visible to the assigned '
                      'doctor and the patient will be notified.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF1A1A2E),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Patient Information ────────────────────────────────────────
            _sectionCard(
              title: 'Patient Information',
              icon: Icons.person_outline_rounded,
              children: [
                _field(
                  ctrl: _patientIdCtrl,
                  label: 'Patient ID',
                  hint: 'e.g. P0001',
                  icon: Icons.badge_outlined,
                  validator: _required,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                _field(
                  ctrl: _patientNameCtrl,
                  label: 'Patient Full Name',
                  hint: 'e.g. Ananya R.',
                  icon: Icons.person_rounded,
                  validator: _required,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Report Details ─────────────────────────────────────────────
            _sectionCard(
              title: 'Report Details',
              icon: Icons.description_outlined,
              children: [
                // Report type dropdown
                DropdownButtonFormField<String>(
                  value: _selectedReportType,
                  decoration: _inputDeco('Report Type',
                      icon: Icons.category_outlined),
                  items: _reportTypes
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedReportType = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  ctrl: _labNameCtrl,
                  label: 'Lab / Hospital Name',
                  hint: 'e.g. City Diagnostics',
                  icon: Icons.local_hospital_outlined,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                // Date picker
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: _deepBlue),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Report Date',
                              style: TextStyle(
                                  fontSize: 11, color: _textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_rounded,
                          size: 14, color: Colors.blueGrey),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  ctrl: _notesCtrl,
                  label: 'Notes / Remarks (optional)',
                  hint: 'Any additional notes about this report…',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── File Upload (placeholder) ──────────────────────────────────
            _sectionCard(
              title: 'Attach File (optional)',
              icon: Icons.attach_file_rounded,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'File picker integration coming soon.')),
                    );
                  },
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Choose Report File'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _deepBlue,
                    side: BorderSide(
                        color: _deepBlue.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Supported formats: PDF, JPG, PNG',
                  style: TextStyle(fontSize: 11, color: _textSecondary),
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
                  _isSaving ? 'Uploading…' : 'Submit Report',
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

  // ── Helpers ──────────────────────────────────────────────────────────────

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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
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
          borderSide: const BorderSide(color: _deepBlue, width: 1.5)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: const TextStyle(fontSize: 13),
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
      decoration: _inputDeco(label, icon: maxLines == 1 ? icon : null)
          .copyWith(hintText: hint),
      style: const TextStyle(fontSize: 13),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;
}