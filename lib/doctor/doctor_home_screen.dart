import 'package:flutter/material.dart';
import '../models/app_user_session.dart';
import '../services/doctor_service.dart';
import '../services/notification_service.dart';
import '../login.dart';
import 'appointments_screen.dart';
import 'consultations_page.dart';
import 'patients_page.dart';
import 'medical_report_page.dart';
import 'doctor_profile_screen.dart';



// ── DoctorHomeScreen ──────────────────────────────────────────────────────────
// Entry point for all doctors. Bottom nav with 4 tabs:
//   Dashboard · Appointments · Consult · Patients

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _selectedIndex = 0;

  static const Color _green = Color(0xFF0D47A1);
  static const Color _lightGreen = Color(0xFFE3F2FD);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = const [
      _DoctorDashboardTab(),
      AppointmentsScreen(),
      ConsultationsPage(),
      PatientsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: _lightGreen,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: _green),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded, color: _green),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_call_outlined),
            selectedIcon: Icon(Icons.video_call_rounded, color: _green),
            label: 'Consult',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded, color: _green),
            label: 'Patients',
          ),
        ],
      ),
    );
  }
}

// ── _DoctorDashboardTab ───────────────────────────────────────────────────────

class _DoctorDashboardTab extends StatefulWidget {
  const _DoctorDashboardTab();

  @override
  State<_DoctorDashboardTab> createState() => _DoctorDashboardTabState();
}

class _DoctorDashboardTabState extends State<_DoctorDashboardTab> {
  final _service = DoctorService();

  static const Color _green = Color(0xFF0D47A1);
  static const Color _bg = Color(0xFFF0F4FF);

  Future<void> _loadStats() async {
    setState(() {});
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded,
                    color: Colors.red.shade400, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Sign Out?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              const Text(
                'You will need to sign in again to access your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0D47A1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Color(0xFF0D47A1),
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AppUserSession.clear();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    child: const Text('Sign Out',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows Firestore notifications in a bottom sheet — real-time, persisted.
  void _showNotifications() {
    // Also mark all as read when panel opens
    _service.markAllNotificationsRead();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FirestoreNotificationPanel(service: _service),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = AppUserSession.currentUser;
    final name = doctor?.name ?? 'Doctor';
    final specialty = doctor?.specialty ?? 'Oncologist';
    final today = DateTime.now();
    final dateStr =
        '${_weekday(today.weekday)}, ${today.day} ${_month(today.month)} ${today.year}';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('OncoSoul',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          // Profile button
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorProfileScreen()),
            ),
            tooltip: 'Profile',
          ),
          // Firestore-backed Notifications badge
          StreamBuilder<int>(
            stream: _service.unreadNotificationCountStream(),
            builder: (_, snap) {
              final count = snap.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: _showNotifications,
                    tooltip: 'Notifications',
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: _confirmLogout,
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: _green,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Hero banner ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_greeting()},',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Dr. $name',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(specialty,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 10),
                  Text(dateStr,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats (live Firestore stream) ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<DashboardStats>(
                stream: _service.statsStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator()));
                  }
                  if (snap.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                'Could not load stats. Pull to refresh.',
                                style: TextStyle(color: Colors.red.shade700))),
                      ]),
                    );
                  }
                  final s = snap.data ?? const DashboardStats();
                  return Column(children: [
                    Row(children: [
                      _statCard(
                          "Today's\nAppointments",
                          s.today,
                          Icons.today_rounded,
                          Colors.orange),
                      const SizedBox(width: 12),
                      _statCard('Pending', s.pending,
                          Icons.hourglass_bottom_rounded, Colors.blue),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _statCard('Completed', s.completed,
                          Icons.check_circle_rounded, Colors.green),
                      const SizedBox(width: 12),
                      _statCard(
                          'Total', s.total, Icons.bar_chart_rounded, _green),
                    ]),
                  ]);
                },
              ),
            ),

            const SizedBox(height: 28),

            // ── Quick Actions ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Quick Actions',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _quickAction(
                    icon: Icons.calendar_month_rounded,
                    label: 'Appointments',
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AppointmentsScreen())),
                  ),
                  _quickAction(
                    icon: Icons.video_call_rounded,
                    label: 'Online Consult',
                    color: _green,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ConsultationsPage())),
                  ),
                  _quickAction(
                    icon: Icons.people_rounded,
                    label: 'My Patients',
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PatientsPage())),
                  ),
                  _quickAction(
                    icon: Icons.description_rounded,
                    label: 'Reports',
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MedicalReportsPage())),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Today's Queue ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's Queue",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800)),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ConsultationsPage())),
                    child: const Text('See All',
                        style: TextStyle(color: _green)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _TodayQueue(service: _service),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value.toString(),
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _weekday(int w) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];

  String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

