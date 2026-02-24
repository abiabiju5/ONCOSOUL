import 'package:flutter/material.dart';
import 'screens/online_consultation_screen.dart';
import 'screens/view_reports_screen.dart';
import 'screens/homestay_screen.dart';
import 'screens/community_forum_screen.dart';
import 'screens/awareness_screen.dart';
import 'screens/patient_profile_screen.dart';
import 'screens/patient_prescriptions_screen.dart';
import 'services/notification_service.dart';
import 'widgets/notification_panel.dart';
import 'login.dart';

class PatientDashboard extends StatefulWidget {
  final String userName;
  const PatientDashboard({super.key, required this.userName});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  static const Color primaryBlue = Color(0xFF1E5AA8);
  final _notifService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _notifService.addListener(_refresh);
  }

  @override
  void dispose() {
    _notifService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() { if (mounted) setState(() {}); }

  void _showNotificationPanel(BuildContext context) {
    _notifService.markAllPatientRead();
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (ctx) => Stack(children: [
        Positioned(
          top: MediaQuery.of(ctx).padding.top + 64,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: ListenableBuilder(
              listenable: _notifService,
              builder: (_, __) => NotificationPanel(
                notifications: _notifService.patientNotifications,
                onMarkAllRead: _notifService.markAllPatientRead,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 32, offset: const Offset(0, 12))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFFDEECFB), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: primaryBlue, size: 26),
            ),
            const SizedBox(height: 16),
            const Text('Sign Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0B2E6B))),
            const SizedBox(height: 7),
            Text('Are you sure you want to sign out?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                },
                child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth < 600 ? 220.0 : screenWidth < 1100 ? 250.0 : 280.0;
    final titleSize = screenWidth < 600 ? 26.0 : screenWidth < 1100 ? 30.0 : 34.0;
    final subtitleSize = screenWidth < 600 ? 14.0 : screenWidth < 1100 ? 16.0 : 17.0;
    final unreadCount = _notifService.patientUnreadCount;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 213, 230, 243), Color.fromARGB(255, 192, 213, 236)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── HEADER ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [
                      Icon(Icons.volunteer_activism, color: primaryBlue, size: 28),
                      SizedBox(width: 6),
                      Text('OncoSoul', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 4, 46, 100))),
                    ]),
                    Row(children: [
                      // Profile icon
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientProfileScreen())),
                        child: const Icon(Icons.account_circle_outlined, size: 28, color: primaryBlue),
                      ),
                      const SizedBox(width: 18),
                      // Notification Bell
                      GestureDetector(
                        onTap: () => _showNotificationPanel(context),
                        child: Stack(clipBehavior: Clip.none, children: [
                          const Icon(Icons.notifications_none, size: 28, color: Color.fromARGB(255, 4, 46, 100)),
                          if (unreadCount > 0)
                            Positioned(right: -4, top: -4, child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text(unreadCount > 9 ? '9+' : unreadCount.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            )),
                        ]),
                      ),
                      const SizedBox(width: 18),
                      // Logout
                      GestureDetector(
                        onTap: () => _showLogoutDialog(context),
                        child: const Icon(Icons.logout_rounded, size: 26, color: primaryBlue),
                      ),
                    ]),
                  ],
                ),
              ),

              // ── HERO BANNER ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                height: bannerHeight,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(children: [
                    Positioned.fill(child: Image.asset('assets/images/dashboard_bg.jpg', fit: BoxFit.cover)),
                    Positioned.fill(child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFFE8F1FB).withValues(alpha: 0.78),
                              const Color(0xFFF0F6FF).withValues(alpha: 0.45), Colors.transparent],
                          begin: Alignment.centerLeft, end: Alignment.centerRight,
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    )),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Hello, ${widget.userName}',
                            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold, color: const Color(0xFF0B2E6B))),
                        const SizedBox(height: 10),
                        Text("We're here to support your care journey",
                            style: TextStyle(fontSize: subtitleSize, color: const Color(0xFF2A4A7A))),
                      ]),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 28),

              // ── QUICK ACCESS LABEL ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                child: Row(children: [
                  Container(width: 4, height: 18,
                      decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 9),
                  const Text('Quick Access', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: Color(0xFF0B2E6B), letterSpacing: 0.1)),
                ]),
              ),

              // ── CARDS ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _card(context, Icons.video_call_rounded, 'Online Consultation',
                        const OnlineConsultationScreen(), const Color(0xFF1A56A0), const Color(0xFFD0E4F7))),
                    const SizedBox(width: 20),
                    Expanded(child: _card(context, Icons.insert_drive_file_rounded, 'View Reports',
                        const ViewReportsScreen(), const Color(0xFF1E7A4A), const Color(0xFFD0EFE0))),
                  ]),
                  const SizedBox(height: 22),
                  Row(children: [
                    Expanded(child: _card(context, Icons.medication_rounded, 'My Prescriptions',
                        const PatientPrescriptionsScreen(), const Color(0xFF6A1B9A), const Color(0xFFEBE0F8))),
                    const SizedBox(width: 20),
                    Expanded(child: _card(context, Icons.home_rounded, 'Accommodation',
                        const HomestayScreen(), const Color(0xFFA85820), const Color(0xFFF5E2CC))),
                  ]),
                  const SizedBox(height: 22),
                  Row(children: [
                    Expanded(child: _card(context, Icons.people_rounded, 'Community Forum',
                        const CommunityForumScreen(), const Color(0xFF0277BD), const Color(0xFFD0E8F7))),
                    const SizedBox(width: 20),
                    Expanded(child: _card(context, Icons.health_and_safety_rounded, 'Awareness',
                        const AwarenessScreen(), const Color(0xFFA81E60), const Color(0xFFF8D8E8))),
                  ]),
                  const SizedBox(height: 40),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String title, Widget screen, Color iconColor, Color circleColor) {
    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        height: 130,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
          boxShadow: [
            BoxShadow(color: iconColor.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
              child: Icon(icon, size: 24, color: iconColor)),
          const SizedBox(width: 18),
          Expanded(child: Text(title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey.shade800))),
        ]),
      ),
    );
  }
}