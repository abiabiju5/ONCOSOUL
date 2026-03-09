import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'upload_consultation_summary_screen.dart';

class MedicalStaffAppointmentsScreen extends StatefulWidget {
  const MedicalStaffAppointmentsScreen({super.key});

  @override
  State<MedicalStaffAppointmentsScreen> createState() =>
      _MedicalStaffAppointmentsScreenState();
}

class _MedicalStaffAppointmentsScreenState
    extends State<MedicalStaffAppointmentsScreen> {
  static const Color _deepBlue = Color(0xFF0D47A1);
  String _selectedStatus = 'All';
  final _statuses = ['All', 'Pending', 'Completed', 'Cancelled'];

  Stream<QuerySnapshot> get _stream {
    return FirebaseFirestore.instance
        .collection('appointments')
        .orderBy('date', descending: false)
        .snapshots();
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '—';
    final dt = (ts as Timestamp).toDate();
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Appointments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((s) {
                  final sel = _selectedStatus == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedStatus = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? Colors.white : Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? _deepBlue : Colors.white)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.event_busy_outlined, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No $_selectedStatus appointments',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Pending';
              final patientName = data['patientName'] ?? '—';
              final patientId = data['patientId'] ?? '—';
              final doctorName = data['doctorName'] ?? '—';
              final slot = data['slot'] ?? '—';
              final date = _formatDate(data['date']);
              final statusColor = _statusColor(status);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _deepBlue.withValues(alpha: 0.12)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.person_outline_rounded, size: 18, color: _deepBlue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(patientName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _deepBlue))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(status,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                      ),
                    ]),
                  ),
                  // Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _row(Icons.badge_outlined, 'Patient ID', patientId),
                      _row(Icons.medical_services_outlined, 'Doctor', doctorName),
                      _row(Icons.calendar_today_outlined, 'Date', date),
                      _row(Icons.access_time_rounded, 'Slot', slot),
                    ]),
                  ),
                  // Actions for Pending
                  if (status == 'Pending')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('appointments')
                                  .doc(docs[i].id)
                                  .update({'status': 'Completed'});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Marked as Completed'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Complete', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => UploadConsultationSummaryScreen(
                                prefilledPatientId: patientId,
                                prefilledPatientName: patientName,
                              ),
                            )),
                            icon: const Icon(Icons.upload_file_rounded, size: 16),
                            label: const Text('Upload Summary', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _deepBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ]),
                    ),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
      ]),
    );
  }
}