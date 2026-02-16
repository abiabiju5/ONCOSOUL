import 'package:flutter/material.dart';
import '../models/appointment_rules.dart';

class MyAppointmentsScreen extends StatelessWidget {
  final Color deepBlue = const Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final appointments =
        AppointmentRules.appointments;

    return Scaffold(
      backgroundColor:
          Colors.grey.shade100,
      appBar:
          AppBar(title: const Text('My Appointments')),
      body: appointments.isEmpty
          ? const Center(
              child: Text(
                  'No appointments booked'),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.all(16),
              itemCount:
                  appointments.length,
              itemBuilder:
                  (context, index) {
                final appt =
                    appointments[index];

                return Card(
                  child: ListTile(
                    title:
                        Text(appt.doctor),
                    subtitle: Text(
                        '${appt.date} • ${appt.slot}'),
                    trailing: Text(
                      appt.status,
                      style: TextStyle(
                        color: appt
                                    .status ==
                                "Pending"
                            ? Colors.orange
                            : appt.status ==
                                    "Completed"
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}