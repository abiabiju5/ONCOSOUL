import 'package:flutter/material.dart';
import 'upload_consultation_summary_screen.dart';

class MedicalStaffViewAppointmentsScreen extends StatelessWidget {
  const MedicalStaffViewAppointmentsScreen({super.key});

  final Color deepBlue = const Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Appointments')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          appointmentCard(
            context: context,
            patientId: 'P1023',
            name: 'Ananya R.',
            age: '42',
            gender: 'Female',
            doctor: 'Dr. Anita Sharma',
            date: '12 Oct 2026',
            time: '10:30 AM',
          ),
        ],
      ),
    );
  }

  Widget appointmentCard({
    required BuildContext context,
    required String patientId,
    required String name,
    required String age,
    required String gender,
    required String doctor,
    required String date,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: deepBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: deepBlue)),
          Text('Patient ID: $patientId',
              style: TextStyle(color: Colors.grey.shade700)),

          const Divider(),

          infoRow('Age', age),
          infoRow('Gender', gender),
          infoRow('Doctor', doctor),
          infoRow('Date', date),
          infoRow('Time', time),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Chip(
                  label: const Text('Auto Approved'),
                  backgroundColor: Colors.green.withOpacity(0.15),
                  labelStyle: const TextStyle(color: Colors.green),
                ),
              ),
              const SizedBox(width: 8),
              // Upload Summary button
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text(
                  'Upload Summary',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const UploadConsultationSummaryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}