import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminManageAppointmentsScreen extends StatefulWidget {
  const AdminManageAppointmentsScreen({super.key});

  @override
  State<AdminManageAppointmentsScreen> createState() =>
      _AdminManageAppointmentsScreenState();
}

class _AdminManageAppointmentsScreenState
    extends State<AdminManageAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _deepBlue = Color(0xFF0D47A1);
  late TabController _tabController;

  // Appointment Rules
  final _maxPerDayCtrl = TextEditingController();
  final _slotDurationCtrl = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _savingRules = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _maxPerDayCtrl.dispose();
    _slotDurationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRules() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('appointment_rules')
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _maxPerDayCtrl.text = (data['maxPerDay'] ?? 20).toString();
        _slotDurationCtrl.text =
            (data['slotDurationMinutes'] ?? 30).toString();
        final start = data['startTime'] ?? '09:00';
        final end = data['endTime'] ?? '17:00';
        _startTime = _parseTime(start);
        _endTime = _parseTime(end);
      });
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveRules() async {
    final max = int.tryParse(_maxPerDayCtrl.text);
    final duration = int.tryParse(_slotDurationCtrl.text);
    if (max == null || duration == null) {
      _showError('Please enter valid numbers.');
      return;
    }
    setState(() => _savingRules = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('appointment_rules')
          .set({
        'maxPerDay': max,
        'slotDurationMinutes': duration,
        'startTime': _formatTimeOfDay(_startTime),
        'endTime': _formatTimeOfDay(_endTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _showSuccess('Appointment rules saved!');
    } catch (e) {
      _showError('Failed to save rules.');
    } finally {
      if (mounted) setState(() => _savingRules = false);
    }
  }

  Future<void> _updateAppointmentStatus(
      String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(docId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    _showSuccess('Appointment $status.');
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FC),
      appBar: AppBar(
        title: const Text('Appointments',
            style:
                TextStyle(fontWeight: FontWeight.w700, color: _deepBlue)),
        backgroundColor: Colors.white,
        foregroundColor: _deepBlue,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _deepBlue,
          labelColor: _deepBlue,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Rules'),
            Tab(text: 'Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRulesTab(),
          _buildBookingsTab(),
        ],
      ),
    );
  }

  Widget _buildRulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(children: [
            const Text('Appointment Settings',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _deepBlue)),
            const SizedBox(height: 20),
            _label('Max Appointments per Day'),
            TextField(
              controller: _maxPerDayCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDeco(
                  'e.g. 20', Icons.event_available_outlined),
            ),
            const SizedBox(height: 16),
            _label('Slot Duration (minutes)'),
            TextField(
              controller: _slotDurationCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  _inputDeco('e.g. 30', Icons.timer_outlined),
            ),
            const SizedBox(height: 16),
            _label('Working Hours'),
            Row(
              children: [
                Expanded(
                  child: _timeTile(
                    label: 'Start',
                    time: _startTime,
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _timeTile(
                    label: 'End',
                    time: _endTime,
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _savingRules ? null : _saveRules,
              child: _savingRules
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Save Rules',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .orderBy('appointmentDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_outlined,
                    size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No appointments found',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final docId = docs[i].id;
            final patientName = data['patientName'] ?? 'Unknown';
            final doctorName = data['doctorName'] ?? 'N/A';
            final status = data['status'] ?? 'pending';
            final date = data['appointmentDate'] as Timestamp?;
            final formattedDate = date != null
                ? DateFormat('dd MMM yyyy, hh:mm a')
                    .format(date.toDate())
                : 'N/A';

            Color statusColor;
            switch (status) {
              case 'confirmed':
                statusColor = Colors.green.shade700;
                break;
              case 'cancelled':
                statusColor = Colors.red.shade700;
                break;
              default:
                statusColor = Colors.orange.shade700;
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(patientName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status[0].toUpperCase() +
                                status.substring(1),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Dr. $doctorName',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                    Text(formattedDate,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black38)),
                    if (status == 'pending') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(
                                    color: Colors.red.shade300),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                              ),
                              onPressed: () =>
                                  _updateAppointmentStatus(
                                      docId, 'cancelled'),
                              child: const Text('Cancel',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.green.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                              ),
                              onPressed: () =>
                                  _updateAppointmentStatus(
                                      docId, 'confirmed'),
                              child: const Text('Confirm',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _timeTile(
      {required String label,
      required TimeOfDay time,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE3F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_outlined,
                size: 18, color: _deepBlue),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.black45)),
                Text(time.format(context),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B3E))),
      );

  InputDecoration _inputDeco(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF5F7FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE3F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE3F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: _deepBlue, width: 1.5)),
      );
}