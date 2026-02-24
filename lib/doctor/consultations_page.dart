import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import 'consultation_room_page.dart';

class ConsultationsPage extends StatelessWidget {
  const ConsultationsPage({super.key});

  static const Color _deepBlue  = Color(0xFF0D47A1);
  static const Color _skyBlue   = Color(0xFF1E88E5);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _surface   = Color(0xFFF0F4FF);

  @override
  Widget build(BuildContext context) {
    final service = DoctorService();
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_deepBlue, _skyBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Online Consultations',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<DoctorAppointment>>(
        stream: service.todayPendingStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _deepBlue));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final appts = snap.data ?? [];
          if (appts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                        color: _lightBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.videocam_off_rounded,
                        size: 44, color: _deepBlue),
                  ),
                  const SizedBox(height: 18),
                  const Text('No consultations scheduled for today.',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: appts.length,
            itemBuilder: (context, index) {
              final appt = appts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _deepBlue.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left accent bar
                    Container(
                      width: 5,
                      height: 80,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_deepBlue, _skyBlue],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(16)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Avatar
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _lightBlue,
                      child: Text(
                        appt.patientName.isNotEmpty
                            ? appt.patientName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _deepBlue,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appt.patientName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF0D1B3E))),
                            const SizedBox(height: 3),
                            Text(
                              'ID: ${appt.patientId}  •  ${appt.slot}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Start button
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.videocam_rounded, size: 15),
                        label: const Text('Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _deepBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConsultationRoomPage(
                              appointmentId: appt.id,
                              patientName: appt.patientName,
                              patientId: appt.patientId,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}