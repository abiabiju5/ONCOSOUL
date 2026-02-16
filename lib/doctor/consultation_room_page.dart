import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/report_model.dart';
import '../models/patient_model.dart';
import '../services/prescription_pdf_service.dart';
import 'medical_report_page.dart';

class ConsultationRoomPage extends StatefulWidget {
  final String patientName;
  final List<ReportModel> reports;
  final List<Map<String, String>> prescription;
  final List<String> consultationHistory;
  final String doctorRemarks;

  const ConsultationRoomPage({
    super.key,
    required this.patientName,
    required this.reports,
    required this.prescription,
    required this.consultationHistory,
    required this.doctorRemarks,
  });

  @override
  State<ConsultationRoomPage> createState() => _ConsultationRoomPageState();
}

class _ConsultationRoomPageState extends State<ConsultationRoomPage>
    with TickerProviderStateMixin {
  late TextEditingController remarksController;
  final TextEditingController medicineController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();

  List<Map<String, String>> prescriptions = [];
  List<String> medicalHistory = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isSavingPdf = false;
  bool _notesExpanded = true;
  bool _historyExpanded = true;
  bool _prescriptionExpanded = true;
  bool _previousConsultationsExpanded = true;

  // Theme colors - matching patient_details_page
  static const Color _primaryGreen = Color(0xFF1B8A5A);
  static const Color _lightGreen = Color(0xFFE8F5EE);
  // static const Color _accentTeal = Color(0xFF00897B); // Unused
  static const Color _warmWhite = Color(0xFFFAFAFA);
  static const Color _cardShadow = Color(0x14000000);
  static const Color _dividerColor = Color(0xFFE0E0E0);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    remarksController = TextEditingController(text: widget.doctorRemarks);

    // Initialize prescription from widget
    if (widget.prescription.isNotEmpty) {
      prescriptions = List<Map<String, String>>.from(widget.prescription);
    }

    // Initialize medical history
    medicalHistory = List<String>.from(widget.consultationHistory);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
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

  void addMedicine() {
    if (medicineController.text.trim().isEmpty ||
        dosageController.text.trim().isEmpty ||
        durationController.text.trim().isEmpty) {
      _showSnackbar("Please fill in all medicine fields.", isError: true);
      return;
    }

    setState(() {
      prescriptions.add({
        "medicine": medicineController.text.trim(),
        "dosage": dosageController.text.trim(),
        "duration": durationController.text.trim(),
        "instructions": instructionsController.text.trim(),
      });

      medicineController.clear();
      dosageController.clear();
      durationController.clear();
      instructionsController.clear();
    });

    _showSnackbar("Medicine added to prescription.");
  }

  void removeMedicine(int index) {
    setState(() {
      prescriptions.removeAt(index);
    });
  }

  Future<void> savePrescription() async {
    if (prescriptions.isEmpty) {
      _showSnackbar("No prescriptions to save.", isError: true);
      return;
    }

    setState(() => _isSavingPdf = true);

    try {
      final file = await PrescriptionPdfService.generatePrescriptionPdf(
        patientName: widget.patientName,
        doctorName: "Dr. John Doe",
        medicines: prescriptions,
      );

      await PrescriptionPdfService.printPdf(file);

      _showSnackbar("Prescription PDF generated successfully!");
    } catch (e) {
      _showSnackbar("Failed to generate PDF. Please try again.", isError: true);
    } finally {
      setState(() => _isSavingPdf = false);
    }
  }

  void saveDoctorRemarks() {
    final updatedRemarks = remarksController.text;

    if (updatedRemarks.trim().isEmpty) {
      _showSnackbar("Please enter some notes.", isError: true);
      return;
    }

    _showSnackbar("Doctor notes saved successfully!");
    // Debug: Saved Doctor Notes: $updatedRemarks
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
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmWhite,
      appBar: AppBar(
        title: Text("Consulting ${widget.patientName}"),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Video Consultation Card
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    'Video Consultation',
                    Icons.videocam_rounded,
                    _primaryGreen,
                  ),
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
                          Icon(
                            Icons.videocam_rounded,
                            size: 60,
                            color: Colors.white70,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Video call in progress',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
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
                        "View Medical Reports",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryGreen,
                        side: const BorderSide(color: _primaryGreen, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicalReportsPage(
                              patients: [
                                PatientModel(
                                  id: "P001",
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

            // Medical History Section
            _buildExpandableCard(
              title: 'Medical History',
              icon: Icons.history_rounded,
              iconColor: const Color(0xFF8B5CF6),
              isExpanded: _historyExpanded,
              onToggle: () => setState(() => _historyExpanded = !_historyExpanded),
              child: medicalHistory.isEmpty
                  ? const Text(
                      'No medical history available.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: medicalHistory
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.fiber_manual_record,
                                    size: 8,
                                    color: _textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),

            // Previous Consultations Section
            _buildExpandableCard(
              title: 'Previous Consultations',
              icon: Icons.folder_shared_rounded,
              iconColor: const Color(0xFF10B981),
              isExpanded: _previousConsultationsExpanded,
              onToggle: () => setState(() => _previousConsultationsExpanded = !_previousConsultationsExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Previous Prescriptions
                  if (widget.prescription.isNotEmpty) ...[
                    const Text(
                      'Previous Prescriptions',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...widget.prescription.map((medicine) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _lightGreen,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _primaryGreen.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.medication_rounded,
                                color: _primaryGreen,
                                size: 20,
                              ),
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
                                      color: _textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${medicine['dosage']} • ${medicine['duration']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _textSecondary,
                                    ),
                                  ),
                                  if (medicine['instructions']?.isNotEmpty ?? false)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        medicine['instructions']!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  
                  // Previous Doctor Remarks
                  if (widget.doctorRemarks.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Previous Doctor Remarks',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.doctorRemarks,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (widget.prescription.isEmpty && widget.doctorRemarks.isEmpty)
                    const Text(
                      'No previous consultation details available.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Prescription Section
            _buildExpandableCard(
              title: 'Prescription',
              icon: Icons.medication_rounded,
              iconColor: const Color(0xFFEF4444),
              isExpanded: _prescriptionExpanded,
              onToggle: () =>
                  setState(() => _prescriptionExpanded = !_prescriptionExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Medicine Form
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _primaryGreen.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Medicine',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: medicineController,
                          decoration: InputDecoration(
                            labelText: "Medicine Name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: dosageController,
                                decoration: InputDecoration(
                                  labelText: "Dosage",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: durationController,
                                decoration: InputDecoration(
                                  labelText: "Duration",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: instructionsController,
                          decoration: InputDecoration(
                            labelText: "Instructions (Optional)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              "Add to Prescription",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: addMedicine,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Prescription List
                  if (prescriptions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No medicines added yet.',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: prescriptions.asMap().entries.map((entry) {
                        int index = entry.key;
                        var medicine = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.medication_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
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
                                        color: _textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${medicine['dosage']} • ${medicine['duration']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _textSecondary,
                                      ),
                                    ),
                                    if (medicine['instructions']?.isNotEmpty ?? false)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          medicine['instructions']!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFDC2626),
                                ),
                                onPressed: () => removeMedicine(index),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  
                  // Save Prescription Button
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
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          _isSavingPdf
                              ? "Generating PDF..."
                              : "Save & Download PDF",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isSavingPdf ? null : savePrescription,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Doctor Notes Section
            _buildExpandableCard(
              title: "Doctor's Notes",
              icon: Icons.notes_rounded,
              iconColor: const Color(0xFFF59E0B),
              isExpanded: _notesExpanded,
              onToggle: () => setState(() => _notesExpanded = !_notesExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: remarksController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: "Add notes, observations, or remarks...",
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
                        "Save Notes",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: saveDoctorRemarks,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // End Consultation Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone_disabled_rounded, size: 18),
                label: const Text(
                  "End Consultation",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

  // ─── Helper Widgets ──────────────────────────────────────────────────────

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: _cardShadow, blurRadius: 8, offset: Offset(0, 2)),
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
          BoxShadow(color: _cardShadow, blurRadius: 8, offset: Offset(0, 2)),
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
                        color: _textPrimary,
                      ),
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
            color: _textPrimary,
          ),
        ),
      ],
    );
  }
}