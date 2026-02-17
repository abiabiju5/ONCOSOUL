import 'consultation_summary_model.dart';

/// Shared in-memory store for offline consultation summaries.
/// Medical staff upload summaries here; doctors read from it
/// during online consultations.
class ConsultationSummaryStore {
  ConsultationSummaryStore._();

  // Keyed by patientId for O(1) lookup
  static final Map<String, List<ConsultationSummaryModel>> _store = {
    // Seed data — mirrors the patient names used in consultations_page.dart
    'P001': [
      ConsultationSummaryModel(
        patientId: 'P001',
        patientName: 'Patient 1',
        date: 'Jan 10, 2026',
        time: '10:00 AM',
        doctorName: 'Dr. John Doe',
        chiefComplaint: 'Persistent cough and mild fever for 5 days',
        clinicalFindings:
            'Temperature 38.2°C, throat mildly inflamed, lungs clear on auscultation',
        diagnosis: 'Viral Upper Respiratory Tract Infection',
        treatmentGiven: 'Paracetamol 500mg, Steam inhalation advised',
        nurseNotes: 'Patient appeared fatigued. Vitals stable. Advised rest.',
        uploadedBy: 'Nurse Priya',
        uploadedAt: DateTime(2026, 1, 10, 11, 30),
      ),
    ],
    'P002': [
      ConsultationSummaryModel(
        patientId: 'P002',
        patientName: 'Patient 2',
        date: 'Feb 01, 2026',
        time: '02:30 PM',
        doctorName: 'Dr. John Doe',
        chiefComplaint: 'Routine follow-up after chemotherapy cycle 3',
        clinicalFindings:
            'BP 122/80, no new complaints, mild nausea reported',
        diagnosis: 'Stage II Breast Cancer – stable post chemo',
        treatmentGiven: 'Anti-nausea medication administered',
        nurseNotes:
            'Patient tolerating treatment well. Weight unchanged. Next cycle in 3 weeks.',
        uploadedBy: 'Nurse Meena',
        uploadedAt: DateTime(2026, 2, 1, 15, 0),
      ),
    ],
  };

  /// Returns all offline summaries for a patient (newest first).
  static List<ConsultationSummaryModel> getSummaries(String patientId) {
    final list = _store[patientId] ?? [];
    return List.from(list.reversed);
  }

  /// Adds a new offline consultation summary.
  static void addSummary(ConsultationSummaryModel summary) {
    _store.putIfAbsent(summary.patientId, () => []);
    _store[summary.patientId]!.add(summary);
  }

  /// Returns all patient IDs that have at least one summary.
  static List<String> get allPatientIds => _store.keys.toList();
}