import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import 'medical_report_page.dart';

class ConsultationDetailsPage extends StatelessWidget {
  final String patientName;
  final String date;
  final String time;

  const ConsultationDetailsPage({
    super.key,
    required this.patientName,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info
            Text(
              patientName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$date • $time',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Start Consultation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.video_call),
                label: const Text('Start Video Consultation'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video consultation started'),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Notes section
            const Text(
              'Doctor Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Patient symptoms and observations will be noted here.',
                style: TextStyle(color: Colors.black87),
              ),
            ),

            const Spacer(),

            // View reports
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.description),
                label: const Text('View Medical Reports'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicalReportsPage(
                        patients: [
                          PatientModel(
                            id: "TEMP",
                            name: patientName,
                            reports: [],
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
    );
  }
}
