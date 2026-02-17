import 'package:flutter/material.dart';
import '../models/report_model.dart';
import 'consultation_room_page.dart';

class ConsultationsPage extends StatelessWidget {
  const ConsultationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultations')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          final reports = [
            ReportModel(title: 'Blood Test Report', date: 'Feb 10, 2026'),
            ReportModel(title: 'CT Scan Report', date: 'Jan 25, 2026'),
          ];

          return Card(
            child: ListTile(
              title: Text('Patient ${index + 1}'),
              subtitle: const Text('Tap to start consultation'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConsultationRoomPage(
                      patientName: 'Patient ${index + 1}',
                      patientId: 'P00${index + 1}',
                      reports: reports,
                      medicalHistory: [
                        'Visited on Jan 10, 2026 - Fever',
                        'Visited on Feb 1, 2026 - Checkup',
                      ],
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