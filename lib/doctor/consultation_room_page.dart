import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../models/patient_model.dart';
import '../models/consultation_summary_model.dart';
import '../models/consultation_summary_store.dart';
import '../services/prescription_pdf_service.dart';
import 'medical_report_page.dart';

class ConsultationRoomPage extends StatefulWidget {
  final String patientName;
  final String patientId;
  final List<ReportModel> reports;
  final List<String> medicalHistory;

  const ConsultationRoomPage({
    super.key,
    required this.patientName,
    required this.patientId,
    required this.reports,
    required this.medicalHistory,
  });

  @override
  State<ConsultationRoomPage> createState() => _ConsultationRoomPageState();
}

class _ConsultationRoomPageState extends State<ConsultationRoomPage>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late TextEditingController remarksController;
  final TextEditingController medicineController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  List<Map<String, String>> prescriptions = [];
  List<String> history = [];
  List<ConsultationSummaryModel> offlineSummaries = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isSavingPdf = false;
  bool _notesExpanded = true;
  bool _historyExpanded = true;
  bool _prescriptionExpanded = true;
  bool _offlineSummariesExpanded = true;

  // ── Theme ─────────────────────────────────────────────────────────────────
  static const Color _primaryGreen = Color(0xFF1B8A5A);
  static const Color _lightGreen = Color(0xFFE8F5EE);
  static const Color _warmWhite = Color(0xFFFAFAFA);
  static const Color _cardShadow = Color(0x14000000);
  static const Color _dividerColor = Color(0xFFE0E0E0);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _deepBlue = Color(0xFF0D47A1);

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    remarksController = TextEditingController();
    history = List<String>.from(widget.medicalHistory);
    offlineSummaries = ConsultationSummaryStore.getSummaries(widget.patientId);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    remarksController.dispose();
    medicineController.dispose();
    dosageController.dispose();
    durationController.dispose();
    instructionsController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _addMedicine() {
    if (medicineController.text.trim().isEmpty ||
        dosageController.text.trim().isEmpty ||
        durationController.text.trim().isEmpty) {
      _showSnackbar('Please fill in all medicine fields.', isError: true);
      return;
    }
    setState(() {
      prescriptions.add({
        'medicine': medicineController.text.trim(),
        'dosage': dosageController.text.trim(),
        'duration': durationController.text.trim(),
        'instructions': instructionsController.text.trim(),
      });
      medicineController.clear();
      dosageController.clear();
      durationController.clear();
      instructionsController.clear();
    });
    _showSnackbar('Medicine added to prescription.');
  }

  void _removeMedicine(int index) =>
      setState(() => prescriptions.removeAt(index));

  Future<void> _savePrescription() async {
    if (prescriptions.isEmpty) {
      _showSnackbar('No prescriptions to save.', isError: true);
      return;
    }
    setState(() => _isSavingPdf = true);
    try {
      final file = await PrescriptionPdfService.generatePrescriptionPdf(
        patientName: widget.patientName,
        doctorName: 'Dr. John Doe',
        medicines: prescriptions,
      );
      await PrescriptionPdfService.printPdf(file);
      _showSnackbar('Prescription PDF generated successfully!');
    } catch (_) {
      _showSnackbar('Failed to generate PDF. Please try again.', isError: true);
    } finally {
      setState(() => _isSavingPdf = false);
    }
  }

  void _saveDoctorRemarks() {
    if (remarksController.text.trim().isEmpty) {
      _showSnackbar('Please enter some notes.', isError: true);
      return;
    }
    _showSnackbar('Doctor notes saved successfully!');
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        title: Text('Consulting ${widget.patientName}'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Video Consultation ─────────────────────────────────────────
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                      'Video Consultation', Icons.videocam_rounded, _primaryGreen),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryGreen, width: 2),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_rounded,
                              size: 60, color: Colors.white70),
                          SizedBox(height: 10),
                          Text(
                            'Video call in progress',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.description_rounded, size: 18),
                      label: const Text(
                        'View Medical Reports',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryGreen,
                        side: const BorderSide(color: _primaryGreen, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicalReportsPage(
                              patients: [
                                PatientModel(
                                  id: widget.patientId,
                                  name: widget.patientName,
                                  reports: widget.reports,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Medical History ────────────────────────────────────────────
            _buildExpandableCard(
              title: 'Medical History',
              icon: Icons.history_rounded,
              iconColor: const Color(0xFF8B5CF6),
              isExpanded: _historyExpanded,
              onToggle: () =>
                  setState(() => _historyExpanded = !_historyExpanded),
              child: history.isEmpty
                  ? const Text(
                      'No medical history available.',
                      style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: history
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.fiber_manual_record,
                                      size: 8, color: _textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(entry,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: _textPrimary)),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),

            // ── Offline Consultation Summaries ─────────────────────────────
            _buildExpandableCard(
              title: 'Consultation Summaries',
              icon: Icons.assignment_ind_rounded,
              iconColor: _deepBlue,
              isExpanded: _offlineSummariesExpanded,
              onToggle: () => setState(
                  () => _offlineSummariesExpanded = !_offlineSummariesExpanded),
              child: offlineSummaries.isEmpty
                  ? const Text(
                      'No offline consultation summaries uploaded by medical staff yet.',
                      style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: offlineSummaries
                          .map((s) => _buildOfflineSummaryCard(s))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),

            // ── Prescription ───────────────────────────────────────────────
            _buildExpandableCard(
              title: 'Prescription',
              icon: Icons.medication_rounded,
              iconColor: const Color(0xFFEF4444),
              isExpanded: _prescriptionExpanded,
              onToggle: () => setState(
                  () => _prescriptionExpanded = !_prescriptionExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add medicine form
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _primaryGreen.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Medicine',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _textPrimary),
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                            controller: medicineController,
                            label: 'Medicine Name'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _inputField(
                                  controller: dosageController,
                                  label: 'Dosage'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _inputField(
                                  controller: durationController,
                                  label: 'Duration'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                            controller: instructionsController,
                            label: 'Instructions (Optional)'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Add to Prescription',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryGreen,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _addMedicine,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Prescription list
                  if (prescriptions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No medicines added yet.',
                        style: TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                            fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    Column(
                      children: prescriptions
                          .asMap()
                          .entries
                          .map((e) => _buildPrescriptionItem(e.key, e.value))
                          .toList(),
                    ),

                  // Save PDF button
                  if (prescriptions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSavingPdf
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white)),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          _isSavingPdf
                              ? 'Generating PDF...'
                              : 'Save & Download PDF',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSavingPdf ? null : _savePrescription,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Doctor's Notes ─────────────────────────────────────────────
            _buildExpandableCard(
              title: "Doctor's Notes",
              icon: Icons.notes_rounded,
              iconColor: const Color(0xFFF59E0B),
              isExpanded: _notesExpanded,
              onToggle: () =>
                  setState(() => _notesExpanded = !_notesExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: remarksController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      hintText: 'Add notes, observations, or remarks...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text(
                        'Save Notes',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _saveDoctorRemarks,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── End Consultation ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone_disabled_rounded, size: 18),
                label: const Text(
                  'End Consultation',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _inputField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildPrescriptionItem(int index, Map<String, String> medicine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medication_rounded,
                color: Color(0xFFEF4444), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine['medicine'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medicine['dosage']} • ${medicine['duration']}',
                  style:
                      const TextStyle(fontSize: 12, color: _textSecondary),
                ),
                if (medicine['instructions']?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      medicine['instructions']!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFDC2626)),
            onPressed: () => _removeMedicine(index),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: _cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }

  Widget _buildExpandableCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: _cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _textPrimary),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: _dividerColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
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
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _textPrimary),
        ),
      ],
    );
  }

  // ── Offline Summary Card ──────────────────────────────────────────────────

  Widget _buildOfflineSummaryCard(ConsultationSummaryModel summary) {
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
          // Header strip
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
                    '${summary.date}  •  ${summary.time}',
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
                  child: const Text(
                    'Offline Visit',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _deepBlue),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow(Icons.medical_services_outlined, 'Doctor',
                    summary.doctorName),
                const Divider(height: 16),
                _summaryRow(Icons.report_problem_outlined,
                    'Chief Complaint', summary.chiefComplaint),
                const SizedBox(height: 10),
                _summaryRow(Icons.biotech_outlined, 'Clinical Findings',
                    summary.clinicalFindings),
                const SizedBox(height: 10),
                _summaryRow(Icons.health_and_safety_outlined, 'Diagnosis',
                    summary.diagnosis),
                const SizedBox(height: 10),
                _summaryRow(Icons.medication_outlined, 'Treatment Given',
                    summary.treatmentGiven),

                if (summary.nurseNotes.isNotEmpty) ...[
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
                              const Text(
                                'Nurse Notes',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _deepBlue),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                summary.nurseNotes,
                                style: const TextStyle(
                                    fontSize: 12, color: _textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 13, color: _textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Uploaded by ${summary.uploadedBy}',
                      style: const TextStyle(
                          fontSize: 11, color: _textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: _textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}