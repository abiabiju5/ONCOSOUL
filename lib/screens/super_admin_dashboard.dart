import 'package:flutter/material.dart';
import '../login.dart';
import 'admin_awareness_management_screen.dart';
import 'admin_homestay_management_screen.dart';
import '../models/app_user_session.dart' hide AppUser;
import '../services/auth_service.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final _authService = AuthService();

  // ─── Logout confirmation dialog ───────────────────────────────────────────
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 90, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    size: 24, color: Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 14),
              const Text(
                'Log Out?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D47A1),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want\nto log out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D47A1),
                        side: const BorderSide(
                            color: Color(0xFF0D47A1), width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        AppUserSession.clear();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      child: const Text('Log Out',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ PopScope replaces deprecated WillPopScope
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FC),
        appBar: _buildAppBar(context),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 28),
            _sectionLabel("Content Management"),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.health_and_safety_rounded,
              title: "Awareness Content",
              subtitle: "Manage cancer awareness articles & posts",
              accentColor: const Color(0xFF1565C0),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminAwarenessManagementScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.home_work_rounded,
              title: "Accommodation",
              subtitle: "Manage homestay listings & bookings",
              accentColor: const Color(0xFF0277BD),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminHomestayManagementScreen()),
              ),
            ),
            const SizedBox(height: 28),
            _sectionLabel("System Analytics"),
            const SizedBox(height: 12),
            // ✅ Live Firestore analytics — no more UserData
            _LiveAnalyticsBox(authService: _authService),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      surfaceTintColor: Colors.transparent,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.volunteer_activism_rounded,
                size: 20, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(width: 8),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Onco',
                  style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
                TextSpan(
                  text: 'Soul',
                  style: TextStyle(
                      color: Color(0xFF42A5F5),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => _confirmLogout(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  size: 20, color: Color(0xFF0D47A1)),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE8EEF8)),
      ),
    );
  }

  // ─── Hero card ────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ✅ withValues replaces deprecated withOpacity
            color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'System Administrator',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Welcome back 👋',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 2),
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                size: 32, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D47A1),
              letterSpacing: -0.2),
        ),
      ],
    );
  }
}

// ─── Live Analytics Box ───────────────────────────────────────────────────────
class _LiveAnalyticsBox extends StatelessWidget {
  final AuthService authService;
  const _LiveAnalyticsBox({required this.authService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: authService.getAllUsersStream(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting;

        final totalPatients =
            users.where((u) => u.role == UserRole.patient).length;
        final totalDoctors =
            users.where((u) => u.role == UserRole.doctor).length;
        final activeUsers = users.where((u) => u.isActive).length;

        final stats = [
          _StatData(
            label: 'Patients',
            value: totalPatients,
            icon: Icons.personal_injury_outlined,
            color: const Color(0xFF1565C0),
            bgColor: const Color(0xFFE3F2FD),
          ),
          _StatData(
            label: 'Doctors',
            value: totalDoctors,
            icon: Icons.medical_services_outlined,
            color: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFE8F5E9),
          ),
          _StatData(
            label: 'Active',
            value: activeUsers,
            icon: Icons.people_alt_outlined,
            color: const Color(0xFF6A1B9A),
            bgColor: const Color(0xFFF3E5F5),
          ),
          const _StatData(
            label: 'Bookings',
            value: 0,
            icon: Icons.hotel_outlined,
            color: Color(0xFFE65100),
            bgColor: Color(0xFFFFF3E0),
          ),
          const _StatData(
            label: 'Posts',
            value: 0,
            icon: Icons.article_outlined,
            color: Color(0xFF00695C),
            bgColor: Color(0xFFE0F2F1),
          ),
        ];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D47A1)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLoading
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          const SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFF2E7D32)),
                          )
                        else
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle),
                          ),
                        const SizedBox(width: 5),
                        Text(
                          isLoading ? 'Loading…' : 'Live',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isLoading
                                  ? Colors.grey
                                  : const Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatCard(data: stats[0])),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(data: stats[1])),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(data: stats[2])),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _StatCard(data: stats[3])),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(data: stats[4])),
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Menu Card ────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black12,
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: accentColor.withValues(alpha: 0.06),
        highlightColor: accentColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D1B3E))),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    size: 20, color: accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Data Model ──────────────────────────────────────────────────────────
class _StatData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

// ─── Stat Card Widget ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: data.bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, size: 18, color: data.color),
          ),
          const SizedBox(height: 10),
          Text(
            data.value.toString(),
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: data.color,
                height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: data.color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}