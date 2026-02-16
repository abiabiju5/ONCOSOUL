import 'package:flutter/material.dart';
import 'my_appointments_screen.dart';
import 'book_appointments_screen.dart';
class OnlineConsultationScreen extends StatelessWidget {
  const OnlineConsultationScreen({super.key});
final Color deepBlue = const Color(0xFF0D47A1);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Online Consultation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            consultationOption(
              icon: Icons.event_note_outlined,
              title: 'My Appointments',
              subtitle: 'View upcoming and past appointments',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyAppointmentsScreen(),
                  ),
                );
              },
            ),
            consultationOption(
              icon: Icons.add_circle_outline,
              title: 'Book Appointment',
              subtitle: 'Schedule a new consultation',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookAppointmentScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 OPTION CARD
  Widget consultationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: deepBlue.withValues(alpha:0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: deepBlue.withValues(alpha:0.15),
                ),
                child: Icon(icon, size: 26, color: deepBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: deepBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: deepBlue.withValues(alpha:0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}