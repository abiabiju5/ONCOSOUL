import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import 'medical_report_details_page.dart';

class PatientReportsPage extends StatelessWidget {
  final PatientModel patient;

  const PatientReportsPage({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${patient.name}'s Reports"),
      ),
      body: patient.reports.isEmpty
          ? const Center(child: Text("No reports available"))
          : ListView.builder(
              itemCount: patient.reports.length,
              itemBuilder: (context, index) {
                final report = patient.reports[index];

                return ListTile(
                  title: Text(report.title),
                  subtitle: Text(report.date),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MedicalReportDetailsPage(report: report),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
