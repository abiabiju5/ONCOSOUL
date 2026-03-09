import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'upload_consultation_summary_screen.dart';

class MedicalStaffViewAppointmentsScreen extends StatefulWidget {
  const MedicalStaffViewAppointmentsScreen({super.key});

  @override
  State<MedicalStaffViewAppointmentsScreen> createState() =>
      _MedicalStaffViewAppointmentsScreenState();
}

class _MedicalStaffViewAppointmentsScreenState
    extends State<MedicalStaffViewAppointmentsScreen> {
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
      backgroundColor: Colors.grey.shade100,
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
                Text('No \$_selectedStatus appointments',
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
                  border: Border.all(color: _deepBlue.withValues(alpha: 0.2)),
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
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _deepBlue))),
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
                  // Info rows
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      infoRow('Patient ID', patientId),
                      infoRow('Doctor', doctorName),
                      infoRow('Date', date),
                      infoRow('Time', slot),
                    ]),
                  ),
                  // Upload Summary button (Pending only)
                  if (status == 'Pending')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file_rounded, size: 16),
                          label: const Text(
                            'Upload Summary',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _deepBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UploadConsultationSummaryScreen(
                                  prefilledPatientId: patientId,
                                  prefilledPatientName: patientName,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label,
              style: TextStyle(color: Colors.grey.shade700))),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}