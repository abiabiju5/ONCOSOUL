import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import 'consultation_room_page.dart';

class ConsultationsPage extends StatelessWidget {
  const ConsultationsPage({super.key});

  static const Color _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final service = DoctorService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Consultations'),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DoctorAppointment>>(
        stream: service.todayPendingStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final appts = snap.data ?? [];
          if (appts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off_rounded, size: 56, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No consultations scheduled for today.',
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final appt = appts[index];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: _blue.withValues(alpha: 0.12),
                    child: Text(
                      appt.patientName.isNotEmpty
                          ? appt.patientName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: _blue),
                    ),
                  ),
                  title: Text(appt.patientName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Patient ID: ${appt.patientId}  •  ${appt.slot}'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.videocam_rounded, size: 16),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConsultationRoomPage(
                            appointmentId: appt.id,
                            patientName: appt.patientName,
                            patientId: appt.patientId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}