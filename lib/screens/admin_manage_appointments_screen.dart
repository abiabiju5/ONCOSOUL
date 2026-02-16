import 'package:flutter/material.dart';
import '../models/appointment_rules.dart';

class AdminManageAppointmentsScreen extends StatefulWidget {
  const AdminManageAppointmentsScreen({super.key});

  @override
  State<AdminManageAppointmentsScreen> createState() =>
      _AdminManageAppointmentsScreenState();
}

class _AdminManageAppointmentsScreenState
    extends State<AdminManageAppointmentsScreen> {
  final Color deepBlue = const Color(0xFF0D47A1);

  late TimeOfDay startTime;
  late TimeOfDay endTime;
  late TimeOfDay breakStart;
  late TimeOfDay breakEnd;
  late int slotDuration;
  late int maxPatientsPerDay;

  @override
  void initState() {
    super.initState();

    startTime = AppointmentRules.startTime;
    endTime = AppointmentRules.endTime;
    breakStart = AppointmentRules.breakStart;
    breakEnd = AppointmentRules.breakEnd;
    slotDuration = AppointmentRules.slotDuration;
    maxPatientsPerDay =
        AppointmentRules.maxPatientsPerDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Manage Appointment Rules'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [

            sectionTitle('Working Hours'),
            timeTile('Start Time', startTime,
                (picked) => setState(() => startTime = picked)),
            timeTile('End Time', endTime,
                (picked) => setState(() => endTime = picked)),

            const SizedBox(height: 20),

            sectionTitle('Break Time'),
            timeTile('Break Start', breakStart,
                (picked) => setState(() => breakStart = picked)),
            timeTile('Break End', breakEnd,
                (picked) => setState(() => breakEnd = picked)),

            const SizedBox(height: 20),

            sectionTitle('Slot Duration (minutes)'),
            DropdownButtonFormField<int>(
              value: slotDuration,
              items: const [
                DropdownMenuItem(
                    value: 15, child: Text('15 Minutes')),
                DropdownMenuItem(
                    value: 20, child: Text('20 Minutes')),
                DropdownMenuItem(
                    value: 30, child: Text('30 Minutes')),
              ],
              onChanged: (value) {
                setState(() {
                  slotDuration = value!;
                });
              },
              decoration: inputDecoration(),
            ),

            const SizedBox(height: 20),

            sectionTitle('Max Patients Per Day'),
            TextField(
              keyboardType: TextInputType.number,
              decoration: inputDecoration(
                  hint: maxPatientsPerDay.toString()),
              onChanged: (value) {
                maxPatientsPerDay =
                    int.tryParse(value) ??
                        maxPatientsPerDay;
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepBlue,
                  padding:
                      const EdgeInsets.all(14),
                ),
                onPressed: () {
                  AppointmentRules.startTime =
                      startTime;
                  AppointmentRules.endTime = endTime;
                  AppointmentRules.breakStart =
                      breakStart;
                  AppointmentRules.breakEnd =
                      breakEnd;
                  AppointmentRules.slotDuration =
                      slotDuration;
                  AppointmentRules
                          .maxPatientsPerDay =
                      maxPatientsPerDay;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Appointment rules updated'),
                    ),
                  );
                },
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight:
              FontWeight.w600,
          color: deepBlue,
        ),
      ),
    );
  }

  Widget timeTile(
      String label,
      TimeOfDay time,
      Function(TimeOfDay) onPicked) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(
        time.format(context),
        style: const TextStyle(
            fontWeight:
                FontWeight.w600),
      ),
      onTap: () async {
        final picked =
            await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) {
          onPicked(picked);
        }
      },
    );
  }

  InputDecoration inputDecoration(
      {String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
    );
  }
}