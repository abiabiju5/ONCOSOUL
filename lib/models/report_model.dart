class ReportModel {
  final String title;
  final String date;
  final String? path;

  ReportModel({
    required this.title,
    required this.date,
    this.path,
  });
}
