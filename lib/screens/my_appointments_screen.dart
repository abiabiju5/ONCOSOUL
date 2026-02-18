import 'package:flutter/material.dart';
import '../models/appointment_rules.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  static const Color deepBlue = Color(0xFF0D47A1);
  static const Color bgColor = Color(0xFFF0F4FC);

  @override
  Widget build(BuildContext context) {
    final appointments = AppointmentRules.appointments;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: appointments.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appt = appointments[index];
                return _AppointmentCard(appt: appt, index: index);
              },
            ),
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
        'My Appointments',
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

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_note_outlined,
                size: 38, color: deepBlue),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Appointments Yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1B3E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your booked appointments will appear here.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Appointment Card ─────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final Appointment appt;
  final int index;

  const _AppointmentCard({required this.appt, required this.index});

  static const Color deepBlue = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatusData(appt.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Index badge ──────────────────────────────────────────────
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_hospital_outlined,
                  size: 22, color: deepBlue),
            ),

            const SizedBox(width: 14),

            // ── Details ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor name + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          appt.doctor,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D1B3E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(
                        label: appt.status,
                        color: statusData['color'] as Color,
                        bgColor: statusData['bg'] as Color,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Date row
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: appt.date,
                  ),
                  const SizedBox(height: 6),

                  // Slot row
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    label: appt.slot,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'Completed':
        return {
          'color': const Color(0xFF2E7D32),
          'bg': const Color(0xFFE8F5E9),
        };
      case 'Cancelled':
        return {
          'color': const Color(0xFFC62828),
          'bg': const Color(0xFFFFEBEE),
        };
      default: // Pending
        return {
          'color': const Color(0xFFE65100),
          'bg': const Color(0xFFFFF3E0),
        };
    }
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}