import 'package:flutter/material.dart';
import 'doctor/appointments_screen.dart';
import 'doctor/consultations_page.dart';
import 'doctor/patients_page.dart';
import 'doctor/medical_report_page.dart';
import 'login.dart';
import 'models/app_user_session.dart';
import 'services/doctor_service.dart';
import 'services/notification_service.dart';
import 'widgets/notification_panel.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard>
    with SingleTickerProviderStateMixin {
  final _notifService = NotificationService.instance;
  final _doctorService = DoctorService();

  late AnimationController _animCtrl;
  late List<Animation<double>> _cardAnimations;

  Map<String, int> _stats = {
    'total': 0,
    'today': 0,
    'pending': 0,
    'completed': 0,
  };
  bool _statsLoading = true;

  static const Color deepBlue = Color(0xFF0D47A1);
  static const Color skyBlue = Color(0xFF1E88E5);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color surfaceWhite = Color(0xFFF0F4FF);

  @override
  void initState() {
    super.initState();
    _notifService.addListener(_refresh);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardAnimations = List.generate(4, (i) {
      return CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(0.1 * i, 0.4 + 0.1 * i, curve: Curves.easeOutCubic),
      );
    });
    _animCtrl.forward();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _doctorService.fetchDashboardStats();
      if (mounted) setState(() { _stats = stats; _statsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _notifService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() { if (mounted) setState(() {}); }

  void _showNotificationPanel(BuildContext context) {
    _notifService.markAllDoctorRead();
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (ctx) => Stack(
        children: [
          Positioned(
            top: MediaQuery.of(ctx).padding.top + kToolbarHeight + 4,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: ListenableBuilder(
                listenable: _notifService,
                builder: (_, __) => NotificationPanel(
                  notifications: _notifService.doctorNotifications,
                  onMarkAllRead: _notifService.markAllDoctorRead,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: deepBlue.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.red.shade100, Colors.red.shade50],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout_rounded,
                      color: Colors.red.shade400, size: 34),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Leaving so soon?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1B3E),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your session will end and you\'ll need\nto sign in again to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFBBDEFB), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          'Stay',
                          style: TextStyle(
                            color: deepBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (shouldLogout == true && mounted) {
      AppUserSession.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = AppUserSession.currentUser?.name ?? 'Doctor';
    final unreadCount = _notifService.doctorUnreadCount;

    final cards = [
      _CardData(
        icon: Icons.video_call_rounded,
        title: 'Online Consultation',
        subtitle: 'Connect with patients remotely',
        gradient: const [Color(0xFF1565C0), Color(0xFF1E88E5)],
        lightColor: const Color(0xFFE3F2FD),
        screen: const ConsultationsPage(),
        tag: 'LIVE',
      ),
      _CardData(
        icon: Icons.description_rounded,
        title: 'View Reports',
        subtitle: 'Access & review medical records',
        gradient: const [Color(0xFF00695C), Color(0xFF26A69A)],
        lightColor: const Color(0xFFE0F2F1),
        screen: const MedicalReportsPage(),
        tag: null,
      ),
      _CardData(
        icon: Icons.people_rounded,
        title: 'My Patients',
        subtitle: 'Manage your patient list',
        gradient: const [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        lightColor: const Color(0xFFF3E5F5),
        screen: const PatientsPage(),
        tag: null,
      ),
      _CardData(
        icon: Icons.event_available_rounded,
        title: 'Appointments',
        subtitle: 'Schedule & manage bookings',
        gradient: const [Color(0xFF2E7D32), Color(0xFF66BB6A)],
        lightColor: const Color(0xFFE8F5E9),
        screen: const AppointmentsScreen(),
        tag: null,
      ),
    ];

    return Scaffold(
      backgroundColor: surfaceWhite,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 26),
                if (unreadCount > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showNotificationPanel(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: Colors.white, size: 22),
              onPressed: _confirmLogout,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Hero Header ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [deepBlue, skyBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40, top: -40,
                      child: Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20, top: 40,
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -25, bottom: 20,
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 80, bottom: 50,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 100, top: 50,
                      child: Opacity(
                        opacity: 0.12,
                        child: Icon(Icons.add, color: Colors.white, size: 48),
                      ),
                    ),
                    Positioned(
                      left: 40,
                      top: MediaQuery.of(context).padding.top + 50,
                      child: const Opacity(
                        opacity: 0.07,
                        child: Icon(Icons.add, color: Colors.white, size: 34),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        MediaQuery.of(context).padding.top + kToolbarHeight + 4,
                        24,
                        32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Good Day,',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Dr. $doctorName 👋',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.local_hospital_rounded,
                                              color: Colors.white.withValues(alpha: 0.85),
                                              size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            'OncoSoul Medical Portal',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 88, height: 88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 76, height: 76,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.18),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(Icons.person_rounded,
                                        color: Colors.white, size: 42),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Live stats
                          if (_statsLoading)
                            const Center(
                              child: SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              ),
                            )
                          else
                            Row(
                              children: [
                                _statChip('Today', _stats['today']!,
                                    Icons.today_rounded),
                                const SizedBox(width: 10),
                                _statChip('Pending', _stats['pending']!,
                                    Icons.hourglass_bottom_rounded),
                                const SizedBox(width: 10),
                                _statChip('Done', _stats['completed']!,
                                    Icons.check_circle_outline_rounded),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Section Label ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [deepBlue, skyBlue],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Quick Access',
                      style: TextStyle(
                        color: deepBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '4 modules',
                        style: TextStyle(
                          color: deepBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Action Cards ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: List.generate(cards.length, (i) {
                    return FadeTransition(
                      opacity: _cardAnimations[i],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(_cardAnimations[i]),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildCard(context, cards[i]),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, int count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(count.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _CardData data) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => data.screen)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: data.gradient.first.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 6, height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: data.gradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20)),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: data.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: data.gradient.first.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(data.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: data.gradient.first,
                              letterSpacing: 0.1,
                            )),
                        if (data.tag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.green.shade300, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5, height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(data.tag!,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(data.subtitle,
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.lightColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: data.gradient.first),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color lightColor;
  final Widget screen;
  final String? tag;

  _CardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.lightColor,
    required this.screen,
    this.tag,
  });
}