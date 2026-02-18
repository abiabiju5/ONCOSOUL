import 'package:flutter/material.dart';
import 'login.dart';
import 'models/app_user_session.dart';

// ── Admin (Hospital Administration) screens ───────────────────────────────────
import 'screens/admin_manage_appointments_screen.dart';
import 'screens/admin_user_account_screen.dart';
import 'screens/admin_reset_password_screen.dart';
import 'screens/admin_community_moderation_screen.dart';
import 'screens/admin_user_list_screen.dart';

// ── Medical Staff screens ─────────────────────────────────────────────────────
import 'screens/upload_medical_report_screen.dart';
import 'screens/upload_consultation_summary_screen.dart';
import 'screens/medical_staff_view_appointments_screen.dart';

class AdminDashboard extends StatefulWidget {
  /// role = 'admin'   → Hospital Administration dashboard
  /// role = 'medical' → Medical Staff dashboard
  final String role;

  const AdminDashboard({super.key, required this.role});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color _deepBlue = Color(0xFF0D47A1);
  static const Color _accentBlue = Color(0xFF1976D2);

  bool get _isAdmin => widget.role == 'admin';

  // ─── Logout confirmation ──────────────────────────────────────────────────
  void _confirmLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 90, vertical: 24),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                    color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded,
                    size: 24, color: _deepBlue),
              ),
              const SizedBox(height: 14),
              const Text(
                'Log Out?',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _deepBlue,
                    letterSpacing: -0.3),
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
                        foregroundColor: _deepBlue,
                        side: const BorderSide(color: _deepBlue, width: 1.4),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
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
                        backgroundColor: _deepBlue,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FC),
        appBar: _buildAppBar(),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 28),
            _sectionLabel(
                _isAdmin ? 'User Management' : 'Patient Records'),
            const SizedBox(height: 12),

            // ── ADMIN (Hospital Administration) menu ──────────────────────
            if (_isAdmin) ...[
              _MenuCard(
                icon: Icons.person_add_alt_1_rounded,
                title: 'Create User Account',
                subtitle: 'Register patients, doctors & medical staff',
                accentColor: const Color(0xFF1565C0),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminUserAccountScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.people_alt_rounded,
                title: 'User List',
                subtitle: 'View & activate/deactivate accounts',
                accentColor: const Color(0xFF0277BD),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminUserListScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.lock_reset_rounded,
                title: 'Reset Password',
                subtitle: 'Generate new credentials for users',
                accentColor: const Color(0xFF6A1B9A),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminResetPasswordScreen()),
                ),
              ),
              const SizedBox(height: 28),
              _sectionLabel('Hospital Operations'),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.event_available_rounded,
                title: 'Appointments',
                subtitle: 'Manage rules & confirmed bookings',
                accentColor: const Color(0xFF2E7D32),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const AdminManageAppointmentsScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.forum_rounded,
                title: 'Community Moderation',
                subtitle: 'Monitor patient discussions',
                accentColor: const Color(0xFFE65100),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const AdminCommunityModerationScreen()),
                ),
              ),
            ],

            // ── MEDICAL STAFF menu ────────────────────────────────────────
            if (!_isAdmin) ...[
              _MenuCard(
                icon: Icons.upload_file_rounded,
                title: 'Upload Medical Reports',
                subtitle: 'Lab reports & diagnostics',
                accentColor: const Color(0xFF1565C0),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UploadMedicalReportScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.summarize_rounded,
                title: 'Upload Consultation Summary',
                subtitle: 'Post-consultation notes & summaries',
                accentColor: const Color(0xFF0277BD),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const UploadConsultationSummaryScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.event_note_rounded,
                title: 'Appointments',
                subtitle: 'View confirmed patient appointments',
                accentColor: const Color(0xFF2E7D32),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MedicalStaffViewAppointmentsScreen()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
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
                size: 20, color: _deepBlue),
          ),
          const SizedBox(width: 8),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Onco',
                  style: TextStyle(
                      color: _deepBlue,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
                TextSpan(
                  text: 'Soul',
                  style: TextStyle(
                      color: _accentBlue,
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
            onTap: _confirmLogout,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  size: 20, color: _deepBlue),
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
    final isAdmin = _isAdmin;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAdmin
              ? [const Color(0xFF0D47A1), const Color(0xFF1976D2)]
              : [const Color(0xFF00695C), const Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAdmin
                    ? const Color(0xFF0D47A1)
                    : const Color(0xFF00695C))
                .withValues(alpha: 0.3),
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
                  child: Text(
                    isAdmin ? 'Hospital Administration' : 'Medical Staff',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Welcome back ',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 2),
                //Text(
                  //isAdmin ? 'Admin' : ' Staff ',
                  //style: const TextStyle(
                      //color: Colors.white,
                      //fontSize: 22,
                      //fontWeight: FontWeight.w800,
                      //letterSpacing: -0.5),
                //),
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
            child: Icon(
              isAdmin
                  ? Icons.manage_accounts_rounded
                  : Icons.medical_services_rounded,
              size: 32,
              color: Colors.white,
            ),
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
            color: _deepBlue,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _deepBlue,
              letterSpacing: -0.2),
        ),
      ],
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