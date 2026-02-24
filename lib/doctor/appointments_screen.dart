import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import '../services/notification_service.dart';
import '../models/app_user_session.dart';
import 'appointment_details_page.dart';

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

  static const Color _deepBlue  = Color(0xFF0D47A1);
  static const Color _skyBlue   = Color(0xFF1E88E5);
  static const Color _lightBlue = Color(0xFFE3F2FD);
  static const Color _surface   = Color(0xFFF0F4FF);

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
          .where((a) =>
              a.patientName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return result;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default:          return Colors.orange;
    }
  }

  Future<void> _markCompleted(DoctorAppointment appt) async {
    try {
      await _service.markCompleted(appt.id);
      if (mounted) _snack('Marked as completed', isError: false);
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
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
      if (mounted) _snack('Appointment cancelled', isError: false);
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    }
  }

  Future<void> _reschedule(DoctorAppointment appt) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate:
          appt.date.isBefore(DateTime.now()) ? DateTime.now() : appt.date,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _deepBlue)),
        child: child!,
      ),
    );
    if (newDate == null || !mounted) return;
    final newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appt.date),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _deepBlue)),
        child: child!,
      ),
    );
    if (newTime == null || !mounted) return;
    try {
      await _service.rescheduleAppointment(
          appt.id, newDate, newTime.format(context));
      if (mounted) _snack('Appointment rescheduled', isError: false);
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_rounded : Icons.check_circle_rounded,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? Colors.red.shade600 : _deepBlue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _statChip(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _deepBlue.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style:
                    const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<DoctorAppointment> all, String tab) {
    final list = _filter(all, tab);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: _lightBlue, shape: BoxShape.circle),
              child: const Icon(Icons.event_busy_rounded,
                  size: 38, color: _deepBlue),
            ),
            const SizedBox(height: 16),
            const Text('No appointments found.',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final appt = list[i];
        final dateStr =
            '${appt.date.day}/${appt.date.month}/${appt.date.year}';
        final statusColor = _statusColor(appt.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _deepBlue.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AppointmentDetailsPage(
                  appointmentId: appt.id,
                  patientId: appt.patientId,
                  patientName: appt.patientName,
                  date: dateStr,
                  time: appt.slot,
                  status: appt.status,
                ),
              ),
            ),
            child: Row(
              children: [
                // Blue left accent bar
                Container(
                  width: 5,
                  height: 82,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_deepBlue, _skyBlue],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(16)),
                  ),
                ),
                const SizedBox(width: 14),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _lightBlue,
                  child: Text(
                    appt.patientName.isNotEmpty
                        ? appt.patientName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _deepBlue,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appt.patientName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF0D1B3E))),
                        const SizedBox(height: 3),
                        Text('$dateStr  •  ${appt.slot}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            appt.status,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (appt.status != 'Cancelled')
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        color: Colors.grey, size: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'complete') _markCompleted(appt);
                      else if (value == 'reschedule') _reschedule(appt);
                      else if (value == 'cancel') _cancel(appt);
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
                  )
                else
                  const SizedBox(width: 12),
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
      backgroundColor: _surface,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_deepBlue, _skyBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Appointments',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
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
            return const Center(
                child: CircularProgressIndicator(color: _deepBlue));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final all = snap.data ?? [];
          final today = DateTime.now();
          final totalCount     = all.length;
          final todayCount     = all.where((a) => _isSameDay(a.date, today)).length;
          final pendingCount   = all.where((a) => a.status == 'Pending').length;
          final completedCount = all.where((a) => a.status == 'Completed').length;
          final cancelledCount = all.where((a) => a.status == 'Cancelled').length;

          return Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search patient…',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon:
                        const Icon(Icons.search, color: _deepBlue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: _deepBlue.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _deepBlue, width: 1.5),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),

              // Stat chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
                child: Row(children: [
                  _statChip('Total', totalCount,
                      Icons.calendar_month_rounded, _deepBlue),
                  _statChip('Today', todayCount,
                      Icons.today_rounded, Colors.orange.shade700),
                  _statChip('Pending', pendingCount,
                      Icons.hourglass_bottom_rounded,
                      Colors.orange.shade700),
                  _statChip('Done', completedCount,
                      Icons.check_circle_rounded, Colors.green.shade700),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _deepBlue.withValues(alpha: 0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.cancel_rounded,
                              size: 16, color: Colors.red),
                          const SizedBox(height: 3),
                          Text(cancelledCount.toString(),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.red)),
                          const Text('Cancel',
                              style: TextStyle(
                                  fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),

              // Tabs
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