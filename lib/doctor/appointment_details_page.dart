import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import 'consultation_room_page.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String date;
  final String time;
  final String status;

  const AppointmentDetailsPage({
    super.key,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.time,
    required this.status,
  });

  @override
  State<AppointmentDetailsPage> createState() =>
      _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState
    extends State<AppointmentDetailsPage> {
  final _service = DoctorService();

  late String _status;
  late DateTime _date;
  late String _slot;
  bool _isSaving = false;

  static const Color _blue = Color(0xFF0D47A1);
  static const Color _lightBlue = Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _slot = widget.time;
    // Parse the dd/MM/yyyy string back into a DateTime
    try {
      final parts = widget.date.split('/');
      _date = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      _date = DateTime.now();
    }
  }

  String get _dateStr => '${_date.day}/${_date.month}/${_date.year}';

  Color _statusColor(String s) {
    switch (s) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime.now()) ? DateTime.now() : _date,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _blue)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final initial = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _blue)),
        child: child!,
      ),
    );
    if (picked != null) {
      if (mounted) {
        setState(() => _slot = picked.format(context));
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      // Reschedule if date/slot changed
      final originalDate = widget.date;
      final originalSlot = widget.time;
      final dateChanged = _dateStr != originalDate;
      final slotChanged = _slot != originalSlot;

      if (dateChanged || slotChanged) {
        await _service.rescheduleAppointment(
            widget.appointmentId, _date, _slot);
      }

      // Update status if it changed (and not already handled by reschedule)
      if (_status != widget.status && !dateChanged && !slotChanged) {
        if (_status == 'Completed') {
          await _service.markCompleted(widget.appointmentId);
        } else if (_status == 'Cancelled') {
          await _service.cancelAppointment(
            widget.appointmentId,
            widget.patientId,
            widget.patientName,
            _dateStr,
            _slot,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Appointment updated successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Patient card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 3))
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _lightBlue,
                    child: Text(
                      widget.patientName.isNotEmpty
                          ? widget.patientName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _blue),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.patientName,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('ID: ${widget.patientId}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(_status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _statusColor(_status)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _status,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(_status)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Date & Time ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 3))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Schedule',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _blue)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _dateTile(
                        label: 'Date',
                        value: _dateStr,
                        icon: Icons.calendar_today_rounded,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateTile(
                        label: 'Time Slot',
                        value: _slot,
                        icon: Icons.access_time_rounded,
                        onTap: _pickTime,
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Status ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 3))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Update Status',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _blue)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _status == 'Upcoming' ? 'Pending' : _status,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F7FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'Completed', child: Text('Completed')),
                      DropdownMenuItem(
                          value: 'Cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Save Changes ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Saving…' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveChanges,
              ),
            ),

            const SizedBox(height: 12),

            // ── Go to Consultation Room ────────────────────────────────────
            if (_status == 'Pending')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('Open Consultation Room'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    side: const BorderSide(color: _blue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsultationRoomPage(
                          appointmentId: widget.appointmentId,
                          patientName: widget.patientName,
                          patientId: widget.patientId,
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: _lightBlue,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _blue.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Colors.blueGrey)),
            const SizedBox(height: 5),
            Row(children: [
              Icon(icon, size: 14, color: _blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _blue)),
              ),
              const Icon(Icons.edit_rounded, size: 13, color: Colors.blueGrey),
            ]),
          ],
        ),
      ),
    );
  }
}