// ── _TodayQueue ───────────────────────────────────────────────────────────────

class _TodayQueue extends StatelessWidget {
  final DoctorService service;
  const _TodayQueue({required this.service});

  static const Color _green = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DoctorAppointment>>(
      stream: service.todayPendingStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Error loading queue: ${snap.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        final appts = snap.data ?? [];
        if (appts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(children: [
                  Icon(Icons.event_available_rounded, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('No pending consultations today.',
                      style: TextStyle(color: Colors.grey)),
                ]),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appts.length.clamp(0, 5),
          itemBuilder: (_, i) {
            final a = appts[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: _green.withValues(alpha: 0.12),
                  child: Text(
                    a.patientName.isNotEmpty
                        ? a.patientName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _green),
                  ),
                ),
                title: Text(a.patientName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(a.slot),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.orange.shade200, width: 0.8),
                  ),
                  child: const Text('Pending',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── _FirestoreNotificationPanel ───────────────────────────────────────────────
// Replaces the old in-memory notification panel with live Firestore data.

class _FirestoreNotificationPanel extends StatelessWidget {
  final DoctorService service;
  const _FirestoreNotificationPanel({required this.service});

  static const Color _blue = Color(0xFF0D47A1);

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'new_appointment':
        return Icons.calendar_today_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancellation':
        return Icons.cancel_rounded;
      case 'rescheduled':
        return Icons.schedule_rounded;
      case 'prescription':
        return Icons.medication_rounded;
      case 'new_report':
      case 'report_uploaded':
        return Icons.description_rounded;
      case 'summary_uploaded':
        return Icons.summarize_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'new_appointment':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancellation':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      case 'prescription':
        return Colors.purple;
      default:
        return _blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DoctorFirestoreNotification>>(
      stream: service.notificationsStream(),
      builder: (context, snap) {
        final notifs = snap.data ?? [];

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, ctrl) => Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(children: [
                  const Text('Notifications',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (notifs.any((n) => !n.isRead))
                    TextButton(
                      onPressed: () async {
                        await service.markAllNotificationsRead();
                      },
                      child: const Text('Mark all read',
                          style: TextStyle(color: _blue)),
                    ),
                  TextButton(
                    onPressed: () async {
                      await service.clearAllNotifications();
                    },
                    child: const Text('Clear all',
                        style: TextStyle(color: Colors.red)),
                  ),
                ]),
              ),

              if (notifs.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none_rounded,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('No notifications yet.',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final n = notifs[i];
                      final color = _colorFor(n.type);
                      return Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: Colors.red.shade50,
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.red),
                        ),
                        onDismissed: (_) => service.deleteNotification(n.id),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_iconFor(n.type),
                                color: color, size: 18),
                          ),
                          title: Text(n.title,
                              style: TextStyle(
                                  fontWeight: n.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  fontSize: 13)),
                          subtitle: Text(n.message,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_timeAgo(n.createdAt),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                              if (!n.isRead) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: _blue, shape: BoxShape.circle),
                                ),
                              ],
                            ],
                          ),
                          onTap: () async {
                            if (!n.isRead) {
                              await service.markNotificationRead(n.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}