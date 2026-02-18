import 'package:flutter/material.dart';
import '../models/appointment_rules.dart';
import '../services/notification_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const Color deepBlue = Color(0xFF0D47A1);
  static const Color midBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF0F4FC);

  DateTime selectedDate = DateTime.now();
  String? selectedSlot;
  String? selectedDoctor;

  final List<String> doctors = ['Dr. Anita Sharma', 'Dr. Rahul Verma'];

  List<String> generateSlots() {
    List<String> slots = [];
    DateTime current = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      AppointmentRules.startTime.hour, AppointmentRules.startTime.minute,
    );
    DateTime end = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      AppointmentRules.endTime.hour, AppointmentRules.endTime.minute,
    );
    DateTime breakStartDT = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      AppointmentRules.breakStart.hour, AppointmentRules.breakStart.minute,
    );
    DateTime breakEndDT = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      AppointmentRules.breakEnd.hour, AppointmentRules.breakEnd.minute,
    );

    while (current.isBefore(end)) {
      if (!(current.isAfter(breakStartDT.subtract(const Duration(minutes: 1))) &&
          current.isBefore(breakEndDT))) {
        slots.add(TimeOfDay.fromDateTime(current).format(context));
      }
      current = current.add(Duration(minutes: AppointmentRules.slotDuration));
    }
    return slots;
  }

  /// Splits flat slot list into morning / afternoon / evening groups
  Map<String, List<String>> _groupSlots(List<String> slots) {
    final Map<String, List<String>> groups = {
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
    };
    for (final slot in slots) {
      final tod = _parseTod(slot);
      if (tod == null) continue;
      if (tod.hour < 12) {
        groups['Morning']!.add(slot);
      } else if (tod.hour < 17) {
        groups['Afternoon']!.add(slot);
      } else {
        groups['Evening']!.add(slot);
      }
    }
    return groups;
  }

  TimeOfDay? _parseTod(String slot) {
    try {
      // Handles "9:00 AM" / "2:30 PM" formats
      final parts = slot.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: deepBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedSlot = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = generateSlots();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              children: [
                _sectionLabel('Select Doctor'),
                const SizedBox(height: 10),
                _doctorSelector(),

                const SizedBox(height: 20),

                _sectionLabel('Select Date'),
                const SizedBox(height: 10),
                _dateSelector(),

                const SizedBox(height: 20),

                _sectionLabel('Available Slots'),
                const SizedBox(height: 10),

                if (selectedDoctor == null)
                  _emptyState(
                    icon: Icons.person_search_outlined,
                    message: 'Please select a doctor first',
                  )
                else
                  _buildGroupedSlots(slots),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: deepBlue),
        ),
      ),
      centerTitle: true,
      title: const Text(
        'Book Appointment',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: deepBlue,
          letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE8EEF8)),
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: deepBlue,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: deepBlue,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ─── Doctor selector ──────────────────────────────────────────────────────
  Widget _doctorSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedDoctor,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: deepBlue),
        decoration: InputDecoration(
          hintText: 'Choose a doctor',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Icon(Icons.medical_services_outlined,
                color: deepBlue, size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: midBlue, width: 2),
          ),
        ),
        items: doctors.map((doc) {
          return DropdownMenuItem(
            value: doc,
            child: Text(
              doc,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B3E),
              ),
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() {
          selectedDoctor = value;
          selectedSlot = null;
        }),
      ),
    );
  }

  // ─── Date selector ────────────────────────────────────────────────────────
  Widget _dateSelector() {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: deepBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${selectedDate.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    monthNames[selectedDate.month - 1],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayNames[selectedDate.weekday - 1],
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${monthNames[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year}',
                    style: const TextStyle(
                      color: Color(0xFF0D1B3E),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_calendar_rounded,
                  size: 18, color: deepBlue),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Grouped slots ────────────────────────────────────────────────────────
  Widget _buildGroupedSlots(List<String> slots) {
    if (slots.isEmpty) {
      return _emptyState(
        icon: Icons.event_busy_outlined,
        message: 'No slots available for this date',
      );
    }

    final dateKey =
        "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
    AppointmentRules.bookedSlots.putIfAbsent(selectedDoctor!, () => {});
    AppointmentRules.bookedSlots[selectedDoctor!]!
        .putIfAbsent(dateKey, () => []);
    final bookedForDoctor =
        AppointmentRules.bookedSlots[selectedDoctor!]![dateKey]!;

    final grouped = _groupSlots(slots);

    // Group metadata: icon, label, accent
    final meta = {
      'Morning': {
        'icon': Icons.wb_sunny_outlined,
        'color': const Color(0xFFE65100),
        'bg': const Color(0xFFFFF3E0),
      },
      'Afternoon': {
        'icon': Icons.wb_cloudy_outlined,
        'color': const Color(0xFF0277BD),
        'bg': const Color(0xFFE1F5FE),
      },
      'Evening': {
        'icon': Icons.nights_stay_outlined,
        'color': const Color(0xFF4527A0),
        'bg': const Color(0xFFEDE7F6),
      },
    };

    final groups = ['Morning', 'Afternoon', 'Evening'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: groups.where((g) => grouped[g]!.isNotEmpty).map((group) {
          final slotList = grouped[group]!;
          final m = meta[group]!;
          final color = m['color'] as Color;
          final bg = m['bg'] as Color;
          final icon = m['icon'] as IconData;
          final isLast = group ==
              groups.lastWhere((g) => grouped[g]!.isNotEmpty);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 15, color: color),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      group,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${slotList.length} slots',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Slot chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: slotList.map((slot) {
                    final isBooked = bookedForDoctor.contains(slot);
                    final isSelected = selectedSlot == slot;
                    return _SlotChip(
                      slot: slot,
                      isBooked: isBooked,
                      isSelected: isSelected,
                      accentColor: color,
                      onTap: isBooked
                          ? null
                          : () => setState(() => selectedSlot = slot),
                    );
                  }).toList(),
                ),
              ),

              // Divider between groups
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.grey.shade100,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _emptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom confirm bar ───────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedDoctor != null && selectedSlot != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: deepBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$selectedDoctor · $selectedSlot',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: deepBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: deepBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: confirmBooking,
              child: const Text(
                'Confirm Appointment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Booking logic (unchanged) ────────────────────────────────────────────
  void confirmBooking() {
    if (selectedDoctor == null || selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select doctor and slot')),
      );
      return;
    }

    final dateKey =
        "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
    final bookedForDoctor =
        AppointmentRules.bookedSlots[selectedDoctor!]![dateKey]!;

    if (bookedForDoctor.length >= AppointmentRules.maxPatientsPerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily limit reached')),
      );
      return;
    }

    bookedForDoctor.add(selectedSlot!);
    AppointmentRules.appointments.add(
      Appointment(doctor: selectedDoctor!, date: dateKey, slot: selectedSlot!),
    );

    final notif = NotificationService.instance;

    notif.addAppointmentConfirmation(
      doctor: selectedDoctor!,
      date: dateKey,
      slot: selectedSlot!,
    );

    if (selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.day == DateTime.now().day) {
      notif.addAppointmentReminder(
        doctor: selectedDoctor!,
        slot: selectedSlot!,
      );
    }

    notif.addNewAppointmentForDoctor(
      patientName: "Patient",
      date: dateKey,
      slot: selectedSlot!,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booked with $selectedDoctor at $selectedSlot'),
        backgroundColor: deepBlue,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );

    setState(() => selectedSlot = null);
  }
}

// ─── Slot Chip ────────────────────────────────────────────────────────────────
class _SlotChip extends StatelessWidget {
  final String slot;
  final bool isBooked;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback? onTap;

  const _SlotChip({
    required this.slot,
    required this.isBooked,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;

    if (isBooked) {
      bg = Colors.grey.shade100;
      text = Colors.grey.shade400;
      border = Colors.grey.shade200;
    } else if (isSelected) {
      bg = accentColor;
      text = Colors.white;
      border = accentColor;
    } else {
      bg = Colors.white;
      text = const Color(0xFF0D1B3E);
      border = accentColor.withOpacity(0.25);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBooked)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(Icons.block_rounded,
                    size: 11, color: Colors.grey.shade400),
              )
            else if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 5),
                child: Icon(Icons.check_circle_rounded,
                    size: 11, color: Colors.white),
              ),
            Text(
              slot,
              style: TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}