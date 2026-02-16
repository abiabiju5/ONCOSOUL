import 'package:flutter/material.dart';
import 'consultation_details_page.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String patientName;
  final String date;
  final String time;
  final String status;

  const AppointmentDetailsPage({
    super.key,
    required this.patientName,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  State<AppointmentDetailsPage> createState() =>
      _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  late String currentStatus;
  late String currentDate;
  late String currentTime;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.status;
    currentDate = widget.date;
    currentTime = widget.time;
  }

  /// 📅 Pick new date
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        currentDate = '${picked.day}/${picked.month}/${picked.year}';
        currentStatus = 'Upcoming';
      });
    }
  }

  /// ⏰ Pick new time
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        currentTime = picked.format(context);
        currentStatus = 'Upcoming';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info
            Text(
              widget.patientName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text('$currentDate • $currentTime'),
            const SizedBox(height: 6),
            Text(
              'Status: $currentStatus',
              style: TextStyle(
                color: currentStatus == 'Completed'
                    ? Colors.green
                    : currentStatus == 'Cancelled'
                        ? Colors.red
                        : Colors.orange,
              ),
            ),

            const SizedBox(height: 20),

            // Status Update Dropdown
            DropdownButtonFormField<String>(
              initialValue: currentStatus,
              decoration: const InputDecoration(
                labelText: 'Update Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Upcoming',
                  child: Text('Upcoming'),
                ),
                DropdownMenuItem(
                  value: 'Completed',
                  child: Text('Completed'),
                ),
                DropdownMenuItem(
                  value: 'Cancelled',
                  child: Text('Cancelled'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  currentStatus = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            // Reschedule Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: pickDate,
                    child: const Text('Change Date'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: pickTime,
                    child: const Text('Change Time'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Go to Consultation Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: currentStatus == 'Upcoming'
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConsultationDetailsPage(
                              patientName: widget.patientName,
                              date: currentDate,
                              time: currentTime,
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text('Go to Consultation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
