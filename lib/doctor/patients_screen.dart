import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../models/patient_model.dart';
import 'medical_report_page.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Sample patient data
    final List<PatientModel> patients = [
      PatientModel(
        id: "P001",
        name: "John Smith",
        reports: [
          ReportModel(
            title: "Blood Test",
            date: "Feb 12, 2026",
            path: "",
          ),
          ReportModel(
            title: "X-Ray",
            date: "Jan 30, 2026",
            path: "",
          ),
        ],
      ),
      PatientModel(
        id: "P002",
        name: "Emily Johnson",
        reports: [
          ReportModel(
            title: "MRI Scan",
            date: "Feb 05, 2026",
            path: "",
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Patients"),
        backgroundColor: Colors.purple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(patient.name),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicalReportsPage(
                      patients: [patient],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
