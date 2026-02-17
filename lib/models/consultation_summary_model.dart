class ConsultationSummaryModel {
  final String patientId;
  final String patientName;
  final String date;
  final String time;
  final String doctorName;
  final String chiefComplaint;
  final String clinicalFindings;
  final String diagnosis;
  final String treatmentGiven;
  final String nurseNotes;
  final String uploadedBy; // nurse/medical staff name
  final DateTime uploadedAt;

  ConsultationSummaryModel({
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.time,
    required this.doctorName,
    required this.chiefComplaint,
    required this.clinicalFindings,
    required this.diagnosis,
    required this.treatmentGiven,
    required this.nurseNotes,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  Map<String, String> toSummaryMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'date': date,
      'time': time,
      'doctorName': doctorName,
      'chiefComplaint': chiefComplaint,
      'clinicalFindings': clinicalFindings,
      'diagnosis': diagnosis,
      'treatmentGiven': treatmentGiven,
      'nurseNotes': nurseNotes,
      'uploadedBy': uploadedBy,
    };
  }
}