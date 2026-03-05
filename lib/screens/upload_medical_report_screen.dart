import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/supabase_storage_service.dart';
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
  final _service  = DoctorService();
  final _formKey  = GlobalKey<FormState>();

  final _patientIdCtrl   = TextEditingController();
  final _patientNameCtrl = TextEditingController();
  final _labNameCtrl     = TextEditingController();
  final _notesCtrl       = TextEditingController();

  String   _selectedReportType = 'Blood Test';
  DateTime _selectedDate        = DateTime.now();
  bool     _isSaving            = false;

  PlatformFile? _pickedFile;
  double        _uploadProgress = 0.0;
  bool          _isUploading    = false;

  static const int _maxBytes = 10 * 1024 * 1024;

  static const Color _deepBlue      = Color(0xFF0D47A1);
  static const Color _lightBlue     = Color(0xFFE8F0FE);
  static const Color _textSecondary = Color(0xFF6B7280);

  static const List<String> _reportTypes = [
    'Blood Test', 'CT Scan', 'MRI Scan', 'Biopsy', 'X-Ray',
    'Ultrasound', 'PET Scan', 'Pathology Report', 'Endoscopy', 'Other',
  ];

  @override
  void dispose() {
    _patientIdCtrl.dispose();
    _patientNameCtrl.dispose();
    _labNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Pick file ─────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,         // always load bytes — needed for Cloudinary upload
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > _maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('File too large (${_fmtBytes(file.size)}). Max 10 MB.'),
        backgroundColor: Colors.orange.shade700,
      ));
      return;
    }
    setState(() => _pickedFile = file);
  }

  void _removeFile() => setState(() {
    _pickedFile     = null;
    _uploadProgress = 0.0;
    _isUploading    = false;
  });

  // ── Upload to Supabase Storage ──────────────────────────────────────────────────

  Future<String?> _uploadFile(String patientId) async {
    if (_pickedFile == null) return null;

    final bytes = _pickedFile!.bytes;
    if (bytes == null) {
      throw Exception('Cannot read file bytes. Please re-select the file.');
    }

    if (mounted) setState(() { _isUploading = true; _uploadProgress = 0.0; });

    try {
      final url = await SupabaseStorageService.uploadBytes(
        bytes:    bytes,
        folder:   'medical_reports/$patientId',
        fileName: '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}',
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 1.0; });
      return url;
    } catch (e) {
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 0.0; });
      rethrow;
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSaving = true; _uploadProgress = 0.0; });

    try {
      final patientId  = _patientIdCtrl.text.trim().toUpperCase();
      final uploadedBy = AppUserSession.currentUser?.name ?? 'Medical Staff';

      String? fileUrl;
      if (_pickedFile != null) {
        fileUrl = await _uploadFile(patientId);
      }

      await _service.uploadMedicalReport(
        patientId:   patientId,
        patientName: _patientNameCtrl.text.trim(),
        reportType:  _selectedReportType,
        labName:     _labNameCtrl.text.trim(),
        uploadedBy:  uploadedBy,
        reportDate:  _selectedDate,
        notes:       _notesCtrl.text.trim(),
        fileUrl:     fileUrl,
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload failed: $e'),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 8),
      ));
    } finally {
      if (mounted) setState(() { _isSaving = false; _isUploading = false; });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.green.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('Report Uploaded!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          const Text(
            'The medical report has been saved to the patient\'s profile '
            'and the patient has been notified.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done', style: TextStyle(color: _deepBlue)),
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
      _selectedDate       = DateTime.now();
      _pickedFile         = null;
      _uploadProgress     = 0.0;
      _isUploading        = false;
    });
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Upload Medical Report',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _deepBlue.withValues(alpha: 0.25)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: _deepBlue, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'Upload lab or diagnostic reports for a patient. '
                    'Reports will be instantly visible to the assigned doctor '
                    'and the patient will be notified.',
                    style: TextStyle(fontSize: 12.5,
                        color: Color(0xFF1A1A2E), height: 1.4),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Patient Information
            _sectionCard(
              title: 'Patient Information',
              icon: Icons.person_outline_rounded,
              children: [
                _field(ctrl: _patientIdCtrl, label: 'Patient ID',
                    hint: 'e.g. P0001', icon: Icons.badge_outlined,
                    validator: _required,
                    textCapitalization: TextCapitalization.characters),
                const SizedBox(height: 12),
                _field(ctrl: _patientNameCtrl, label: 'Patient Name',
                    hint: 'Full name as registered',
                    icon: Icons.person_outline_rounded,
                    validator: _required,
                    textCapitalization: TextCapitalization.words),
              ],
            ),
            const SizedBox(height: 16),

            // Report Details
            _sectionCard(
              title: 'Report Details',
              icon: Icons.description_outlined,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedReportType,
                  decoration: _inputDeco('Report Type',
                      icon: Icons.science_outlined),
                  items: _reportTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedReportType = v);
                  },
                ),
                const SizedBox(height: 12),
                _field(ctrl: _labNameCtrl, label: 'Lab / Hospital Name',
                    hint: 'e.g. City Diagnostics',
                    icon: Icons.local_hospital_outlined,
                    validator: _required),
                const SizedBox(height: 12),
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
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Report Date',
                            style: TextStyle(fontSize: 11,
                                color: _textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ]),
                      const Spacer(),
                      const Icon(Icons.edit_rounded,
                          size: 14, color: Colors.blueGrey),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                _field(ctrl: _notesCtrl,
                    label: 'Notes / Remarks (optional)',
                    hint: 'Any additional notes…',
                    icon: Icons.notes_rounded, maxLines: 3),
              ],
            ),
            const SizedBox(height: 16),

            // Attach File
            _sectionCard(
              title: 'Attach File (optional)',
              icon: Icons.attach_file_rounded,
              children: [
                if (_pickedFile == null) ...[
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickFile,
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
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Supported: PDF, JPG, PNG  •  Max 10 MB',
                      style: TextStyle(fontSize: 11, color: _textSecondary)),
                ] else ...[
                  // File card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white,
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(_fileIcon(_pickedFile!.extension ?? ''),
                            color: _deepBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_pickedFile!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 2),
                        Text(_fmtBytes(_pickedFile!.size),
                            style: TextStyle(fontSize: 11,
                                color: Colors.green.shade700)),
                      ])),
                      if (!_isSaving)
                        IconButton(
                          onPressed: _removeFile,
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: Colors.redAccent),
                        ),
                    ]),
                  ),

                  // Progress bar — always visible while saving
                  if (_isSaving) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_deepBlue),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isUploading
                          ? (_uploadProgress > 0
                              ? 'Uploading… ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                              : 'Uploading…')
                          : 'Saving report to database…',
                      style: const TextStyle(fontSize: 12,
                          color: _deepBlue, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload_rounded, size: 20),
                label: Text(
                  _isSaving
                      ? (_isUploading
                          ? (_uploadProgress > 0
                              ? 'Uploading… ${(_uploadProgress * 100).toInt()}%'
                              : 'Connecting…')
                          : 'Saving…')
                      : 'Submit Report',
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  IconData _fileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':  return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':  return Icons.image_rounded;
      default:     return Icons.insert_drive_file_rounded;
    }
  }

  String _fmtBytes(int b) {
    if (b < 1024)        return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _sectionCard({required String title, required IconData icon,
      required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(color: _lightBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
          child: Row(children: [
            Icon(icon, size: 18, color: _deepBlue),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: _deepBlue)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: children),
        ),
      ]),
    );
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: _textSecondary) : null,
      filled: true, fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _deepBlue, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: const TextStyle(fontSize: 13),
    );
  }

  Widget _field({required TextEditingController ctrl, required String label,
      required IconData icon, String? hint, int maxLines = 1,
      String? Function(String?)? validator,
      TextCapitalization textCapitalization = TextCapitalization.none}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines,
      validator: validator, textCapitalization: textCapitalization,
      decoration: _inputDeco(label, icon: maxLines == 1 ? icon : null)
          .copyWith(hintText: hint),
      style: const TextStyle(fontSize: 13),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;
}