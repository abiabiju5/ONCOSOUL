import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import '../services/notification_service.dart';
import '../models/app_user_session.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final _service = DoctorService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color _green = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DoctorAppointment> _filter(List<DoctorAppointment> all, String tab) {
    final today = DateTime.now();
    List<DoctorAppointment> result;
    switch (tab) {
      case 'Today':
        result = all
            .where((a) => _isSameDay(a.date, today) && a.status == 'Pending')
            .toList();
        break;
      case 'Upcoming':
        result = all
            .where((a) => a.date.isAfter(today) && a.status == 'Pending')
            .toList();
        break;
      case 'Completed':
        result = all.where((a) => a.status == 'Completed').toList();
        break;
      case 'Cancelled':
        result = all.where((a) => a.status == 'Cancelled').toList();
        break;
      default:
        result = all;
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((a) => a.patientName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return result;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _markCompleted(DoctorAppointment appt) async {
    try {
      await _service.markCompleted(appt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cancel(DoctorAppointment appt) async {
    final doctorName = AppUserSession.currentUser?.name ?? 'your doctor';
    final dateStr = '${appt.date.day}/${appt.date.month}/${appt.date.year}';
    try {
      await _service.cancelAppointment(
          appt.id, appt.patientId, appt.patientName, dateStr, appt.slot);
      NotificationService.instance.addAppointmentCancellationForPatient(
        doctor: 'Dr. $doctorName',
        date: dateStr,
        slot: appt.slot,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _reschedule(DoctorAppointment appt) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: appt.date,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (newDate == null || !mounted) return;
    final newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appt.date),
    );
    if (newTime == null || !mounted) return;
    final newSlot = newTime.format(context);
    try {
      await _service.rescheduleAppointment(appt.id, newDate, newSlot);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment rescheduled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<DoctorAppointment> all, String tab) {
    final list = _filter(all, tab);
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No appointments found.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final appt = list[i];
        final dateStr =
            '${appt.date.day}/${appt.date.month}/${appt.date.year}';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _green.withValues(alpha: 0.12),
              child: Text(
                appt.patientName.isNotEmpty
                    ? appt.patientName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: _green),
              ),
            ),
            title: Text(appt.patientName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$dateStr  •  ${appt.slot}'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(appt.status)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appt.status,
                    style: TextStyle(
                        color: _statusColor(appt.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
            trailing: appt.status == 'Cancelled'
                ? null
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'complete') {
                        _markCompleted(appt);
                      } else if (value == 'reschedule') {
                        _reschedule(appt);
                      } else if (value == 'cancel') {
                        _cancel(appt);
                      }
                    },
                    itemBuilder: (_) => [
                      if (appt.status == 'Pending')
                        const PopupMenuItem(
                            value: 'complete',
                            child: Text('Mark as Completed')),
                      const PopupMenuItem(
                          value: 'reschedule',
                          child: Text('Reschedule')),
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text('Cancel',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<List<DoctorAppointment>>(
        stream: _service.appointmentsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final all = snap.data ?? [];
          final today = DateTime.now();
          final totalCount = all.length;
          final todayCount =
              all.where((a) => _isSameDay(a.date, today)).length;
          final pendingCount =
              all.where((a) => a.status == 'Pending').length;
          final completedCount =
              all.where((a) => a.status == 'Completed').length;
          final cancelledCount =
              all.where((a) => a.status == 'Cancelled').length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search patient...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            }),
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Row(children: [
                      _buildStatCard('Total', totalCount, Colors.blue),
                      _buildStatCard('Today', todayCount, Colors.orange),
                    ]),
                    Row(children: [
                      _buildStatCard(
                          'Pending', pendingCount, Colors.orange),
                      _buildStatCard(
                          'Done', completedCount, Colors.green),
                      _buildStatCard(
                          'Cancelled', cancelledCount, Colors.red),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(all, 'All'),
                    _buildList(all, 'Today'),
                    _buildList(all, 'Upcoming'),
                    _buildList(all, 'Completed'),
                    _buildList(all, 'Cancelled'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}