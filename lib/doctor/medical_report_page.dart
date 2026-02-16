import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import 'patient_reports_page.dart';

class MedicalReportsPage extends StatelessWidget {
  final List<PatientModel> patients;

  const MedicalReportsPage({
    super.key,
    required this.patients,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patients")),
      body: patients.isEmpty
          ? const Center(child: Text("No patients available"))
          : ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(patient.name),
                    subtitle: Text("Patient ID: ${patient.id}"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientReportsPage(
                            patient: patient,
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
