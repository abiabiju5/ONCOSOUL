import 'package:flutter/material.dart';

class PatientDetailsPage extends StatelessWidget {
  final Map<String, String> patient;
  const PatientDetailsPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Basic Info
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      child: Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient["name"] ?? "Unknown",
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text("Age: ${patient["age"] ?? 'N/A'}"),
                          Text("Blood Group: ${patient["bloodGroup"] ?? 'N/A'}"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Diagnosis Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Diagnosis",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Divider(thickness: 1, height: 16),
                    Text(patient["diagnosis"] ?? "N/A"),
                  ],
                ),
              ),
            ),

            // Allergies & Medications
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Allergies & Medications",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Divider(thickness: 1, height: 16),
                    Text("Allergies: ${patient["allergies"] ?? 'None'}"),
                    Text("Medications: ${patient["medications"] ?? 'None'}"),
                  ],
                ),
              ),
            ),

            // Notes / History
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Medical History / Notes",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Divider(thickness: 1, height: 16),
                    Text(patient["notes"] ?? "No history available"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example usage in PatientsPage
class PatientsPage extends StatelessWidget {
  PatientsPage({super.key});

  final List<Map<String, String>> patients = [
    {
      "name": "John Doe",
      "age": "45",
      "bloodGroup": "A+",
      "diagnosis": "Lung Cancer",
      "allergies": "Penicillin",
      "medications": "Aspirin",
      "notes": "Patient is stable and responding to treatment",
    },
    {
      "name": "Jane Smith",
      "age": "38",
      "bloodGroup": "B+",
      "diagnosis": "Breast Cancer",
      "allergies": "None",
      "medications": "Metformin",
      "notes": "Patient requires regular follow-up",
    },
    {
      "name": "Michael Brown",
      "age": "52",
      "bloodGroup": "O-",
      "diagnosis": "Leukemia",
      "allergies": "None",
      "medications": "Chemotherapy",
      "notes": "Patient under observation",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patients")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(patient["name"]!),
              subtitle: Text(
                "Age: ${patient["age"]} | Diagnosis: ${patient["diagnosis"]}",
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PatientDetailsPage(patient: patient),
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