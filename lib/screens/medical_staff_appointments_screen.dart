import 'package:flutter/material.dart';
import '../models/appointment_rules.dart';

class MedicalStaffAppointmentsScreen
    extends StatefulWidget {
  const MedicalStaffAppointmentsScreen(
      {super.key});

  @override
  State<MedicalStaffAppointmentsScreen>
      createState() =>
          _MedicalStaffAppointmentsScreenState();
}

class _MedicalStaffAppointmentsScreenState
    extends State<
        MedicalStaffAppointmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final appointments =
        AppointmentRules.appointments;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Manage Appointments'),
      ),
      body: ListView.builder(
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
              title: Text(
                  appt.doctor),
              subtitle: Text(
                  '${appt.date} • ${appt.slot}'),
              trailing:
                  DropdownButton<String>(
                value: appt.status,
                items: const [
                  DropdownMenuItem(
                      value:
                          "Pending",
                      child:
                          Text("Pending")),
                  DropdownMenuItem(
                      value:
                          "Completed",
                      child:
                          Text(
                              "Completed")),
                  DropdownMenuItem(
                      value:
                          "Cancelled",
                      child:
                          Text(
                              "Cancelled")),
                ],
                onChanged:
                    (value) {
                  setState(() {
                    appt.status =
                        value!;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}