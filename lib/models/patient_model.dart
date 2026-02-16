import 'report_model.dart';

class PatientModel {
  final String id;
  final String name;
  final List<ReportModel> reports;

  PatientModel({
    required this.id,
    required this.name,
    required this.reports,
  });
}
