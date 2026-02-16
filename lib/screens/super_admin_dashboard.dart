import 'package:flutter/material.dart';
import '../login.dart';

// Super Admin Screens
import 'admin_awareness_management_screen.dart';
import 'admin_homestay_management_screen.dart';
import 'admin_user_account_screen.dart';
import 'admin_user_list_screen.dart';
import 'admin_reset_password_screen.dart';
import 'admin_manage_appointments_screen.dart';
import 'admin_community_moderation_screen.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

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
              Icon(Icons.volunteer_activism,
                  size: 22,
                  color: accentBlue),
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
                  MaterialPageRoute(
                      builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                'Super Administration',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: deepBlue,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'System-level management & global control',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  children: [

                    // ================= USER MANAGEMENT =================
                    optionBox(
                      context,
                      icon: Icons.person_add_outlined,
                      title: 'User Accounts',
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

                    // ================= AWARENESS MANAGEMENT =================
                    optionBox(
                      context,
                      icon: Icons.health_and_safety_outlined,
                      title: 'Awareness Management',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminAwarenessManagementScreen(),
                          ),
                        );
                      },
                    ),

                    // ================= HOMESTAY MANAGEMENT =================
                    optionBox(
                      context,
                      icon: Icons.home_work_outlined,
                      title: 'Homestay Management',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminHomestayManagementScreen(),
                          ),
                        );
                      },
                    ),
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
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}