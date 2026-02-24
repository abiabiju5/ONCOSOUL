import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import '../models/app_user_session.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  static const Color _blue = Color(0xFF0D47A1);
  static const Color _bg = Color(0xFFF0F4FF);

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _timeOptions = [
    '06:00 AM', '06:30 AM', '07:00 AM', '07:30 AM',
    '08:00 AM', '08:30 AM', '09:00 AM', '09:30 AM',
    '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM',
    '12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM',
    '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM',
    '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM',
    '06:00 PM', '06:30 PM', '07:00 PM', '07:30 PM',
    '08:00 PM', '08:30 PM', '09:00 PM',
  ];

  final _service = DoctorService();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  Map<String, bool> _workingDays = {};
  String _startTime = '09:00 AM';
  String _endTime = '05:00 PM';
  int _slotDuration = 30;
  List<String> _blockedDates = [];
  List<String> _blockedSlots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final avail = await _service.fetchAvailability();
      setState(() {
        _workingDays = Map<String, bool>.from(avail.workingDays);
        _startTime = avail.startTime;
        _endTime = avail.endTime;
        _slotDuration = avail.slotDurationMinutes;
        _blockedDates = List<String>.from(avail.blockedDates);
        _blockedSlots = List<String>.from(avail.blockedSlots);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final doctorId = AppUserSession.currentUser?.userId ?? '';
      final avail = DoctorAvailability(
        doctorId: doctorId,
        workingDays: _workingDays,
        startTime: _startTime,
        endTime: _endTime,
        slotDurationMinutes: _slotDuration,
        blockedDates: _blockedDates,
        blockedSlots: _blockedSlots,
      );
      await _service.saveAvailability(avail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndBlockDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final dateStr =
          '\${picked.year}-\${picked.month.toString().padLeft(2, '0')}-\${picked.day.toString().padLeft(2, '0')}';
      if (!_blockedDates.contains(dateStr)) {
        setState(() => _blockedDates.add(dateStr));
        try {
          await _service.blockDate(picked);
        } catch (_) {}
      }
    }
  }

  Future<void> _pickAndBlockSlot() async {
    // Step 1: pick a date
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _blue)),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final dateStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    // Step 2: pick a slot from a dialog
    final slot = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Slot to Block', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _timeOptions.map((t) => ListTile(
              dense: true,
              title: Text(t, style: const TextStyle(fontSize: 13)),
              onTap: () => Navigator.pop(ctx, t),
            )).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
      ),
    );
    if (slot == null) return;

    final key = '$dateStr|$slot';
    if (!_blockedSlots.contains(key)) {
      setState(() => _blockedSlots.add(key));
      try {
        await _service.blockSlot(picked, slot);
      } catch (_) {}
    }
  }

  Future<void> _unblockSlot(String key) async {
    setState(() => _blockedSlots.remove(key));
    try {
      final parts = key.split('|');
      if (parts.length == 2) {
        final dateParts = parts[0].split('-');
        final date = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
        await _service.unblockSlot(date, parts[1]);
      }
    } catch (_) {}
  }

  Future<void> _unblockDate(String dateStr) async {
    setState(() => _blockedDates.remove(dateStr));
    try {
      final parts = dateStr.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      await _service.unblockDate(date);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Availability',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (!_loading)
            _saving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.save_rounded),
                    onPressed: _save,
                    tooltip: 'Save',
                  ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text('Failed to load availability',
                          style: TextStyle(color: Colors.red.shade700)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Working Days ──────────────────────────────────────
                    _sectionHeader('Working Days'),
                    const SizedBox(height: 10),
                    _card(
                      child: Column(
                        children: _days.map((day) {
                          final isOn = _workingDays[day] ?? false;
                          return SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(day,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14)),
                            value: isOn,
                            activeThumbColor: _blue,
                            onChanged: (v) =>
                                setState(() => _workingDays[day] = v),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Consultation Hours ────────────────────────────────
                    _sectionHeader('Consultation Hours'),
                    const SizedBox(height: 10),
                    _card(
                      child: Column(children: [
                        _timeDropdown(
                          label: 'Start Time',
                          value: _startTime,
                          onChanged: (v) =>
                              setState(() => _startTime = v ?? _startTime),
                        ),
                        const Divider(height: 20),
                        _timeDropdown(
                          label: 'End Time',
                          value: _endTime,
                          onChanged: (v) =>
                              setState(() => _endTime = v ?? _endTime),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── Slot Duration ─────────────────────────────────────
                    _sectionHeader('Slot Duration (minutes)'),
                    const SizedBox(height: 10),
                    _card(
                      child: Row(
                        children: [15, 20, 30, 45, 60].map((min) {
                          final selected = _slotDuration == min;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _slotDuration = min),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _blue
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? _blue
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  '$min',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Blocked Dates ─────────────────────────────────────
                    _sectionHeader('Blocked / Leave Dates'),
                    const SizedBox(height: 10),
                    _card(
                      child: Column(children: [
                        if (_blockedDates.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(children: [
                              Icon(Icons.event_available_rounded,
                                  color: Colors.grey, size: 18),
                              SizedBox(width: 8),
                              Text('No blocked dates.',
                                  style: TextStyle(color: Colors.grey)),
                            ]),
                          )
                        else
                          ..._blockedDates.map((d) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                    Icons.block_rounded,
                                    color: Colors.red,
                                    size: 18),
                                title: Text(d,
                                    style: const TextStyle(fontSize: 13)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 18),
                                  onPressed: () => _unblockDate(d),
                                ),
                              )),
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          onPressed: _pickAndBlockDate,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Blocked Date'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _blue,
                            side: const BorderSide(color: _blue),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── Blocked Slots ─────────────────────────────────────
                    _sectionHeader('Block Specific Slots'),
                    const SizedBox(height: 4),
                    Text('Block individual time slots on a specific date.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 10),
                    _card(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (_blockedSlots.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(children: [
                              Icon(Icons.schedule_rounded, color: Colors.grey, size: 18),
                              SizedBox(width: 8),
                              Text('No slots blocked.', style: TextStyle(color: Colors.grey)),
                            ]),
                          )
                        else
                          ..._blockedSlots.map((s) {
                            final parts = s.split('|');
                            final label = parts.length == 2 ? '\${parts[0]}  •  \${parts[1]}' : s;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.access_time_rounded, color: Colors.orange, size: 18),
                              title: Text(label, style: const TextStyle(fontSize: 13)),
                              trailing: IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => _unblockSlot(s),
                              ),
                            );
                          }),
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          onPressed: _pickAndBlockSlot,
                          icon: const Icon(Icons.more_time_rounded, size: 16),
                          label: const Text('Block a Slot'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            side: BorderSide(color: Colors.orange.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 28),

                    // ── Save Button ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text('Save Availability'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _sectionHeader(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800),
      );

  Widget _timeDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(children: [
      Text(label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      const Spacer(),
      DropdownButton<String>(
        value: _timeOptions.contains(value) ? value : _timeOptions.first,
        onChanged: onChanged,
        underline: const SizedBox(),
        style: const TextStyle(
            color: _blue, fontWeight: FontWeight.w600, fontSize: 14),
        items: _timeOptions
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
      ),
    ]);
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}