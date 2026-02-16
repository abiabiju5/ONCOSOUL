import 'package:flutter/material.dart';
import 'login.dart';

// Admin screens
import 'screens/admin_manage_appointments_screen.dart';
import 'screens/admin_user_account_screen.dart';
import 'screens/admin_reset_password_screen.dart';
import 'screens/admin_community_moderation_screen.dart';
import 'screens/admin_user_list_screen.dart';

// Medical staff screens
import 'screens/upload_medical_report_screen.dart';
import 'screens/medical_staff_view_appointments_screen.dart';

class AdminDashboard extends StatelessWidget {
  final String role; // 'admin' or 'medical'

  const AdminDashboard({super.key, required this.role});

  final Color deepBlue = const Color(0xFF0D47A1);
  final Color accentBlue = const Color.fromARGB(255, 70, 100, 150);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volunteer_activism, size: 22, color: accentBlue),
              const SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Onco',
                      style: TextStyle(
                        color: deepBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: 'Soul',
                      style: TextStyle(
                        color: accentBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              color: deepBlue,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role == 'admin' ? 'Administration' : 'Medical Staff',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: deepBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                role == 'admin'
                    ? 'Manage hospital system & users'
                    : 'Manage reports and appointments',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    if (role == 'medical') ...[
                      optionBox(
                        context,
                        icon: Icons.upload_file_outlined,
                        title: 'Upload Medical Reports',
                        subtitle: 'Lab reports & diagnostics',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UploadMedicalReportScreen(),
                            ),
                          );
                        },
                      ),
                      optionBox(
                        context,
                        icon: Icons.event_note_outlined,
                        title: 'Appointments',
                        subtitle: 'Confirmed patient appointments',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MedicalStaffViewAppointmentsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    if (role == 'admin') ...[
                      optionBox(
                        context,
                        icon: Icons.person_add_outlined,
                        title: 'User Accounts',
                        subtitle: 'Add patients & staff',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminUserAccountScreen(),
                            ),
                          );
                        },
                      ),
                      optionBox(
                        context,
                        icon: Icons.people_outline,
                        title: 'User List',
                        subtitle: 'View all registered users',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminUserListScreen(),
                            ),
                          );
                        },
                      ),
                      optionBox(
                        context,
                        icon: Icons.lock_reset_outlined,
                        title: 'Reset Password',
                        subtitle: 'Regenerate user credentials',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminResetPasswordScreen(),
                            ),
                          );
                        },
                      ),
                      optionBox(
                        context,
                        icon: Icons.event_available_outlined,
                        title: 'Appointments',
                        subtitle: 'Rules & confirmed bookings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminManageAppointmentsScreen(),
                            ),
                          );
                        },
                      ),
                      optionBox(
                        context,
                        icon: Icons.forum_outlined,
                        title: 'Community Moderation',
                        subtitle: 'Monitor patient discussions',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminCommunityModerationScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget optionBox(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}