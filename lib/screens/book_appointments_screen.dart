import 'package:flutter/material.dart';
import '../models/appointment_rules.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState
    extends State<BookAppointmentScreen> {
  final Color deepBlue = const Color(0xFF0D47A1);

  DateTime selectedDate = DateTime.now();
  String? selectedSlot;
  String? selectedDoctor;

  final List<String> doctors = [
    'Dr. Anita Sharma',
    'Dr. Rahul Verma'
  ];

  List<String> generateSlots() {
    List<String> slots = [];

    DateTime current = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      AppointmentRules.startTime.hour,
      AppointmentRules.startTime.minute,
    );

    DateTime end = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      AppointmentRules.endTime.hour,
      AppointmentRules.endTime.minute,
    );

    DateTime breakStartDT = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      AppointmentRules.breakStart.hour,
      AppointmentRules.breakStart.minute,
    );

    DateTime breakEndDT = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      AppointmentRules.breakEnd.hour,
      AppointmentRules.breakEnd.minute,
    );

    while (current.isBefore(end)) {
      if (!(current.isAfter(
              breakStartDT.subtract(
                  const Duration(minutes: 1))) &&
          current.isBefore(breakEndDT))) {
        slots.add(
          TimeOfDay.fromDateTime(current)
              .format(context),
        );
      }

      current = current.add(Duration(
          minutes:
              AppointmentRules.slotDuration));
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final slots = generateSlots();

    return Scaffold(
      backgroundColor:
          Colors.grey.shade100,
      appBar: AppBar(
        title:
            const Text('Book Appointment'),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            DropdownButtonFormField<String>(
              value: selectedDoctor,
              decoration:
                  const InputDecoration(
                labelText: 'Select Doctor',
                filled: true,
              ),
              items: doctors
                  .map(
                    (doc) =>
                        DropdownMenuItem(
                      value: doc,
                      child: Text(doc),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDoctor =
                      value;
                  selectedSlot = null;
                });
              },
            ),

            const SizedBox(height: 20),

            Expanded(
              child:
                  selectedDoctor ==
                          null
                      ? const Center(
                          child: Text(
                              'Select a doctor first'),
                        )
                      : buildSlots(
                          slots),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      deepBlue,
                ),
                onPressed:
                    confirmBooking,
                child: const Text(
                  'Confirm Appointment',
                  style: TextStyle(
                      color:
                          Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSlots(
      List<String> slots) {
    final dateKey =
        "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    AppointmentRules.bookedSlots
        .putIfAbsent(
            selectedDoctor!,
            () => {});

    AppointmentRules
        .bookedSlots[
            selectedDoctor!]!
        .putIfAbsent(
            dateKey,
            () => []);

    final bookedForDoctor =
        AppointmentRules
                .bookedSlots[
            selectedDoctor!]![
        dateKey]!;

    return GridView.builder(
      itemCount: slots.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemBuilder:
          (context, index) {
        final slot =
            slots[index];
        final isBooked =
            bookedForDoctor
                .contains(slot);
        final isSelected =
            selectedSlot ==
                slot;

        return GestureDetector(
          onTap: isBooked
              ? null
              : () {
                  setState(() {
                    selectedSlot =
                        slot;
                  });
                },
          child: Container(
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color: isBooked
                  ? Colors
                      .grey
                      .shade400
                  : isSelected
                      ? deepBlue
                      : Colors
                          .white,
              borderRadius:
                  BorderRadius
                      .circular(
                          8),
              border:
                  Border.all(
                color: deepBlue
                    .withOpacity(
                        0.3),
              ),
            ),
            child: Text(
              slot,
              style: TextStyle(
                color: isBooked
                    ? Colors.white
                    : isSelected
                        ? Colors.white
                        : Colors.black,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void confirmBooking() {
    if (selectedDoctor ==
            null ||
        selectedSlot ==
            null) {
      ScaffoldMessenger.of(
              context)
          .showSnackBar(
        const SnackBar(
          content: Text(
              'Select doctor and slot'),
        ),
      );
      return;
    }

    final dateKey =
        "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    final bookedForDoctor =
        AppointmentRules
                .bookedSlots[
            selectedDoctor!]![
        dateKey]!;

    if (bookedForDoctor.length >=
        AppointmentRules
            .maxPatientsPerDay) {
      ScaffoldMessenger.of(
              context)
          .showSnackBar(
        const SnackBar(
          content: Text(
              'Daily limit reached'),
        ),
      );
      return;
    }

    bookedForDoctor
        .add(selectedSlot!);

    AppointmentRules.appointments
        .add(
      Appointment(
        doctor: selectedDoctor!,
        date: dateKey,
        slot: selectedSlot!,
      ),
    );

    ScaffoldMessenger.of(
            context)
        .showSnackBar(
      SnackBar(
        content: Text(
            'Booked with $selectedDoctor at $selectedSlot'),
      ),
    );

    setState(() {
      selectedSlot =
          null;
    });
  }
}