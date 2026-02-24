import 'package:flutter/material.dart';
import '../services/patient_service.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});
  static const Color deepBlue = Color(0xFF0D47A1);
  static const Color bgColor = Color(0xFFF0F4FC);

  @override
  Widget build(BuildContext context) {
    final service = PatientService();
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: StreamBuilder<List<PatientAppointment>>(
        stream: service.myAppointmentsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red)));
          }
          final appointments = snap.data ?? [];
          if (appointments.isEmpty) return _buildEmptyState();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: appointments.length,
            itemBuilder: (context, index) => _AppointmentCard(appt: appointments[index], service: service),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: deepBlue)),
      ),
      centerTitle: true,
      title: const Text('My Appointments', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: deepBlue, letterSpacing: -0.3)),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: const Color(0xFFE8EEF8))),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(width: 80, height: 80,
        child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
          child: Center(child: Icon(Icons.event_note_outlined, size: 38, color: deepBlue)))),
      const SizedBox(height: 20),
      const Text('No Appointments Yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0D1B3E))),
      const SizedBox(height: 8),
      Text('Your booked appointments will appear here.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
    ]));
  }
}

class _AppointmentCard extends StatelessWidget {
  final PatientAppointment appt;
  final PatientService service;
  const _AppointmentCard({required this.appt, required this.service});
  static const Color deepBlue = Color(0xFF0D47A1);

  static const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: const Icon(Icons.event_busy_rounded, color: Colors.red, size: 26)),
            const SizedBox(height: 16),
            const Text('Cancel Appointment?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0D1B3E))),
            const SizedBox(height: 8),
            Text('Are you sure you want to cancel your appointment with Dr. ${appt.doctorName}?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Keep it', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await service.cancelAppointment(appt.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment cancelled.'), backgroundColor: Colors.red));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('Cancel it', style: TextStyle(fontWeight: FontWeight.w700)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatusData(appt.status);
    final dateStr = '${appt.date.day} ${monthNames[appt.date.month - 1]} ${appt.date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.local_hospital_outlined, size: 22, color: deepBlue)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text('Dr. ${appt.doctorName}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D1B3E)))),
                const SizedBox(width: 8),
                _StatusBadge(label: appt.status, color: statusData['color'] as Color, bgColor: statusData['bg'] as Color),
              ]),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.calendar_today_outlined, label: dateStr),
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.access_time_rounded, label: appt.slot),
            ])),
          ]),
          if (appt.status == 'Pending') ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmCancel(context),
                icon: const Icon(Icons.event_busy_rounded, size: 15),
                label: const Text('Cancel Appointment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'Completed': return {'color': const Color(0xFF2E7D32), 'bg': const Color(0xFFE8F5E9)};
      case 'Cancelled': return {'color': const Color(0xFFC62828), 'bg': const Color(0xFFFFEBEE)};
      default: return {'color': const Color(0xFFE65100), 'bg': const Color(0xFFFFF3E0)};
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label; final Color color; final Color bgColor;
  const _StatusBadge({required this.label, required this.color, required this.bgColor});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2)));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 13, color: Colors.grey.shade400), const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
    ]);
  }
}